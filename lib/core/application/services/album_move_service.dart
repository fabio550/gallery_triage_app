import 'package:gallery_triage_app/core/application/services/album_move_result.dart';
import 'package:gallery_triage_app/core/domain/entities/media_item_entity.dart';
import 'package:gallery_triage_app/core/domain/repositories/media_repository.dart';
import 'package:gallery_triage_app/core/domain/repositories/triage_repository.dart';

/// 6.5.7 — "álbum como pasta real". Confirmação em lote, no mesmo
/// padrão já usado pela exclusão (4.3): o swipe/painel de álbuns só
/// grava local e marca `albumMovePending` (instantâneo); o movimento
/// físico de verdade — que pede confirmação do sistema — só roda
/// quando isto é chamado, tipicamente a partir da Tela de Revisão
/// (6.3, unificada com a fila de exclusão).
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

  /// Só a contagem, pra badges/gatilhos que não precisam da lista.
  Future<int> pendingCount() async {
    final pending = await _triage.itemsPendingAlbumMove();
    return pending.length;
  }

  /// Lista completa, pra Tela de Revisão renderizar a grade com
  /// miniaturas (6.3.2) — mesmo papel que `session.items` cumpre pra
  /// fila de exclusão, só que este conjunto não vive numa sessão.
  Future<List<MediaItemEntity>> pendingItems() =>
      _triage.itemsPendingAlbumMove();

  /// Resolve o destino de cada item pendente (pasta do álbum atual, ou
  /// [MediaItemEntity.preAlbumRelativePath] pra quem foi
  /// desclassificado/teve o álbum excluído) e confirma tudo numa
  /// chamada só — um diálogo do sistema pro lote inteiro, não um por
  /// destino. [onlyItemIds], quando informado, restringe o lote a um
  /// subconjunto (6.3.3-like "Mover Selecionados" na Revisão, onde o
  /// usuário pode excluir item da confirmação); `null` processa tudo
  /// que está pendente.
  Future<AlbumMoveResult> confirmPendingMoves({Set<String>? onlyItemIds}) async {
    var pending = await _triage.itemsPendingAlbumMove();
    if (onlyItemIds != null) {
      pending = pending.where((i) => onlyItemIds.contains(i.id)).toList();
    }
    if (pending.isEmpty) {
      return const AlbumMoveResult(movedCount: 0, failedCount: 0);
    }

    final albums = await _triage.albums();
    final albumById = {for (final a in albums) a.id: a};

    final movesByMediaStoreId =
        <int, ({String targetRelativePath, bool isVideo})>{};
    final itemByMediaStoreId = <int, MediaItemEntity>{};
    for (final item in pending) {
      // MediaStore.RELATIVE_PATH exige barra no final ("Pictures/Nome/",
      // nunca "Pictures/Nome") — sem ela o SO ignora a atualização
      // silenciosamente (nem lança erro, só devolve 0 linhas afetadas,
      // reportado aqui como falha do item). preAlbumRelativePath já
      // vem assim (lido de RELATIVE_PATH de verdade pelo scan);
      // [AlbumEntity.effectiveRelativePath] já devolve a pasta com
      // barra no final, tanto pra convenção padrão quanto pra álbum
      // importado de uma pasta existente (6.5.8).
      final target = item.albumId != null
          ? albumById[item.albumId]?.effectiveRelativePath
          : item.preAlbumRelativePath;
      // Defensivo (§7): item pendente sem álbum e sem origem gravada
      // não deveria existir (assignToAlbum sempre grava a origem antes
      // de marcar pendente), mas sem alvo não há o que mover.
      if (target == null) continue;
      movesByMediaStoreId[item.mediaStoreId] =
          (targetRelativePath: target, isVideo: item.isVideo);
      itemByMediaStoreId[item.mediaStoreId] = item;
    }

    if (movesByMediaStoreId.isEmpty) {
      return const AlbumMoveResult(movedCount: 0, failedCount: 0);
    }

    final movedIds = await _media.moveAssetsToPaths(movesByMediaStoreId);

    final succeeded = <MediaItemEntity>[];
    for (final id in movedIds) {
      final item = itemByMediaStoreId[id];
      final target = movesByMediaStoreId[id]?.targetRelativePath;
      if (item != null && target != null) {
        succeeded.add(item.applyAlbumMove(target));
      }
    }

    if (succeeded.isNotEmpty) {
      await _triage.applyAlbumMoveOutcome(succeeded);
    }

    return AlbumMoveResult(
      movedCount: succeeded.length,
      failedCount: movesByMediaStoreId.length - succeeded.length,
    );
  }
}
