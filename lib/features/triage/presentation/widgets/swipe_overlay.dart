import 'package:flutter/material.dart';

/// Lavagem de cor com ícone e rótulo, opacidade proporcional ao
/// deslocamento. O texto não é decoração: vermelho e verde são o par
/// mais confundido em deuteranopia, então a direção nunca é comunicada
/// só por cor — vale para as 4 direções (6.2.18), não só esquerda/
/// direita. Só uma fica ativa por vez, já que o eixo é travado no
/// TriageCard.
class SwipeOverlay extends StatelessWidget {
  const SwipeOverlay({
    required this.horizontalProgress,
    required this.verticalProgress,
    required this.lastUsedAlbumLabel,
    super.key,
  });

  /// -1 (esquerda/excluir) .. 1 (direita/manter).
  final double horizontalProgress;

  /// -1 (cima/classificar) .. 1 (baixo/abrir painel).
  final double verticalProgress;

  /// Nome do álbum armado em `lastUsedAlbumId`. Nulo = sem feedback de
  /// swipe para cima — o gesto está inerte (6.2.18).
  final String? lastUsedAlbumLabel;

  @override
  Widget build(BuildContext context) {
    if (horizontalProgress.abs() > 0.02) {
      final toRight = horizontalProgress > 0;
      return _overlay(
        context,
        opacity: horizontalProgress.abs(),
        color: toRight ? const Color(0xFF4C8DFF) : const Color(0xFFF2554B),
        icon: toRight ? Icons.check : Icons.delete_outline,
        label: toRight ? 'Manter' : 'Excluir',
      );
    }

    if (verticalProgress < -0.02 && lastUsedAlbumLabel != null) {
      return _overlay(
        context,
        opacity: verticalProgress.abs(),
        color: const Color(0xFF3DAA6B),
        icon: Icons.photo_album_outlined,
        label: lastUsedAlbumLabel!,
      );
    }

    if (verticalProgress > 0.02) {
      return _overlay(
        context,
        opacity: verticalProgress,
        color: const Color(0xFF808080),
        icon: Icons.expand_more,
        label: 'Álbuns',
      );
    }

    return const SizedBox.shrink();
  }

  Widget _overlay(
    BuildContext context, {
    required double opacity,
    required Color color,
    required IconData icon,
    required String label,
  }) {
    return Positioned.fill(
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.34 * opacity),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Opacity(
              opacity: opacity,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 44, color: Colors.white),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}