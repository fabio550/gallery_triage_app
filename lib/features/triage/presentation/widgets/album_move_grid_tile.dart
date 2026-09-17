import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gallery_triage_app/core/application/providers/thumbnail_provider.dart';
import 'package:gallery_triage_app/core/domain/entities/media_item_entity.dart';
import 'package:gallery_triage_app/core/presentation/widgets/media_placeholder.dart';

const _thumbSize = 200;

/// Grade da seção "Pra mover de álbum" na Revisão (6.5.7) — mesma
/// convenção visual de [QueueGridTile] (borda + selo no canto), mas o
/// selo aqui é sobre inclusão nesta confirmação, não sobre decisão de
/// domínio: excluir um item aqui não desclassifica nada, só deixa de
/// movê-lo agora — ele continua pendente pra próxima revisão.
class AlbumMoveGridTile extends ConsumerWidget {
  const AlbumMoveGridTile({
    required this.item,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final MediaItemEntity item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final thumbnail =
        ref.watch(thumbnailProvider((item.mediaStoreId, _thumbSize)));

    return GestureDetector(
      onTap: onTap,
      child: AspectRatio(
        aspectRatio: 1,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Opacity(
              opacity: selected ? 1 : 0.35,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: mediaPlaceholderColor(item.id),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: selected ? colors.primary : colors.outline,
                    width: selected ? 3 : 1,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      thumbnail.when(
                        data: (bytes) => bytes == null
                            ? const SizedBox.shrink()
                            : Image.memory(bytes, fit: BoxFit.cover),
                        loading: () => const SizedBox.shrink(),
                        error: (Object error, StackTrace stackTrace) =>
                            const SizedBox.shrink(),
                      ),
                      if (item.isVideo)
                        const Center(
                          child: Icon(Icons.videocam, color: Colors.white70),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: CircleAvatar(
                radius: 11,
                backgroundColor: selected ? colors.primary : Colors.black54,
                child: Icon(
                  selected ? Icons.check : Icons.close,
                  size: 14,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
