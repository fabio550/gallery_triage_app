import 'package:gallery_triage_app/core/domain/enums/deletion_mode.dart';
import 'package:gallery_triage_app/core/domain/enums/sort_order.dart';
import 'package:gallery_triage_app/core/domain/models/category_summary.dart';
import 'package:gallery_triage_app/core/domain/repositories/preferences_repository.dart';

import 'app_database.dart';

/// Chave/valor sobre `PreferencesTable` (2.6). Cada preferência escalar
/// mora numa linha de chave fixa; `cursorPosition` grava uma linha por
/// categoria, com a chave prefixada — é a única preferência de 2.6
/// escopada por categoria, o resto do arquivo é global.
class DriftPreferencesRepository implements PreferencesRepository {
  DriftPreferencesRepository(this._db);

  final AppDatabase _db;

  static const _keySortOrder = 'sortOrder';
  static const _keyDeletionMode = 'deletionMode';
  static const _keyLastUsedAlbumId = 'lastUsedAlbumId';
  static const _keyLastSyncAt = 'lastSyncAt';
  static const _keyLastGeneration = 'lastGeneration';
  static const _keyScanOffset = 'scanOffset';

  @override
  Future<SortOrder> sortOrder() async {
    final raw = await _read(_keySortOrder);
    // Padrão: mais recente primeiro (6.2.3).
    return raw == null ? SortOrder.newestFirst : SortOrder.values.byName(raw);
  }

  @override
  Future<void> setSortOrder(SortOrder order) =>
      _write(_keySortOrder, order.name);

  @override
  Future<DeletionMode> deletionMode() async {
    final raw = await _read(_keyDeletionMode);
    // Padrão: lixeira do sistema — reversível (4.4.2).
    return raw == null ? DeletionMode.trash : DeletionMode.values.byName(raw);
  }

  @override
  Future<void> setDeletionMode(DeletionMode mode) =>
      _write(_keyDeletionMode, mode.name);

  @override
  Future<String?> lastUsedAlbumId() => _read(_keyLastUsedAlbumId);

  @override
  Future<void> setLastUsedAlbumId(String? albumId) => albumId == null
      ? _delete(_keyLastUsedAlbumId)
      : _write(_keyLastUsedAlbumId, albumId);

  @override
  Future<String?> cursorPosition(CategoryRef ref) => _read(_cursorKey(ref));

  @override
  Future<void> setCursorPosition(CategoryRef ref, String itemId) =>
      _write(_cursorKey(ref), itemId);

  @override
  Future<DateTime?> lastSyncAt() async {
    final raw = await _read(_keyLastSyncAt);
    return raw == null ? null : DateTime.parse(raw);
  }

  @override
  Future<int?> lastGeneration() async {
    final raw = await _read(_keyLastGeneration);
    return raw == null ? null : int.parse(raw);
  }

  @override
  Future<void> setLastSync({
    required DateTime at,
    required int generation,
  }) async {
    // As duas chaves andam juntas (5.3.6) — gravadas na mesma chamada
    // para não haver um estado intermediário com uma sem a outra.
    await _write(_keyLastSyncAt, at.toIso8601String());
    await _write(_keyLastGeneration, generation.toString());
  }

  @override
  Future<int?> scanOffset() async {
    final raw = await _read(_keyScanOffset);
    return raw == null ? null : int.parse(raw);
  }

  @override
  Future<void> setScanOffset(int? offset) => offset == null
      ? _delete(_keyScanOffset)
      : _write(_keyScanOffset, offset.toString());

  // --- Chave/valor genérico -----------------------------------------

  /// `cursor::<granularidade>::<chave da categoria>` — único jeito de
  /// 2.6 que precisa de uma linha por categoria em vez de uma global.
  String _cursorKey(CategoryRef ref) =>
      'cursor::${ref.granularity.name}::${ref.key}';

  Future<String?> _read(String key) async {
    final row = await (_db.select(
      _db.preferencesTable,
    )..where((t) => t.key.equals(key))).getSingleOrNull();
    return row?.value;
  }

  Future<void> _write(String key, String value) {
    return _db
        .into(_db.preferencesTable)
        .insertOnConflictUpdate(
          PreferencesTableCompanion.insert(key: key, value: value),
        );
  }

  Future<void> _delete(String key) async {
    await (_db.delete(
      _db.preferencesTable,
    )..where((t) => t.key.equals(key))).go();
  }
}
