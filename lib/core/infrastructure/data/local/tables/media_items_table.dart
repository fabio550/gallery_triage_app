import 'package:drift/drift.dart';

import '../converters/enum_converters.dart';

/// Espelha [MediaItemEntity] campo a campo (spec 2.2.1). Índices conforme
/// 8.2, literal: decision, albumId, dateTaken, relativePath, mediaStoreId,
/// isScreenshot, trashedInSystem.
@TableIndex(name: 'idx_media_items_decision', columns: {#decision})
@TableIndex(name: 'idx_media_items_album_id', columns: {#albumId})
@TableIndex(name: 'idx_media_items_date_taken', columns: {#dateTaken})
@TableIndex(name: 'idx_media_items_relative_path', columns: {#relativePath})
@TableIndex(name: 'idx_media_items_media_store_id', columns: {#mediaStoreId})
@TableIndex(name: 'idx_media_items_is_screenshot', columns: {#isScreenshot})
@TableIndex(
  name: 'idx_media_items_trashed_in_system',
  columns: {#trashedInSystem},
)
class MediaItemsTable extends Table {
  @override
  String get tableName => 'media_items';

  /// UUID local (2.5.2). Chave primária — `mediaStoreId` não é estável
  /// o bastante para esse papel (2.5.1).
  TextColumn get id => text()();

  IntColumn get mediaStoreId => integer()();

  TextColumn get fingerprint => text()();

  DateTimeColumn get dateTaken => dateTime()();

  IntColumn get sizeBytes => integer()();

  TextColumn get mimeType => text()();

  TextColumn get relativePath => text()();

  TextColumn get mediaType => text().map(const MediaTypeConverter())();

  BoolColumn get isScreenshot => boolean()();

  /// Só existe em vídeo — mesma regra do `assert` da entidade.
  IntColumn get durationMs => integer().nullable()();

  TextColumn get decision =>
      text().map(const TriageDecisionConverter())();

  /// `null` = não classificado.
  TextColumn get albumId => text().nullable()();

  DateTimeColumn get decidedAt => dateTime().nullable()();

  /// Snapshot pré-fila (2.2.4) — viabiliza 3.5.3 e 5.4.1 sem alteração
  /// futura de schema.
  TextColumn get preQueueDecision =>
      text().map(const TriageDecisionConverter()).nullable()();

  TextColumn get preQueueAlbumId => text().nullable()();

  BoolColumn get trashedInSystem =>
      boolean().withDefault(const Constant(false))();

  DateTimeColumn get trashedAt => dateTime().nullable()();

  BoolColumn get isAvailable => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}