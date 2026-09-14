import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gallery_triage_app/core/application/providers/triage_repository_provider.dart';
import 'package:gallery_triage_app/core/domain/entities/album_entity.dart';

final albumsProvider = NotifierProvider<AlbumsNotifier, List<AlbumEntity>>(
  AlbumsNotifier.new,
);

/// Registro global de álbuns — não escopado por categoria, como o
/// próprio conceito de álbum (2.2.2). Persistido via Drift
/// (`TriageRepository.albums()`/`createAlbum()`); `build()` retorna
/// vazio de imediato e o valor real chega assíncrono, mesmo padrão do
/// `TriageSessionNotifier`/`DeletionModeNotifier`.
class AlbumsNotifier extends Notifier<List<AlbumEntity>> {
  late final _repository = ref.read(triageRepositoryProvider);

  @override
  List<AlbumEntity> build() {
    _load();
    return const [];
  }

  Future<void> _load() async {
    final albums = await _repository.albums();
    if (ref.mounted) state = albums;
  }

  /// Regras de 6.5.3 (nome único, ≤64 caracteres, caracteres
  /// proibidos) são validadas pelo `TriageRepository`, que lança
  /// `AlbumNameException` — o painel (6.2.16) trata isso inline, sem
  /// fechar o diálogo (§7). Retorna o id do álbum criado.
  Future<String> create(String rawName) async {
    final album = await _repository.createAlbum(rawName);
    state = [...state, album];
    return album.id;
  }

  /// Reavalia a lista — usado depois de qualquer escrita feita por
  /// fora deste notifier (nenhuma ainda, mas mantém o estado
  /// reconciliável se um dia existir gestão de álbuns fora daqui,
  /// 6.5.2/P-08).
  Future<void> refresh() => _load();
}
