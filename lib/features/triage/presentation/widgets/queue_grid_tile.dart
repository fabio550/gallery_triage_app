import 'package:flutter/material.dart';
import 'package:gallery_triage_app/core/domain/entities/media_item_entity.dart';
import 'package:gallery_triage_app/core/presentation/theme/triage_colors.dart';
import 'package:gallery_triage_app/core/presentation/theme/triage_visual_state.dart';
import 'package:gallery_triage_app/core/presentation/widgets/media_placeholder.dart';

/// Grade da Tela de Revisão (6.3.2) — mesma convenção de borda de 3.3
/// usada no resto do app, não uma paleta nova. O selo no canto (marcado
/// para exclusão vs. restaurado) é redundante com a cor de propósito:
/// mesmo princípio de não comunicar só por cor do SwipeOverlay.
class QueueGridTile extends StatelessWidget {
  const QueueGridTile({
    required this.item,
    required this.onTap,
    super.key,
  });

  final MediaItemEntity item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final stateColor = TriageVisualState.of(item).colorIn(context.triageColors);
    final marked = item.isInDeletionQueue;

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
              child: item.isVideo
                  ? const Center(
                      child: Icon(Icons.videocam, color: Colors.white70),
                    )
                  : null,
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