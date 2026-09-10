import 'package:drift/drift.dart';

/// Espelha [AlbumEntity] (2.2.2). Unicidade de `name` (case-insensitive,
/// 6.5.3) é checada em código no repositório, não via collation do
/// Drift — evita depender de configuração de collation da conexão.
class AlbumsTable extends Table {
  @override
  String get tableName => 'albums';

  TextColumn get id => text()();

  TextColumn get name => text()();

  DateTimeColumn get createdAt => dateTime()();

  /// Reservado para os estágios 2 e 3 (1.3.2/1.3.3). Não usado ainda.
  TextColumn get externalRef => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}