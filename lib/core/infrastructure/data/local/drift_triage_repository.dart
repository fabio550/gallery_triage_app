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
    final query = _db.select(_db.mediaItemsTable)
      ..where(
        (t) => t.trashedInSystem.equals(false) & t.isAvailable.equals(true),
      )
      ..where(_categoryPredicate(ref))
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
    return rows
        .map(
          (r) => AlbumEntity(id: r.id, name: r.name, createdAt: r.createdAt),
        )
        .toList();
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

    return AlbumEntity(id: albumId, name: name, createdAt: current.createdAt);
  }

  @override
  Future<void> deleteAlbum(String albumId) async {
    // 6.5.6 — desclassifica os itens vinculados (albumId null),
    // preservando `decision` — "mantido" não muda, nenhum arquivo é
    // tocado. Roda antes de apagar a linha do álbum em si.
    await (_db.update(_db.mediaItemsTable)
          ..where((t) => t.albumId.equals(albumId)))
        .write(const MediaItemsTableCompanion(albumId: Value(null)));

    await (_db.delete(_db.albumsTable)..where((t) => t.id.equals(albumId)))
        .go();
  }

  /// 6.5.3 — nome único (case-insensitive), sem espaços nas pontas,
  /// ≤64 caracteres, sem os separadores de caminho (`/ \ : * ? " < > |`
  /// — antecipa o estágio 2, onde o nome vira pasta real). Compartilhado
  /// entre [createAlbum] e [renameAlbum]; [excludingId] deixa o próprio
  /// álbum fora da checagem de duplicidade ao renomear.
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

  // --- Mapeamento entidade <-> linha do Drift ---------------------------

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
    final byAlbum = <String, List<MediaItemEntity>>{};
    for (final item in items) {
      final albumId = item.albumId;
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
