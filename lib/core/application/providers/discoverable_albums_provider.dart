import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gallery_triage_app/core/application/providers/albums_provider.dart';
import 'package:gallery_triage_app/core/application/providers/media_repository_provider.dart';

/// 6.5.8 — uma pasta real do sistema com mídia (Câmera, WhatsApp
/// Images etc.) ainda não representada por nenhum [AlbumEntity].
class DiscoveredFolder {
  const DiscoveredFolder({required this.relativePath, required this.name});

  /// `RELATIVE_PATH` bruto do MediaStore, sempre com barra no final.
  final String relativePath;

  /// Último segmento do caminho — nome de exibição padrão ao importar.
  final String name;
}

/// Pastas do sistema com mídia que ainda não são nenhum álbum do app
/// (nem criado nele, nem importado antes) — o que falta pro painel de
/// álbuns (6.2.16) oferecer como opção além dos que o app já conhece.
/// Filtra comparando com [AlbumEntity.effectiveRelativePath] de cada
/// álbum já existente, não só os importados: um álbum criado no app
/// cuja pasta `Pictures/<nome>/` já tem itens de verdade não deve
/// reaparecer aqui como se fosse uma pasta nova.
final discoverableAlbumsProvider = FutureProvider<List<DiscoveredFolder>>((
  ref,
) async {
  final media = ref.watch(mediaRepositoryProvider);
  // `watch`, não `read`: reimportar/criar um álbum precisa refletir
  // aqui na próxima leitura, sem exigir reabrir a tela.
  final albums = ref.watch(albumsProvider);
  final claimed = albums.map((a) => a.effectiveRelativePath).toSet();

  final folders = await media.discoverMediaFolders();
  return folders
      .where((path) => !claimed.contains(path))
      .map((path) => DiscoveredFolder(relativePath: path, name: _leafName(path)))
      .toList()
    ..sort((a, b) => a.name.compareTo(b.name));
});

String _leafName(String relativePath) {
  final trimmed = relativePath.endsWith('/')
      ? relativePath.substring(0, relativePath.length - 1)
      : relativePath;
  final lastSlash = trimmed.lastIndexOf('/');
  return lastSlash == -1 ? trimmed : trimmed.substring(lastSlash + 1);
}
