import 'package:drift/drift.dart';

import 'package:gallery_triage_app/core/domain/entities/album_entity.dart';
import 'package:gallery_triage_app/core/domain/entities/media_item_entity.dart';
import 'package:gallery_triage_app/core/domain/enums/category_granularity.dart';
import 'package:gallery_triage_app/core/domain/enums/triage_decision.dart';
import 'package:gallery_triage_app/core/domain/exceptions/album_name_exception.dart';
import 'package:gallery_triage_app/core/domain/models/category_summary.dart';
import 'package:gallery_triage_app/core/domain/repositories/triage_repository.dart';
import 'package:gallery_triage_app/features/dashboard/infrastructure/data/mock_media_items.dart';

import 'app_database.dart';

class DriftTriageRepository implements TriageRepository {
  DriftTriageRepository(this._db);

  final AppDatabase _db;

  static final DateTime _seedDate = DateTime(2025, 1, 1);

  @override
  Future<List<MediaItemEntity>> itemsForCategory(CategoryRef ref) async {
    final query = _db.select(_db.mediaItemsTable)
      ..where(
        (t) => t.trashedInSystem.equals(false) & t.isAvailable.equals(true),
      )
      ..where(_categoryPredicate(ref));
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
    final existing = await albums();
    final duplicate =
        existing.any((a) => a.name.toLowerCase() == name.toLowerCase());
    if (duplicate) {
      throw const AlbumNameException('Já existe um álbum com esse nome.');
    }

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
  Future<void> seedIfEmpty() async {
    final countExpr = _db.mediaItemsTable.id.count();
    final result = await (_db.selectOnly(_db.mediaItemsTable)
          ..addColumns([countExpr]))
        .getSingle();
    final existing = result.read(countExpr) ?? 0;
    if (existing > 0) return;

    await _db.batch((batch) {
      batch.insertAll(_db.albumsTable, [
        AlbumsTableCompanion.insert(
          id: MockAlbums.familia,
          name: 'Família',
          createdAt: _seedDate,
        ),
        AlbumsTableCompanion.insert(
          id: MockAlbums.viagens,
          name: 'Viagens',
          createdAt: _seedDate,
        ),
        AlbumsTableCompanion.insert(
          id: MockAlbums.documentos,
          name: 'Documentos',
          createdAt: _seedDate,
        ),
      ]);
      batch.insertAll(
        _db.mediaItemsTable,
        MockMediaItems.all.map(_toCompanion).toList(),
      );
    });
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
}