
/// Lavagem de cor com ícone e rótulo, opacidade proporcional ao
/// deslocamento. O texto não é decoração: vermelho e verde são o par mais
/// confundido em deuteranopia, então a direção nunca é comunicada só por
/// cor.
class SwipeOverlay extends StatelessWidget {
  const SwipeOverlay({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final opacity = progress.abs();
    if (opacity <= 0.02) return const SizedBox.shrink();

    final toRight = progress > 0;
    final color = toRight ? const Color(0xFF4C8DFF) : const Color(0xFFF2554B);

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
                  Icon(
                    toRight ? Icons.check : Icons.delete_outline,
                    size: 44,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    toRight ? 'Manter' : 'Excluir',
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
