import 'package:gallery_triage_app/core/domain/entities/media_item_entity.dart';
import 'package:gallery_triage_app/core/domain/models/media_store_asset.dart';
import 'package:gallery_triage_app/core/domain/repositories/media_repository.dart';
import 'package:gallery_triage_app/core/domain/repositories/preferences_repository.dart';
import 'package:gallery_triage_app/core/domain/repositories/triage_repository.dart';

/// Primeiro scan (5.2) e sincronização incremental (5.3). Isolamento
/// real do trabalho pesado: as escritas no índice já rodam num isolate
/// próprio via `NativeDatabase.createInBackground` (`AppDatabase`) —
/// não há `Isolate.spawn` explícito aqui porque orquestrar canais de
/// plataforma (`photo_manager`) fora do isolate principal exigiria
/// passar o token de `BackgroundIsolateBinaryMessenger`, que o plugin
/// não documenta suportar; a orquestração em si é só `await` entre
/// chamadas assíncronas, o que já não trava a UI.
class SyncService {
  SyncService({
    required MediaRepository mediaRepository,
    required TriageRepository triageRepository,
    required PreferencesRepository preferencesRepository,
  })  : _media = mediaRepository,
        _triage = triageRepository,
        _prefs = preferencesRepository;

  final MediaRepository _media;
  final TriageRepository _triage;
  final PreferencesRepository _prefs;

  static const _batchSize = 500;

  int _sequence = 0;

  /// 5.1 — só DCIM e Pictures/Screenshots entram no índice.
  bool _inScope(String relativePath) {
    final normalized = relativePath.replaceAll('\\', '/');
    return normalized.startsWith('DCIM') ||
        normalized.startsWith('Pictures/Screenshots');
  }

  /// 5.2 — primeiro scan. Resumível via `scanOffset` (5.2.4): sem
  /// detecção de ausência aqui, porque ela exigiria uma passada
  /// completa do início, o que contradiria a própria resumabilidade
  /// (retomar do meio veria "ausentes" os itens das páginas já
  /// processadas antes da interrupção).
  Future<void> runFirstScan({void Function(int processed)? onProgress}) async {
    await _media.ensureReady();

    // Carrega o que já foi commitado — não necessariamente vazio: se o
    // app foi encerrado entre um `upsertScanned` e o `setScanOffset`
    // seguinte, esse lote já está no índice mas o offset ainda aponta
    // pra antes dele. Sem isto, a retomada reprocessaria esse lote com
    // UUIDs novos e duplicaria os itens.
    final existingIds = await _triage.indexedMediaStoreIds();
    final resumeOffset = await _prefs.scanOffset() ?? 0;
    var offset = resumeOffset;
    // Retomando: já existe trabalho de uma rodada anterior — o
    // contador exibido (5.2.1) parte daí, não de zero.
    var processed = existingIds.length;

    await for (final batch in _media.scanBatches(
      batchSize: _batchSize,
      startPage: resumeOffset ~/ _batchSize,
    )) {
      final entities = await _buildNewEntities(batch, existingIds: existingIds);
      if (entities.isNotEmpty) {
        await _triage.upsertScanned(entities);
        existingIds.addAll(entities.map((e) => e.mediaStoreId));
        processed += entities.length;
        onProgress?.call(processed);
      }
      offset += batch.length;
      await _prefs.setScanOffset(offset);
    }

    await _prefs.setScanOffset(null);
    await _bumpLastSync();
  }

  /// 5.3 — sincronização incremental. Sempre uma passada completa do
  /// início: sem o `MethodChannel` nativo de `MediaStore.getGeneration`
  /// (5.3.2, fora do escopo desta etapa — só o de itens na lixeira,
  /// 2.1.5, está previsto), o caminho de fallback de 5.3.3 generaliza
  /// pra "recomparar tudo", que é o que acontece aqui via
  /// [TriageRepository.indexedMediaStoreIds].
  Future<void> runIncrementalSync() async {
    await _media.ensureReady();

    final existingIds = await _triage.indexedMediaStoreIds();
    final seen = <int>{};

    await for (final batch in _media.scanBatches(batchSize: _batchSize)) {
      for (final asset in batch) {
        if (_inScope(asset.relativePath)) seen.add(asset.mediaStoreId);
      }
      final entities = await _buildNewEntities(
        batch,
        existingIds: existingIds,
      );
      if (entities.isNotEmpty) {
        await _triage.upsertScanned(entities);
      }
    }

    // 5.5.6 — ausência não decorre necessariamente de exclusão de
    // verdade (pode ser acesso parcial ou volume desmontado, e sem o
    // canal nativo de 5.5.2 não dá pra distinguir de retido na lixeira
    // do sistema). Marca indisponível, nunca apaga o registro aqui —
    // 5.5.4 (purga de órfão de verdade) fica pra quando esse canal
    // existir.
    final missing = existingIds.difference(seen);
    if (missing.isNotEmpty) {
      await _triage.markUnavailable(missing);
    }

    // Lacuna conhecida: um item que estava `isAvailable` false (5.5.6)
    // e reaparece (volume remontado) é visto aqui — entra em `seen` —
    // mas como já está em `existingIds`, `_buildNewEntities` pula ele
    // e ninguém restaura `isAvailable` pra true. Sem impacto na
    // detecção de itens novos/ausentes; revisitar junto da distinção
    // órfão/retido de 5.5, que depende do mesmo canal nativo ainda não
    // construído (2.1.5).
    await _bumpLastSync();
  }

  Future<List<MediaItemEntity>> _buildNewEntities(
    List<MediaStoreAsset> batch, {
    required Set<int> existingIds,
  }) async {
    final result = <MediaItemEntity>[];
    for (final asset in batch) {
      if (!_inScope(asset.relativePath)) continue;
      if (existingIds.contains(asset.mediaStoreId)) {
        // 5.3.4 — já indexado. Detectar atualização de metadados em
        // itens já existentes (ex.: EXIF reeditado) fica pra uma etapa
        // futura — exigiria guardar a data de modificação do MediaStore
        // à parte de `dateTaken`, que é campo de exibição (6.1.5),
        // não de sincronização.
        continue;
      }

      final sizeBytes = await _media.readSizeBytes(asset.mediaStoreId);
      result.add(MediaItemEntity(
        id: _newId(),
        mediaStoreId: asset.mediaStoreId,
        fingerprint: _fingerprint(asset, sizeBytes),
        dateTaken: asset.dateTaken,
        sizeBytes: sizeBytes,
        mimeType: asset.mimeType,
        relativePath: asset.relativePath,
        mediaType: asset.mediaType,
        isScreenshot: asset.isScreenshot,
        durationMs: asset.durationMs,
      ));
    }
    return result;
  }

  Future<void> _bumpLastSync() async {
    final generation = (await _prefs.lastGeneration() ?? 0) + 1;
    await _prefs.setLastSync(at: DateTime.now(), generation: generation);
  }

  String _newId() =>
      'media-${DateTime.now().microsecondsSinceEpoch}-${_sequence++}';

  /// 2.5.3 — hash de `dateTaken` + `sizeBytes` + nome do arquivo. Só
  /// calculado aqui, no momento em que o item é gravado pela primeira
  /// vez — itens já indexados não recalculam (2.5.4: o fingerprint é
  /// usado como fallback de correspondência, não recomputado a cada
  /// sync).
  String _fingerprint(MediaStoreAsset asset, int sizeBytes) {
    final raw =
        '${asset.dateTaken.millisecondsSinceEpoch}|$sizeBytes|${asset.fileName}';
    return raw.hashCode.toString();
  }
}
