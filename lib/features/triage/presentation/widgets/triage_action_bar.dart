import 'package:flutter/material.dart';
import 'package:gallery_triage_app/core/presentation/theme/triage_colors.dart';

/// Rodapé da Tela de Triagem (6.2.12). Caminho equivalente ao swipe —
/// por isso os callbacks aqui são os mesmos métodos do notifier que o
/// `TriageCard` já chama, não lambdas separadas.
class TriageActionBar extends StatelessWidget {
  const TriageActionBar({
    required this.onDelete,
    required this.onSkip,
    required this.onKeep,
    this.isVideo = false,
    this.isPlaying = false,
    this.onTogglePlay,
    super.key,
  });

  final VoidCallback onDelete;
  final VoidCallback onSkip;
  final VoidCallback onKeep;

  /// 6.2.17 — controle de play/pause "presente apenas em itens de
  /// vídeo", ao lado do botão Pular.
  final bool isVideo;
  final bool isPlaying;
  final VoidCallback? onTogglePlay;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final triageColors = context.triageColors;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _ActionButton(
            icon: Icons.delete_outline,
            label: 'Excluir',
            color: triageColors.stateMarkedForDeletion,
            onTap: onDelete,
          ),
          if (isVideo)
            _ActionButton(
              icon: isPlaying ? Icons.pause : Icons.play_arrow,
              label: isPlaying ? 'Pausar' : 'Reproduzir',
              color: colors.onSurfaceVariant,
              onTap: onTogglePlay ?? () {},
            ),
          _ActionButton(
            icon: Icons.skip_next_outlined,
            label: 'Pular',
            color: colors.onSurfaceVariant,
            onTap: onSkip,
          ),
          _ActionButton(
            icon: Icons.check,
            label: 'Manter',
            color: triageColors.stateKept,
            onTap: onKeep,
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.14),
                border: Border.all(color: color, width: 1.5),
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(height: 6),
            Text(label, style: text.labelSmall?.copyWith(color: color)),
          ],
        ),
      ),
    );
  }
}