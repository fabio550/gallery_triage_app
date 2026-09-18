import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:gallery_triage_app/core/domain/enums/triage_decision.dart';
import 'package:gallery_triage_app/core/infrastructure/data/local/converters/enum_converters.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'tables/albums_table.dart';
import 'tables/media_items_table.dart';
import 'tables/preferences_table.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [MediaItemsTable, AlbumsTable, PreferencesTable])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// Permite injetar uma conexão em memória em teste, sem passar pelo
  /// `path_provider`.
  AppDatabase.forTesting(super.connection);

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          // v2 — PreferencesTable (2.6). Bancos criados na v1
          // (MediaItemsTable + AlbumsTable) ganham só a tabela nova; os
          // dados de triagem já indexados não são tocados.
          if (from < 2) {
            await m.createTable(preferencesTable);
          }
          // v3 — 6.5.7 (álbum como pasta real): novas colunas em
          // MediaItemsTable. Sem valor pra linha existente ainda ficar
          // "pendente" — o default (`albumMovePending` falso) é
          // correto pra todo item já indexado antes desta versão, que
          // nunca teve movimento físico em aberto.
          if (from < 3) {
            await m.addColumn(
              mediaItemsTable,
              mediaItemsTable.preAlbumRelativePath,
            );
            await m.addColumn(
              mediaItemsTable,
              mediaItemsTable.albumMovePending,
            );
          }
          // v4 — 6.5.8 (ler álbuns/pastas já existentes no sistema):
          // `relativePath` em AlbumsTable. `null` em todo álbum já
          // existente — todos criados no app, seguem a convenção
          // padrão (`AlbumEntity.effectiveRelativePath`), nunca tiveram
          // pasta importada.
          if (from < 4) {
            await m.addColumn(albumsTable, albumsTable.relativePath);
          }
        },
      );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'gallery_triage.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}