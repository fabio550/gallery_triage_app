import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gallery_triage_app/core/domain/entities/album_entity.dart';
import 'package:gallery_triage_app/features/dashboard/infrastructure/data/mock_media_items.dart';

/// Nome de álbum inválido ou duplicado (7 — "erro inline no campo, sem
/// fechar o diálogo").
class AlbumNameException implements Exception {
  const AlbumNameException(this.message);
  final String message;
}

final albumsProvider =
    NotifierProvider<AlbumsNotifier, List<AlbumEntity>>(AlbumsNotifier.new);

/// Registro global de álbuns — não escopado por categoria, como o
/// próprio conceito de álbum (2.2.2). Em memória por enquanto; migra
/// para o índice local quando o Drift existir.
///
/// Semeado com os 3 álbuns de [MockAlbums] para manter os `albumId` já
/// gravados em `mock_media_items.dart` válidos. Álbuns criados pelo
/// painel (6.2.16) entram aqui, não em [MockAlbums] — aquele mapa fica
/// só como lookup do dataset original.
class AlbumsNotifier extends Notifier<List<AlbumEntity>> {
  @override
  List<AlbumEntity> build() {
    final seedDate = DateTime(2025, 1, 1);
    return [
      AlbumEntity(id: MockAlbums.familia, name: 'Família', createdAt: seedDate),
      AlbumEntity(id: MockAlbums.viagens, name: 'Viagens', createdAt: seedDate),
      AlbumEntity(
        id: MockAlbums.documentos,
        name: 'Documentos',
        createdAt: seedDate,
      ),
    ];
  }

  /// Regras de 6.5.3, antecipadas aqui porque o painel (6.2.16) já cria
  /// álbum pela via rápida, antes de existir a tela de gestão em si.
  /// Retorna o id do álbum criado.
  String create(String rawName) {
    final name = rawName.trim();

    if (name.isEmpty) {
      throw const AlbumNameException('Digite um nome para o álbum.');
    }
    if (name.length > 64) {
      throw const AlbumNameException('Nome muito longo (máximo 64 caracteres).');
    }
    if (RegExp(r'[/\\:*?"<>|]').hasMatch(name)) {
      throw const AlbumNameException('Nome não pode conter / \\ : * ? " < > |');
    }
    final duplicate =
        state.any((a) => a.name.toLowerCase() == name.toLowerCase());
    if (duplicate) {
      throw const AlbumNameException('Já existe um álbum com esse nome.');
    }

    final album = AlbumEntity(
      id: 'album-${DateTime.now().microsecondsSinceEpoch}',
      name: name,
      createdAt: DateTime.now(),
    );
    state = [...state, album];
    return album.id;
  }
}