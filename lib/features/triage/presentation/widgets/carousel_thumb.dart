import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gallery_triage_app/core/application/providers/thumbnail_provider.dart';
import 'package:gallery_triage_app/core/domain/entities/media_item_entity.dart';
import 'package:gallery_triage_app/core/presentation/theme/triage_colors.dart';
import 'package:gallery_triage_app/core/presentation/theme/triage_visual_state.dart';
import 'package:gallery_triage_app/core/presentation/widgets/media_placeholder.dart';

/// 8.5 — "requisitadas em aproximadamente 200x200".
const _thumbSize = 200;

class CarouselThumb extends ConsumerWidget {
  final MediaItemEntity item;
  final bool isActive;
  final VoidCallback onTap;

  const CarouselThumb({
    required this.item,
    required this.isActive,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stateColor = TriageVisualState.of(item).colorIn(context.triageColors);
    final thumbnail = ref.watch(thumbnailProvider((item.mediaStoreId, _thumbSize)));

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        width: 90,
        height: 90,
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          // Contorno de seleção do item ativo (6.2.6) — deliberadamente
          // um elemento visual separado da borda de estado abaixo, para
          // não se confundirem.
          border: isActive ? Border.all(color: Colors.white, width: 3) : null,
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : const [],
        ),
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: mediaPlaceholderColor(item.id),
            borderRadius: BorderRadius.circular(9),
            // Borda de estado (6.2.7, precedência 3.3) — sempre visível,
            // ativo ou não.
            border: Border.all(color: stateColor, width: 2),
          ),
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
                  child: Icon(Icons.videocam, size: 16, color: Colors.white70),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
