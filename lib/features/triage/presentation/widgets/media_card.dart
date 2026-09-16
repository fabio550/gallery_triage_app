import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gallery_triage_app/core/application/providers/thumbnail_provider.dart';
import 'package:gallery_triage_app/core/domain/entities/media_item_entity.dart';
import 'package:gallery_triage_app/core/presentation/theme/triage_colors.dart';
import 'package:gallery_triage_app/core/presentation/theme/triage_visual_state.dart';
import 'package:gallery_triage_app/core/presentation/widgets/media_placeholder.dart';

/// 6.2.8 — "carregado na resolução da tela, nunca em resolução
/// original" (8.6). 720px é bem acima do que qualquer card nesta UI
/// ocupa em tela, e evita decodificar o arquivo original (uma foto de
/// 12MP em resolução original chega a ~48MB, 8.6).
const _cardThumbnailSize = 720;

class MediaCard extends ConsumerWidget {
  final MediaItemEntity item;

  /// 6.2.17 — só troca o ícone de play/pause; é o card do próximo item
  /// (`behind`) que nunca deve receber `true`, já que ele não é o item
  /// ativo.
  final bool isPlaying;

  const MediaCard({
    required this.item,
    this.isPlaying = false,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Precedência de 3.3 — mesma regra usada no carrossel (CarouselThumb).
    final borderColor =
        TriageVisualState.of(item).colorIn(context.triageColors);
    final thumbnail = ref.watch(
      thumbnailProvider((item.mediaStoreId, _cardThumbnailSize)),
    );

    // Card quadrado, mas o tamanho acompanha a tela em vez de fixo:
    // 400 sozinho já é mais largo que a maioria dos aparelhos (~360 a
    // 430dp de largura lógica), o que ultrapassava a tela. Telas
    // maiores (tablet) ficam limitadas ao tamanho original.
    final screenWidth = MediaQuery.sizeOf(context).width;
    final cardSize = (screenWidth - 48).clamp(160.0, 400.0);

    return Container(
      width: cardSize,
      height: cardSize,
      clipBehavior: Clip.antiAlias,
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
      child: Stack(
        fit: StackFit.expand,
        children: [
          thumbnail.when(
            data: (bytes) => bytes == null
                ? const SizedBox.shrink()
                : Image.memory(bytes, fit: BoxFit.cover),
            loading: () => const SizedBox.shrink(),
            // §7 — falha de leitura de miniatura: o placeholder de cor
            // já preenche o fundo, o item continua triável normalmente.
            error: (Object error, StackTrace stackTrace) =>
                const SizedBox.shrink(),
          ),
          if (item.isVideo)
            Center(
              child: Icon(
                isPlaying
                    ? Icons.pause_circle_outline
                    : Icons.play_circle_outline,
                size: 48,
                color: Colors.white70,
              ),
            ),
        ],
      ),
    );
  }
}
