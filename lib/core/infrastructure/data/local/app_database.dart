import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:gallery_triage_app/core/domain/enums/triage_decision.dart';
import 'package:gallery_triage_app/core/infrastructure/data/local/converters/enum_converters.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'tables/albums_table.dart';
import 'tables/media_items_table.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [MediaItemsTable, AlbumsTable])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// Permite injetar uma conexão em memória em teste, sem passar pelo
  /// `path_provider`.
  AppDatabase.forTesting(super.connection);

  @override
  int get schemaVersion => 1;
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'gallery_triage.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}