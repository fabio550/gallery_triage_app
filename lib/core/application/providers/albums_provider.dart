import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gallery_triage_app/core/application/providers/categories_provider.dart';
import 'package:gallery_triage_app/core/application/providers/last_used_album_provider.dart';
import 'package:gallery_triage_app/core/application/providers/triage_repository_provider.dart';
import 'package:gallery_triage_app/core/domain/entities/album_entity.dart';
import 'package:gallery_triage_app/core/domain/enums/category_granularity.dart';

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
    _invalidateDashboard();
    return album.id;
  }

  /// 6.5.4 — renomeia, sem afetar os vínculos existentes.
  Future<AlbumEntity> rename(String albumId, String rawName) async {
    final renamed = await _repository.renameAlbum(albumId, rawName);
    state = [
      for (final a in state) a.id == albumId ? renamed : a,
    ];
    _invalidateDashboard();
    return renamed;
  }

  /// 6.5.5/6.5.6 — exclui o álbum e desclassifica os itens vinculados
  /// (repositório cuida disso). Limpa `lastUsedAlbumId` se era este o
  /// álbum armado (2.6.3), senão o atalho de swipe pra cima (6.2.18)
  /// ficaria apontando pra um álbum que não existe mais.
  Future<void> delete(String albumId) async {
    await _repository.deleteAlbum(albumId);
    state = state.where((a) => a.id != albumId).toList();
    ref.read(lastUsedAlbumProvider.notifier).clearIfMatches(albumId);
    _invalidateDashboard();
  }

  /// Reavalia a lista — usado depois de qualquer escrita feita por
  /// fora deste notifier.
  Future<void> refresh() => _load();

  /// Criar/renomear/excluir álbum muda tanto a categoria "Álbuns" quanto
  /// a contagem "Todos os itens" (um item pode trocar de álbum) e as
  /// contagens usadas pelo painel de gestão — sem isso, o Dashboard
  /// mostraria dado velho ao voltar da tela de álbuns.
  void _invalidateDashboard() {
    ref.invalidate(categoriesProvider(CategoryGranularity.album));
    ref.invalidate(categoriesProvider(CategoryGranularity.all));
    ref.invalidate(albumItemCountsProvider);
  }
}
