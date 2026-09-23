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

    return DecoratedBox(
      // Véu em degradê atrás de toda a barra, não um fundo por botão:
      // garante contraste uniforme contra qualquer foto sem depender
      // da cor de cada ícone, e ainda deixa a foto transparecer perto
      // do topo em vez de tapar tudo atrás dos botões.
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0),
            Colors.black.withValues(alpha: 0.7),
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 28, 12, 12),
        child: Row(
          // Cada botão dentro de Expanded: divide o espaço disponível
          // em partes iguais e nunca deixa o texto do rótulo (varia de
          // "Pular" a "Reproduzir") estourar a largura da tela --
          // antes cada botão só pedia sua largura natural, e a soma
          // dos quatro passava do limite em telas estreitas
          // ("RIGHT OVERFLOWED").
          children: [
            Expanded(
              child: _ActionButton(
                icon: Icons.delete_outline,
                label: 'Excluir',
                color: triageColors.stateMarkedForDeletion,
                onTap: onDelete,
              ),
            ),
            if (isVideo)
              Expanded(
                child: _ActionButton(
                  icon: isPlaying ? Icons.pause : Icons.play_arrow,
                  label: isPlaying ? 'Pausar' : 'Reproduzir',
                  color: colors.onSurfaceVariant,
                  onTap: onTogglePlay ?? () {},
                ),
              ),
            Expanded(
              child: _ActionButton(
                icon: Icons.skip_next_outlined,
                label: 'Pular',
                color: colors.onSurfaceVariant,
                onTap: onSkip,
              ),
            ),
            Expanded(
              child: _ActionButton(
                icon: Icons.check,
                label: 'Manter',
                color: triageColors.stateKept,
                onTap: onKeep,
              ),
            ),
          ],
        ),
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              // Preenchimento sólido na cor semântica (não mais um
              // contorno fino sobre fundo translúcido): já sentado
              // sobre o véu escuro da barra, a cor de cada ação salta
              // aos olhos sem depender de mais nenhuma camada.
              color: color,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 26),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: text.labelSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              shadows: const [
                Shadow(color: Colors.black87, blurRadius: 4),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
