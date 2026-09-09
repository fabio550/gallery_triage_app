import 'package:flutter/material.dart';
import 'package:gallery_triage_app/core/domain/entities/media_item_entity.dart';
import 'package:gallery_triage_app/core/presentation/theme/triage_colors.dart';
import 'package:gallery_triage_app/core/presentation/theme/triage_visual_state.dart';
import 'package:gallery_triage_app/core/presentation/widgets/media_placeholder.dart';

class MediaCard extends StatelessWidget {
  final MediaItemEntity item;

  const MediaCard({
    required this.item,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    // Precedência de 3.3 — mesma regra usada no carrossel (CarouselThumb).
    final borderColor =
        TriageVisualState.of(item).colorIn(context.triageColors);

    return Container(
      width: 400,
      height: 400,
      decoration: BoxDecoration(
        color: mediaPlaceholderColor(item.id),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor, width: 4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      // Placeholder de vídeo — controles reais entram em 6.2.17 (Etapa 9).
      child: item.isVideo
          ? const Center(
              child: Icon(
                Icons.play_circle_outline,
                size: 48,
                color: Colors.white70,
              ),
            )
          : null,
    );
  }
}
