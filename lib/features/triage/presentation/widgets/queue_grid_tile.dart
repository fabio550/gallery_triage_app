import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gallery_triage_app/core/application/providers/thumbnail_provider.dart';
import 'package:gallery_triage_app/core/domain/entities/media_item_entity.dart';
import 'package:gallery_triage_app/core/presentation/theme/triage_colors.dart';
import 'package:gallery_triage_app/core/presentation/theme/triage_visual_state.dart';
import 'package:gallery_triage_app/core/presentation/widgets/media_placeholder.dart';

const _thumbSize = 200;

/// Grade da Tela de Revisão (6.3.2) — mesma convenção de borda de 3.3
/// usada no resto do app, não uma paleta nova. O selo no canto (marcado
/// para exclusão vs. restaurado) é redundante com a cor de propósito:
/// mesmo princípio de não comunicar só por cor do SwipeOverlay.
class QueueGridTile extends ConsumerWidget {
  const QueueGridTile({
    required this.item,
    required this.onTap,
    super.key,
  });

  final MediaItemEntity item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stateColor = TriageVisualState.of(item).colorIn(context.triageColors);
    final marked = item.isInDeletionQueue;
    final thumbnail =
        ref.watch(thumbnailProvider((item.mediaStoreId, _thumbSize)));

    return GestureDetector(
      onTap: onTap,
      child: AspectRatio(
        aspectRatio: 1,
        child: Stack(
          fit: StackFit.expand,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: mediaPlaceholderColor(item.id),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: stateColor, width: 3),
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
            Positioned(
              top: 4,
              right: 4,
              child: CircleAvatar(
                radius: 11,
                backgroundColor:
                    marked ? const Color(0xFFF2554B) : Colors.black54,
                child: Icon(
                  marked ? Icons.delete : Icons.check,
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