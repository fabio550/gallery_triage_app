import 'package:drift/drift.dart';

/// Tabela chave/valor para o estado global de 2.6 — `sortOrder`,
/// `deletionMode`, `lastUsedAlbumId`, `cursorPosition` (uma linha por
/// categoria, chave prefixada — ver `DriftPreferencesRepository`),
/// `lastSyncAt`/`lastGeneration` e `scanOffset`.
///
/// Chave/valor genérico em vez de uma coluna por preferência: 2.6 lista
/// tipos e escopos heterogêneos (enum, String?, DateTime, int?, e um
/// valor por categoria) que não caberiam bem numa linha singleton — e
/// uma preferência nova não exige migração de schema, só uma chave
/// nova. A tipagem e a decodificação ficam no `PreferencesRepository`
/// (camada `data`), não aqui.
class PreferencesTable extends Table {
  @override
  String get tableName => 'preferences';

  TextColumn get key => text()();

  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}
