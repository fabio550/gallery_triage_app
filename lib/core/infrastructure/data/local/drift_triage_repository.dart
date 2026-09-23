import 'package:drift/drift.dart';

import 'package:gallery_triage_app/core/domain/entities/album_entity.dart';
import 'package:gallery_triage_app/core/domain/entities/media_item_entity.dart';
import 'package:gallery_triage_app/core/domain/enums/category_granularity.dart';
import 'package:gallery_triage_app/core/domain/enums/sort_order.dart';
import 'package:gallery_triage_app/core/domain/enums/triage_decision.dart';
import 'package:gallery_triage_app/core/domain/exceptions/album_name_exception.dart';
import 'package:gallery_triage_app/core/domain/models/category_summary.dart';
import 'package:gallery_triage_app/core/domain/repositories/triage_repository.dart';

import 'app_database.dart';

class DriftTriageRepository implements TriageRepository {
  DriftTriageRepository(this._db);

  final AppDatabase _db;

  static const _monthNames = [
    '',
    'Janeiro',
    'Fevereiro',
    'Março',
    'Abril',
    'Maio',
    'Junho',
    'Julho',
    'Agosto',
    'Setembro',
    'Outubro',
    'Novembro',
    'Dezembro',
  ];

  @override
  Future<List<MediaItemEntity>> itemsForCategory(
    CategoryRef ref, {
    required SortOrder sortOrder,
  }) async {
    final predicate = await _resolveCategoryPredicate(ref);
    final query = _db.select(_db.mediaItemsTable)
      ..where(
        (t) => t.trashedInSystem.equals(false) & t.isAvailable.equals(true),
      )
      ..where(predicate)
      // 6.2.3 — sempre cronológica, direto pelo índice de dateTaken.
      ..orderBy([
        (t) => OrderingTerm(
              expression: t.dateTaken,
              mode: sortOrder == SortOrder.newestFirst
                  ? OrderingMode.desc
                  : OrderingMode.asc,
            ),
      ]);
    final rows = await query.get();
    return rows.map(_toEntity).toList();
  }

  /// Igual a [_categoryPredicate], mas resolve o caso de álbum de forma
  /// assíncrona: além de `albumId == ref.key` (classificação explícita,
  /// 3.2.1), também casa por localização física
  /// (`relativePath == album.effectiveRelativePath`) — é o que faz uma
  /// categoria "automática" espelhada (Câmera, Screenshots etc., ver
  /// [mirrorSystemFolder]) mostrar os itens que já moram lá sem
  /// precisar marcar nada como classificado de antemão. Explícito
  /// sempre tem prioridade sobre localização — ver [_summarizeByAlbum].
  Future<Expression<bool> Function($MediaItemsTableTable)>
      _resolveCategoryPredicate(CategoryRef ref) async {
    if (ref.granularity != CategoryGranularity.album) {
      return _categoryPredicate(ref);
    }

    final albumList = await albums();
    AlbumEntity? album;
    for (final a in albumList) {
      if (a.id == ref.key) {
        album = a;
        break;
      }
    }
    if (album == null) return _categoryPredicate(ref);

    final path = album.effectiveRelativePath;
    return ($MediaItemsTableTable t) =>
        t.albumId.equals(ref.key) | t.relativePath.equals(path);
  }

  @override
  Future<void> updateItem(MediaItemEntity item) {
    return _db
        .into(_db.mediaItemsTable)
        .insertOnConflictUpdate(_toCompanion(item));
  }

  @override
  Future<void> upsertScanned(List<MediaItemEntity> items) async {
    if (items.isEmpty) return;
    // 5.2.3 — uma transação por lote; quem chama já divide em lotes de
    // 500 a 1000. `OnConflictUpdate` em vez de insert puro: idempotente
    // se o `SyncService` alguma vez reprocessar um `mediaStoreId` já
    // gravado (ex.: no reinício de um primeiro scan interrompido).
    await _db.batch((batch) {
      batch.insertAllOnConflictUpdate(
        _db.mediaItemsTable,
        items.map(_toCompanion).toList(),
      );
    });
  }

  @override
  Future<Set<int>> indexedMediaStoreIds() async {
    final query = _db.selectOnly(_db.mediaItemsTable)
      ..addColumns([_db.mediaItemsTable.mediaStoreId]);
    final rows = await query.get();
    return rows.map((r) => r.read(_db.mediaItemsTable.mediaStoreId)!).toSet();
  }

  @override
  Future<void> markUnavailable(Set<int> mediaStoreIds) async {
    if (mediaStoreIds.isEmpty) return;
    await (_db.update(_db.mediaItemsTable)
          ..where((t) => t.mediaStoreId.isIn(mediaStoreIds)))
        .write(const MediaItemsTableCompanion(isAvailable: Value(false)));
  }

  @override
  Future<void> markTrashedInSystem(List<String> ids, DateTime at) async {
    if (ids.isEmpty) return;
    await (_db.update(_db.mediaItemsTable)..where((t) => t.id.isIn(ids)))
        .write(
      MediaItemsTableCompanion(
        trashedInSystem: const Value(true),
        trashedAt: Value(at),
      ),
    );
  }

  @override
  Future<Set<int>> trashedMediaStoreIds() async {
    final query = _db.selectOnly(_db.mediaItemsTable)
      ..addColumns([_db.mediaItemsTable.mediaStoreId])
      ..where(_db.mediaItemsTable.trashedInSystem.equals(true));
    final rows = await query.get();
    return rows.map((r) => r.read(_db.mediaItemsTable.mediaStoreId)!).toSet();
  }

  @override
  Future<void> restoreFromSystemTrash(Set<int> mediaStoreIds) async {
    if (mediaStoreIds.isEmpty) return;
    await (_db.update(_db.mediaItemsTable)
          ..where((t) => t.mediaStoreId.isIn(mediaStoreIds)))
        .write(
      const MediaItemsTableCompanion(
        trashedInSystem: Value(false),
        trashedAt: Value(null),
      ),
    );
  }

  @override
  Future<void> markTrashedInSystemByMediaStoreId(
    Set<int> mediaStoreIds,
    DateTime at,
  ) async {
    if (mediaStoreIds.isEmpty) return;
    await (_db.update(_db.mediaItemsTable)
          ..where((t) => t.mediaStoreId.isIn(mediaStoreIds)))
        .write(
      MediaItemsTableCompanion(
        trashedInSystem: const Value(true),
        trashedAt: Value(at),
      ),
    );
  }

  @override
  Future<void> deleteByMediaStoreIds(Set<int> mediaStoreIds) async {
    if (mediaStoreIds.isEmpty) return;
    await (_db.delete(_db.mediaItemsTable)
          ..where((t) => t.mediaStoreId.isIn(mediaStoreIds)))
        .go();
  }

  @override
  Future<List<CategorySummary>> categoriesFor(
    CategoryGranularity granularity,
  ) async {
    // 8.3 — o ideal seria `COUNT`/`SUM` agregado por SQL; aqui o
    // agregado é feito em Dart sobre uma projeção já filtrada por
    // 6.1.10 (trashedInSystem/isAvailable). Simplificação pragmática
    // enquanto o volume real (8.1) não exige o caminho puramente SQL —
    // revisitar depois da medição de performance (8.9/P-02).
    final rows = await (_db.select(_db.mediaItemsTable)
          ..where(
            (t) => t.trashedInSystem.equals(false) & t.isAvailable.equals(true),
          ))
        .get();
    final items = rows.map(_toEntity).toList();

    switch (granularity) {
      case CategoryGranularity.all:
        return _summarizeAll(items);
      case CategoryGranularity.month:
        return _summarizeByMonth(items);
      case CategoryGranularity.year:
        return _summarizeByYear(items);
      case CategoryGranularity.type:
        return _summarizeByType(items);
      case CategoryGranularity.album:
        final albumList = await albums();
        return _summarizeByAlbum(items, albumList);
    }
  }

  @override
  Future<Map<String, int>> albumItemCounts() async {
    final rows = await (_db.select(_db.mediaItemsTable)
          ..where(
            (t) =>
                t.trashedInSystem.equals(false) &
                t.isAvailable.equals(true) &
                t.albumId.isNotNull(),
          ))
        .get();
    final counts = <String, int>{};
    for (final row in rows) {
      final id = row.albumId;
      if (id == null) continue;
      counts[id] = (counts[id] ?? 0) + 1;
    }
    return counts;
  }

  @override
  Future<void> restorePendingQueueItems() async {
    final rows = await (_db.select(_db.mediaItemsTable)
          ..where(
            (t) =>
                t.decision.equals(TriageDecision.markedForDeletion.name) &
                t.trashedInSystem.equals(false),
          ))
        .get();
    if (rows.isEmpty) return;

    final restored = rows
        .map((row) => _toCompanion(_toEntity(row).restoreFromQueue()))
        .toList();
    await _db.batch((batch) {
      batch.replaceAll(_db.mediaItemsTable, restored);
    });
  }

  @override
  Future<List<AlbumEntity>> albums() async {
    final rows = await _db.select(_db.albumsTable).get();
    return rows.map(_albumToEntity).toList();
  }

  @override
  Future<AlbumEntity> createAlbum(String rawName) async {
    final existing = await albums();
    final name = _validateAlbumName(rawName, existing);

    final album = AlbumEntity(
      id: 'album-${DateTime.now().microsecondsSinceEpoch}',
      name: name,
      createdAt: DateTime.now(),
    );
    await _db.into(_db.albumsTable).insert(
          AlbumsTableCompanion.insert(
            id: album.id,
            name: album.name,
            createdAt: album.createdAt,
          ),
        );
    return album;
  }

  @override
  Future<AlbumEntity> importAlbumFromFolder(String relativePath) async {
    final existing = await albums();
    final name = _validateAlbumName(_leafFolderName(relativePath), existing);

    final album = AlbumEntity(
      id: 'album-${DateTime.now().microsecondsSinceEpoch}',
      name: name,
      createdAt: DateTime.now(),
      relativePath: relativePath,
    );
    await _db.into(_db.albumsTable).insert(
          AlbumsTableCompanion.insert(
            id: album.id,
            name: album.name,
            createdAt: album.createdAt,
            relativePath: Value(album.relativePath),
          ),
        );
    return album;
  }

  /// Sempre garante que o álbum exista. Só classifica retroativamente
  /// (mantido + vinculado) os itens que já moram nele quando a pasta
  /// não é uma categoria automática da galeria (ver [_isAutomaticBucket]:
  /// Câmera padrão, Screenshots) — essas são "onde a mídia cai
  /// sozinha", não uma organização deliberada, e classificar tudo nelas
  /// de cara esvaziaria o propósito da triagem (3.1/3.2), já que é onde
  /// mora a maioria das fotos de um aparelho normal. Qualquer outra
  /// pasta real (WhatsApp Images, Instagram, um álbum que o usuário já
  /// organizou pela Galeria do sistema etc.) representa uma
  /// classificação que o usuário já fez fora do app — espelhar isso
  /// como mantido/classificado é reconhecer essa decisão, não pular a
  /// triagem. Nunca sobrescreve uma decisão que o usuário já tomou
  /// dentro do app (item já mantido sem álbum, excluído, ou
  /// classificado noutro álbum fica intocado). Retorna quantos itens
  /// foram vinculados nesta chamada (0 se a pasta é automática ou já
  /// não sobrou nada pra classificar).
  @override
  Future<int> mirrorSystemFolder(String relativePath) async {
    final existing = await albums();
    AlbumEntity? album;
    for (final a in existing) {
      if (a.effectiveRelativePath == relativePath) {
        album = a;
        break;
      }
    }
    album ??= await _createMirroredAlbum(relativePath, existing);

    if (_isAutomaticBucket(relativePath)) return 0;

    // Só item ainda não decidido: uma decisão que o usuário já tomou
    // dentro do app nunca é sobrescrita por este espelhamento.
    return (_db.update(_db.mediaItemsTable)
          ..where(
            (t) =>
                t.relativePath.equals(relativePath) &
                t.albumId.isNull() &
                t.decision.equals(TriageDecision.undecided.name),
          ))
        .write(
      MediaItemsTableCompanion(
        albumId: Value(album.id),
        decision: const Value(TriageDecision.kept),
        decidedAt: Value(DateTime.now()),
        // O item já está fisicamente nesta pasta (é por isso que
        // casou o filtro acima) — "endereço de origem" (6.5.7) é a
        // própria pasta atual, não uma pasta anterior real.
        preAlbumRelativePath: Value(relativePath),
      ),
    );
  }

  /// Câmera padrão (`DCIM/Camera/`, ou mídia solta direto em `DCIM/`
  /// sem subpasta em aparelhos antigos) e Screenshots — mesma regra de
  /// [MediaItemEntity.isScreenshot] — são "onde a mídia cai sozinha" só
  /// por tirar uma foto ou capturar a tela, nunca uma organização
  /// deliberada. Qualquer outra pasta (mesmo dentro de `DCIM/`, ex.:
  /// `DCIM/WhatsApp/`) é tratada como álbum de verdade.
  bool _isAutomaticBucket(String relativePath) {
    final normalized = relativePath.toLowerCase();
    if (normalized.contains('screenshot')) return true;

    final trimmed = normalized.endsWith('/')
        ? normalized.substring(0, normalized.length - 1)
        : normalized;
    return trimmed == 'dcim' || trimmed == 'dcim/camera';
  }

  /// Cria o álbum espelhado. Nome pode colidir com um álbum manual já
  /// existente com o mesmo nome de pasta — sufixo numérico em vez de
  /// derrubar a sincronização inteira por causa de um único álbum
  /// espelhado (diferente de [importAlbumFromFolder], fluxo manual
  /// onde faz sentido lançar `AlbumNameException` e deixar o usuário
  /// escolher outro nome).
  Future<AlbumEntity> _createMirroredAlbum(
    String relativePath,
    List<AlbumEntity> existing,
  ) async {
    final leafName = _leafFolderName(relativePath);
    var name = leafName;
    var suffix = 2;
    while (existing.any((a) => a.name.toLowerCase() == name.toLowerCase())) {
      name = '$leafName ($suffix)';
      suffix++;
    }

    final album = AlbumEntity(
      id: 'album-${DateTime.now().microsecondsSinceEpoch}',
      name: name,
      createdAt: DateTime.now(),
      relativePath: relativePath,
    );
    await _db.into(_db.albumsTable).insert(
          AlbumsTableCompanion.insert(
            id: album.id,
            name: album.name,
            createdAt: album.createdAt,
            relativePath: Value(album.relativePath),
          ),
        );
    return album;
  }

  /// Último segmento de um `RELATIVE_PATH` do MediaStore (sempre com
  /// barra no final, ex.: "DCIM/Camera/" -> "Camera") — nome de exibição
  /// padrão para um álbum importado (6.5.8).
  String _leafFolderName(String relativePath) {
    final trimmed = relativePath.endsWith('/')
        ? relativePath.substring(0, relativePath.length - 1)
        : relativePath;
    final lastSlash = trimmed.lastIndexOf('/');
    return lastSlash == -1 ? trimmed : trimmed.substring(lastSlash + 1);
  }

  @override
  Future<AlbumEntity> renameAlbum(String albumId, String rawName) async {
    final existing = await albums();
    AlbumEntity? current;
    for (final a in existing) {
      if (a.id == albumId) {
        current = a;
        break;
      }
    }
    if (current == null) {
      throw const AlbumNameException('Álbum não encontrado.');
    }
    final name = _validateAlbumName(rawName, existing, excludingId: albumId);

    await (_db.update(_db.albumsTable)..where((t) => t.id.equals(albumId)))
        .write(AlbumsTableCompanion(name: Value(name)));

    // 6.5.7 — pasta real: o nome antigo pode já existir fisicamente
    // com itens dentro. Marca pendente incondicionalmente — se algum
    // item nunca chegou a ser movido de verdade, o próximo lote só
    // "move" pro mesmo lugar onde já está (sem custo real).
    await (_db.update(_db.mediaItemsTable)
          ..where((t) => t.albumId.equals(albumId)))
        .write(const MediaItemsTableCompanion(albumMovePending: Value(true)));

    return AlbumEntity(
      id: albumId,
      name: name,
      createdAt: current.createdAt,
      relativePath: current.relativePath,
    );
  }

  @override
  Future<void> deleteAlbum(String albumId) async {
    // 6.5.6 — desclassifica os itens vinculados (albumId null),
    // preservando `decision` — "mantido" não muda. 6.5.7 — pasta
    // real: só quem já foi fisicamente movido pra lá (relativePath
    // diferente da origem gravada) precisa de um movimento de volta;
    // quem nunca chegou a mover já está "em casa", não gera trabalho
    // à toa nem deixa `preAlbumRelativePath` pendurado sem uso.
    final linked = await (_db.select(_db.mediaItemsTable)
          ..where((t) => t.albumId.equals(albumId)))
        .get();

    if (linked.isNotEmpty) {
      final updated = linked.map((row) {
        final item = _toEntity(row);
        final alreadyMoved = item.preAlbumRelativePath != null &&
            item.relativePath != item.preAlbumRelativePath;
        // Já movido: preserva preAlbumRelativePath (é o alvo do
        // retorno) e pendura o movimento de volta. Nunca movido: já
        // está em casa, limpa o rastro em vez de deixar sem uso.
        return _toCompanion(
          alreadyMoved
              ? item.copyWith(albumId: null, albumMovePending: true)
              : item.copyWith(
                  albumId: null,
                  preAlbumRelativePath: null,
                  albumMovePending: false,
                ),
        );
      }).toList();
      await _db.batch((batch) {
        batch.replaceAll(_db.mediaItemsTable, updated);
      });
    }

    await (_db.delete(_db.albumsTable)..where((t) => t.id.equals(albumId)))
        .go();
  }

  /// 6.5.3 — nome único (case-insensitive), sem espaços nas pontas,
  /// ≤64 caracteres, sem os separadores de caminho (`/ \ : * ? " < > |`
  /// — o nome vira pasta real de verdade, `Pictures/<nome>`, 6.5.7).
  /// Compartilhado entre [createAlbum] e [renameAlbum]; [excludingId]
  /// deixa o próprio álbum fora da checagem de duplicidade ao renomear.
  String _validateAlbumName(
    String rawName,
    List<AlbumEntity> existing, {
    String? excludingId,
  }) {
    final name = rawName.trim();

    if (name.isEmpty) {
      throw const AlbumNameException('Digite um nome para o álbum.');
    }
    if (name.length > 64) {
      throw const AlbumNameException(
        'Nome muito longo (máximo 64 caracteres).',
      );
    }
    if (RegExp(r'[/\\:*?"<>|]').hasMatch(name)) {
      throw const AlbumNameException('Nome não pode conter / \\ : * ? " < > |');
    }

    // Unicidade case-insensitive (6.5.3) checada em código, não via
    // collation do Drift — mesma decisão documentada no schema.
    final duplicate = existing.any(
      (a) => a.id != excludingId && a.name.toLowerCase() == name.toLowerCase(),
    );
    if (duplicate) {
      throw const AlbumNameException('Já existe um álbum com esse nome.');
    }

    return name;
  }

  @override
  Future<void> deleteItems(List<String> ids) async {
    if (ids.isEmpty) return;
    await (_db.delete(_db.mediaItemsTable)..where((t) => t.id.isIn(ids)))
        .go();
  }

  @override
  Future<List<MediaItemEntity>> itemsPendingAlbumMove() async {
    // Exclui retido/indisponível: mover um item nessas condições tende
    // a falhar — e como o lote é tudo-ou-nada por destino (6.5.7), um
    // item assim juntado no grupo derrubaria os demais com ele.
    final rows = await (_db.select(_db.mediaItemsTable)
          ..where(
            (t) =>
                t.albumMovePending.equals(true) &
                t.trashedInSystem.equals(false) &
                t.isAvailable.equals(true),
          ))
        .get();
    return rows.map(_toEntity).toList();
  }

  @override
  Future<void> applyAlbumMoveOutcome(List<MediaItemEntity> movedItems) async {
    if (movedItems.isEmpty) return;
    await _db.batch((batch) {
      batch.replaceAll(_db.mediaItemsTable, movedItems.map(_toCompanion).toList());
    });
  }

  // --- Mapeamento entidade <-> linha do Drift ---------------------------

  AlbumEntity _albumToEntity(AlbumsTableData row) => AlbumEntity(
        id: row.id,
        name: row.name,
        createdAt: row.createdAt,
        relativePath: row.relativePath,
      );

  MediaItemEntity _toEntity(MediaItemsTableData row) => MediaItemEntity(
        id: row.id,
        mediaStoreId: row.mediaStoreId,
        fingerprint: row.fingerprint,
        dateTaken: row.dateTaken,
        sizeBytes: row.sizeBytes,
        mimeType: row.mimeType,
        relativePath: row.relativePath,
        mediaType: row.mediaType,
        isScreenshot: row.isScreenshot,
        durationMs: row.durationMs,
        decision: row.decision,
        albumId: row.albumId,
        decidedAt: row.decidedAt,
        preQueueDecision: row.preQueueDecision,
        preQueueAlbumId: row.preQueueAlbumId,
        trashedInSystem: row.trashedInSystem,
        trashedAt: row.trashedAt,
        isAvailable: row.isAvailable,
        preAlbumRelativePath: row.preAlbumRelativePath,
        albumMovePending: row.albumMovePending,
      );

  MediaItemsTableCompanion _toCompanion(MediaItemEntity item) =>
      MediaItemsTableCompanion.insert(
        id: item.id,
        mediaStoreId: item.mediaStoreId,
        fingerprint: item.fingerprint,
        dateTaken: item.dateTaken,
        sizeBytes: item.sizeBytes,
        mimeType: item.mimeType,
        relativePath: item.relativePath,
        mediaType: item.mediaType,
        isScreenshot: item.isScreenshot,
        durationMs: Value(item.durationMs),
        decision: item.decision,
        albumId: Value(item.albumId),
        decidedAt: Value(item.decidedAt),
        preQueueDecision: Value(item.preQueueDecision),
        preQueueAlbumId: Value(item.preQueueAlbumId),
        trashedInSystem: Value(item.trashedInSystem),
        trashedAt: Value(item.trashedAt),
        isAvailable: Value(item.isAvailable),
        preAlbumRelativePath: Value(item.preAlbumRelativePath),
        albumMovePending: Value(item.albumMovePending),
      );

  // --- Filtro por categoria (3.1, 6.1.5) ---------------------------------
  //
  // month/year comparam `dateTaken` por faixa de data (usa o índice
  // idx_media_items_date_taken direto), não por string derivada — ver
  // decisão combinada antes desta etapa.

  Expression<bool> Function($MediaItemsTableTable) _categoryPredicate(
    CategoryRef ref,
  ) {
    switch (ref.granularity) {
      case CategoryGranularity.all:
        return (t) => const Constant(true);

      case CategoryGranularity.month:
        final start = _monthStart(ref.key);
        final end = DateTime(start.year, start.month + 1, 1);
        return (t) =>
            t.dateTaken.isBiggerOrEqualValue(start) &
            t.dateTaken.isSmallerThanValue(end);

      case CategoryGranularity.year:
        final year = int.parse(ref.key);
        final start = DateTime(year, 1, 1);
        final end = DateTime(year + 1, 1, 1);
        return (t) =>
            t.dateTaken.isBiggerOrEqualValue(start) &
            t.dateTaken.isSmallerThanValue(end);

      case CategoryGranularity.album:
        return (t) => t.albumId.equals(ref.key);

      case CategoryGranularity.type:
        // Comparado pelo nome do enum (MediaType.name), o mesmo valor
        // que o TypeConverter grava — sem depender de extensão
        // `.equalsValue` em cima do converter.
        return switch (ref.key) {
          'photos' => (t) =>
              t.mediaType.equals(MediaType.image.name) &
              t.isScreenshot.equals(false),
          'screenshots' => (t) =>
              t.mediaType.equals(MediaType.image.name) &
              t.isScreenshot.equals(true),
          'images' => (t) => t.mediaType.equals(MediaType.image.name),
          'videos' => (t) => t.mediaType.equals(MediaType.video.name),
          _ => (t) => const Constant(false),
        };
    }
  }

  DateTime _monthStart(String key) {
    final parts = key.split('-');
    return DateTime(int.parse(parts[0]), int.parse(parts[1]), 1);
  }

  // --- Agregação do Dashboard (6.1) --------------------------------------
  //
  // Porta direta da lógica que vivia em `MockCategories`, agora sobre
  // itens vindos do Drift em vez do dataset mockado — mesmas regras
  // (6.1.2, 6.1.5, 6.1.8), incluindo o fix de 3.2.5 (item classificado
  // que caiu na fila não conta como mantido nem como classificado).

  /// `null` se a categoria não tiver nenhum item — evita gerar um
  /// `CategoryTile` para um recorte vazio (6.1.11). `items` já chega
  /// filtrado por 6.1.10, então não repete o filtro aqui.
  CategorySummary? _summarize(
    CategoryRef ref,
    String label,
    List<MediaItemEntity> items,
  ) {
    if (items.isEmpty) return null;

    final kept =
        items.where((i) => i.decision == TriageDecision.kept).toList();
    final classified = kept.where((i) => i.albumId != null).length;
    final sizeBytes = items.fold<int>(0, (sum, i) => sum + i.sizeBytes);

    // P-10 — origem da capa: item mais recente do recorte.
    final sorted = [...items]..sort((a, b) => b.dateTaken.compareTo(a.dateTaken));

    return CategorySummary(
      ref: ref,
      label: label,
      totalItems: items.length,
      keptItems: kept.length,
      classifiedItems: classified,
      sizeBytes: sizeBytes,
      coverMediaStoreId: sorted.first.mediaStoreId,
    );
  }

  List<CategorySummary> _summarizeAll(List<MediaItemEntity> items) {
    final summary = _summarize(
      const CategoryRef(granularity: CategoryGranularity.all, key: 'all'),
      'Todos os itens',
      items,
    );
    return summary == null ? const [] : [summary];
  }

  String _monthKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}';

  List<CategorySummary> _summarizeByMonth(List<MediaItemEntity> items) {
    final byKey = <String, List<MediaItemEntity>>{};
    for (final item in items) {
      byKey.putIfAbsent(_monthKey(item.dateTaken), () => []).add(item);
    }
    final keys = byKey.keys.toList()..sort((a, b) => b.compareTo(a));

    return keys
        .map((key) {
          final parts = key.split('-');
          final month = int.parse(parts[1]);
          final label = '${_monthNames[month]} de ${parts[0]}';
          return _summarize(
            CategoryRef(granularity: CategoryGranularity.month, key: key),
            label,
            byKey[key]!,
          );
        })
        .whereType<CategorySummary>()
        .toList();
  }

  List<CategorySummary> _summarizeByYear(List<MediaItemEntity> items) {
    final byKey = <String, List<MediaItemEntity>>{};
    for (final item in items) {
      byKey.putIfAbsent(item.dateTaken.year.toString(), () => []).add(item);
    }
    final keys = byKey.keys.toList()..sort((a, b) => b.compareTo(a));

    return keys
        .map((key) => _summarize(
              CategoryRef(granularity: CategoryGranularity.year, key: key),
              key,
              byKey[key]!,
            ))
        .whereType<CategorySummary>()
        .toList();
  }

  List<CategorySummary> _summarizeByType(List<MediaItemEntity> items) {
    // Ordem fixa (6.1.8). Tipo não forma partição (6.1.5): Imagens
    // contém Fotos e Screenshots.
    final photos = items
        .where((i) => i.mediaType == MediaType.image && !i.isScreenshot)
        .toList();
    final screenshots = items
        .where((i) => i.mediaType == MediaType.image && i.isScreenshot)
        .toList();
    final images = items.where((i) => i.mediaType == MediaType.image).toList();
    final videos = items.where((i) => i.mediaType == MediaType.video).toList();

    return [
      _summarize(
        const CategoryRef(granularity: CategoryGranularity.type, key: 'photos'),
        'Fotos',
        photos,
      ),
      _summarize(
        const CategoryRef(
          granularity: CategoryGranularity.type,
          key: 'screenshots',
        ),
        'Screenshots',
        screenshots,
      ),
      _summarize(
        const CategoryRef(granularity: CategoryGranularity.type, key: 'images'),
        'Imagens',
        images,
      ),
      _summarize(
        const CategoryRef(granularity: CategoryGranularity.type, key: 'videos'),
        'Vídeos',
        videos,
      ),
    ].whereType<CategorySummary>().toList();
  }

  List<CategorySummary> _summarizeByAlbum(
    List<MediaItemEntity> items,
    List<AlbumEntity> albumList,
  ) {
    final names = {for (final a in albumList) a.id: a.name};
    // Categoria automática (Câmera, Screenshots etc., `mirrorSystemFolder`):
    // item sem classificação explícita ainda entra no grupo por já
    // morar fisicamente na pasta do álbum -- sem isso, um álbum
    // espelhado apareceria sempre vazio (nada nele nunca foi
    // classificado de propósito). Explícito (`item.albumId`) tem
    // prioridade: só cai na pasta se a triagem não decidiu nada ainda.
    final albumIdByPath = {
      for (final a in albumList) a.effectiveRelativePath: a.id,
    };
    final byAlbum = <String, List<MediaItemEntity>>{};
    for (final item in items) {
      final albumId = item.albumId ?? albumIdByPath[item.relativePath];
      if (albumId == null) continue;
      byAlbum.putIfAbsent(albumId, () => []).add(item);
    }
    // 6.1.8 — álbuns por nome.
    final ids = byAlbum.keys.toList()
      ..sort((a, b) => (names[a] ?? a).compareTo(names[b] ?? b));

    return ids
        .map((id) => _summarize(
              CategoryRef(granularity: CategoryGranularity.album, key: id),
              names[id] ?? id,
              byAlbum[id]!,
            ))
        .whereType<CategorySummary>()
        .toList();
  }
}
