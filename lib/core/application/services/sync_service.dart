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

  /// Antes restrito a DCIM + Pictures/Screenshots (5.1). O app agora
  /// precisa espelhar TODOS os álbuns reais do sistema (WhatsApp
  /// Images, Instagram, pastas de outros apps etc.), não só a câmera e
  /// os screenshots — então toda mídia entra no índice; a pasta de
  /// origem (`relativePath`) é o que [_mirrorSystemAlbums] usa depois
  /// pra espelhar cada álbum.
  bool _inScope(String relativePath) => true;

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
    await _mirrorSystemAlbums();
    await _bumpLastSync();
  }

  /// 5.3 — sincronização incremental. Sempre uma passada completa do
  /// início: sem o `MethodChannel` nativo de `MediaStore.getGeneration`
  /// (5.3.2, ainda fora de escopo), o caminho de fallback de 5.3.3
  /// generaliza pra "recomparar tudo", que é o que acontece aqui via
  /// [TriageRepository.indexedMediaStoreIds]. O canal nativo de itens
  /// na lixeira (2.1.5) já existe — usado abaixo pra reconciliar
  /// `trashedInSystem` com o estado real do MediaStore, inclusive o
  /// que foi retido/purgado por fora deste app.
  /// Retorna quantos itens novos foram indexados nesta rodada — usado
  /// pelo chamador pra saber se precisa invalidar sessões de triagem já
  /// abertas (o cursor delas só deve pular pra mídia mais nova quando
  /// mídia nova de fato chegou, não a cada sync sem novidade).
  Future<int> runIncrementalSync() async {
    await _media.ensureReady();

    final existingIds = await _triage.indexedMediaStoreIds();
    // 5.5.1 — itens retidos na lixeira do sistema somem das consultas
    // normais do MediaStore por definição; sem isolar isso, o diff
    // abaixo os classificaria como órfãos.
    final trashedIds = await _triage.trashedMediaStoreIds();
    // 2.1.5 — verdade atual do MediaStore (`IS_TRASHED`), via canal
    // nativo. `trashedIds` acima é só o que o próprio app retém
    // (`moveToSystemTrash`); isto cobre também o que foi retido por
    // fora (Fotos do sistema, outro app) e permite detectar purga real.
    final systemTrashedIds = await _media.systemTrashedMediaStoreIds();
    final seen = <int>{};
    // 3.6.3/5.5.5 — retido que reaparece na varredura foi restaurado
    // pelo usuário na lixeira do sistema, não é item novo.
    final reappearedTrashed = <int>{};
    var newCount = 0;

    await for (final batch in _media.scanBatches(batchSize: _batchSize)) {
      for (final asset in batch) {
        if (!_inScope(asset.relativePath)) continue;
        seen.add(asset.mediaStoreId);
        if (trashedIds.contains(asset.mediaStoreId)) {
          reappearedTrashed.add(asset.mediaStoreId);
        }
      }
      final entities = await _buildNewEntities(
        batch,
        existingIds: existingIds,
      );
      if (entities.isNotEmpty) {
        await _triage.upsertScanned(entities);
        newCount += entities.length;
      }
    }

    if (reappearedTrashed.isNotEmpty) {
      await _triage.restoreFromSystemTrash(reappearedTrashed);
    }

    // `null` = canal indisponível ou falhou nesta rodada — nunca
    // tratado como "nada retido agora" (ver motivo no contrato de
    // `MediaRepository.systemTrashedMediaStoreIds`); a reconciliação
    // abaixo simplesmente não roda, mantendo o comportamento anterior
    // à 2.1.5 (só `trashedIds` importa) em vez de arriscar apagar
    // linha de item que continua retido de verdade.
    if (systemTrashedIds != null) {
      // 5.5.2/5.5.3 — retido na lixeira do sistema por fora deste app:
      // não passou por `moveToSystemTrash`, então `trashedIds` (nosso
      // próprio registro) não sabia. Só o canal nativo resolve isso.
      final newlyTrashedExternally =
          systemTrashedIds.intersection(existingIds).difference(trashedIds);
      if (newlyTrashedExternally.isNotEmpty) {
        await _triage.markTrashedInSystemByMediaStoreId(
          newlyTrashedExternally,
          DateTime.now(),
        );
      }

      // 5.5.4 — estava retido e não está mais nem na lixeira do
      // sistema nem na varredura normal: foi purgado de verdade
      // (expirou os 30 dias, ou a lixeira foi esvaziada por fora do
      // app). Órfão confirmado — diferente do caso ambíguo de
      // `missing` abaixo, remove a linha em vez de só marcar
      // indisponível.
      final purgedFromTrash =
          trashedIds.difference(systemTrashedIds).difference(seen);
      if (purgedFromTrash.isNotEmpty) {
        await _triage.deleteByMediaStoreIds(purgedFromTrash);
      }
    }

    // 5.5.6 — ausência que não é retenção (própria ou externa) nem
    // purga confirmada ainda pode ser acesso parcial ou volume
    // desmontado — o canal nativo não distingue esses dois casos.
    // Marca indisponível, nunca apaga o registro aqui.
    final missing = existingIds
        .difference(seen)
        .difference(trashedIds)
        .difference(systemTrashedIds ?? const {});
    if (missing.isNotEmpty) {
      await _triage.markUnavailable(missing);
    }

    // Lacuna conhecida: um item que estava `isAvailable` false (5.5.6,
    // não retido na lixeira) e reaparece (volume remontado) é visto
    // aqui — entra em `seen` — mas como já está em `existingIds`,
    // `_buildNewEntities` pula ele e ninguém restaura `isAvailable`
    // pra true. Sem impacto na detecção de itens novos/ausentes/
    // retidos — gap isolado, independente do canal nativo de lixeira
    // (2.1.5, já usado acima).
    final mirroredCount = await _mirrorSystemAlbums();
    await _bumpLastSync();
    return newCount + mirroredCount;
  }

  /// Espelha cada pasta real do sistema com mídia como um álbum do app
  /// (`TriageRepository.mirrorSystemFolder`) — pedido explícito de
  /// fazer a Tela Inicial ("agrupar por álbuns") mostrar o mesmo que a
  /// Galeria do sistema, não só listar pastas vazias esperando
  /// importação manual (6.5.8). Sempre cria o álbum; só marca item como
  /// mantido/classificado quando a pasta não é uma categoria automática
  /// da galeria (Câmera padrão, Screenshots — ver doc de
  /// `TriageRepository.mirrorSystemFolder` pro motivo). Best-effort por
  /// pasta: uma falha isolada (ex.: nome colidindo de um jeito que a
  /// checagem de unicidade não previu) não deve derrubar a
  /// sincronização inteira nem impedir as demais pastas.
  Future<int> _mirrorSystemAlbums() async {
    final folders = await _media.discoverMediaFolders();
    var linked = 0;
    for (final folder in folders) {
      try {
        linked += await _triage.mirrorSystemFolder(folder);
      } catch (_) {
        continue;
      }
    }
    return linked;
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
