import 'package:gallery_triage_app/core/application/services/album_move_result.dart';
import 'package:gallery_triage_app/core/domain/entities/media_item_entity.dart';
import 'package:gallery_triage_app/core/domain/repositories/media_repository.dart';
import 'package:gallery_triage_app/core/domain/repositories/triage_repository.dart';

/// 6.5.7 — "álbum como pasta real". Confirmação em lote, no mesmo
/// padrão já usado pela exclusão (4.3): o swipe/painel de álbuns só
/// grava local e marca `albumMovePending` (instantâneo); o movimento
/// físico de verdade — que pede confirmação do sistema — só roda
/// quando isto é chamado, tipicamente ao sair de uma sessão de
/// triagem.
///
/// O lote pendente é global (qualquer categoria), não escopado por
/// sessão — diferente da fila de exclusão (3.5.1), porque classificar
/// num álbum pode acontecer em qualquer categoria e o item físico só
/// tem uma pasta de verdade. [MediaRepository.moveAssetsToPaths] pede
/// a concessão do sistema pro lote inteiro de uma vez só — um único
/// diálogo, mesmo que os itens tenham destinos (álbuns) diferentes.
class AlbumMoveService {
  AlbumMoveService({
    required MediaRepository mediaRepository,
    required TriageRepository triageRepository,
  })  : _media = mediaRepository,
        _triage = triageRepository;

  final MediaRepository _media;
  final TriageRepository _triage;

  static const _albumsRoot = 'Pictures';

  /// 6.5.7 — só a contagem, pra decidir se vale mostrar o diálogo de
  /// confirmação antes de sair da triagem.
  Future<int> pendingCount() async {
    final pending = await _triage.itemsPendingAlbumMove();
    return pending.length;
  }

  /// Resolve o destino de cada item pendente (pasta do álbum atual, ou
  /// [MediaItemEntity.preAlbumRelativePath] pra quem foi
  /// desclassificado/teve o álbum excluído) e confirma tudo numa
  /// chamada só — um diálogo do sistema pro lote inteiro, não um por
  /// destino.
  Future<AlbumMoveResult> confirmPendingMoves() async {
    final pending = await _triage.itemsPendingAlbumMove();
    if (pending.isEmpty) {
      return const AlbumMoveResult(movedCount: 0, failedCount: 0);
    }

    final albums = await _triage.albums();
    final albumNameById = {for (final a in albums) a.id: a.name};

    final targetByMediaStoreId = <int, String>{};
    final itemByMediaStoreId = <int, MediaItemEntity>{};
    for (final item in pending) {
      final target = item.albumId != null
          ? '$_albumsRoot/${albumNameById[item.albumId] ?? item.albumId}'
          : item.preAlbumRelativePath;
      // Defensivo (§7): item pendente sem álbum e sem origem gravada
      // não deveria existir (assignToAlbum sempre grava a origem antes
      // de marcar pendente), mas sem alvo não há o que mover.
      if (target == null) continue;
      targetByMediaStoreId[item.mediaStoreId] = target;
      itemByMediaStoreId[item.mediaStoreId] = item;
    }

    if (targetByMediaStoreId.isEmpty) {
      return const AlbumMoveResult(movedCount: 0, failedCount: 0);
    }

    final movedIds = await _media.moveAssetsToPaths(targetByMediaStoreId);

    final succeeded = <MediaItemEntity>[];
    for (final id in movedIds) {
      final item = itemByMediaStoreId[id];
      final target = targetByMediaStoreId[id];
      if (item != null && target != null) {
        succeeded.add(item.applyAlbumMove(target));
      }
    }

    if (succeeded.isNotEmpty) {
      await _triage.applyAlbumMoveOutcome(succeeded);
    }

    return AlbumMoveResult(
      movedCount: succeeded.length,
      failedCount: targetByMediaStoreId.length - succeeded.length,
    );
  }
}
