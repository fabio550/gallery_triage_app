import 'package:gallery_triage_app/core/application/services/album_move_result.dart';
import 'package:gallery_triage_app/core/domain/entities/media_item_entity.dart';
import 'package:gallery_triage_app/core/domain/repositories/media_repository.dart';
import 'package:gallery_triage_app/core/domain/repositories/triage_repository.dart';

/// 6.5.7 — "álbum como pasta real". Confirmação em lote, no mesmo
/// padrão já usado pela exclusão (4.3): o swipe/painel de álbuns só
/// grava local e marca `albumMovePending` (instantâneo); o movimento
/// físico de verdade — que pede confirmação do sistema
/// (`createWriteRequest`, via [MediaRepository.moveAssetsToRelativePath])
/// — só roda quando isto é chamado, tipicamente ao sair de uma sessão
/// de triagem.
///
/// O lote pendente é global (qualquer categoria), não escopado por
/// sessão — diferente da fila de exclusão (3.5.1), porque classificar
/// num álbum pode acontecer em qualquer categoria e o item físico só
/// tem uma pasta de verdade.
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

  /// Agrupa por destino (pasta do álbum atual, ou [MediaItemEntity
  /// .preAlbumRelativePath] pra quem foi desclassificado/teve o álbum
  /// excluído) e confirma um lote por grupo — um diálogo do sistema por
  /// destino distinto, não um por item. Na sessão comum (um álbum por
  /// vez) isso já é um único diálogo.
  Future<AlbumMoveResult> confirmPendingMoves() async {
    final pending = await _triage.itemsPendingAlbumMove();
    if (pending.isEmpty) {
      return const AlbumMoveResult(movedCount: 0, failedCount: 0);
    }

    final albums = await _triage.albums();
    final albumNameById = {for (final a in albums) a.id: a.name};

    final groups = <String, List<MediaItemEntity>>{};
    for (final item in pending) {
      final target = item.albumId != null
          ? '$_albumsRoot/${albumNameById[item.albumId] ?? item.albumId}'
          : item.preAlbumRelativePath;
      // Defensivo (§7): item pendente sem álbum e sem origem gravada
      // não deveria existir (assignToAlbum sempre grava a origem antes
      // de marcar pendente), mas sem alvo não há o que mover.
      if (target == null) continue;
      groups.putIfAbsent(target, () => []).add(item);
    }

    final succeeded = <MediaItemEntity>[];
    var failedCount = 0;

    for (final entry in groups.entries) {
      final targetPath = entry.key;
      final items = entry.value;
      final ok = await _media.moveAssetsToRelativePath(
        items.map((i) => i.mediaStoreId).toList(),
        targetPath,
      );
      if (ok) {
        succeeded.addAll(items.map((i) => i.applyAlbumMove(targetPath)));
      } else {
        failedCount += items.length;
      }
    }

    if (succeeded.isNotEmpty) {
      await _triage.applyAlbumMoveOutcome(succeeded);
    }

    return AlbumMoveResult(
      movedCount: succeeded.length,
      failedCount: failedCount,
    );
  }
}
