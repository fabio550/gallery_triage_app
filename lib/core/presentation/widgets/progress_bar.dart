import 'package:flutter/material.dart';
import 'package:gallery_triage_app/core/presentation/theme/triage_colors.dart';

class ProgressBar extends StatelessWidget {
  final int totalItens;
  final int primaryItens;
  final int secondaryItens;

  const ProgressBar({
    required this.totalItens,
    required this.primaryItens,
    required this.secondaryItens,
    super.key
  });

  @override
  Widget build(BuildContext context) {

  final color = Theme.of(context).colorScheme;
  final triageColors = context.triageColors;
  final text = Theme.of(context).textTheme;

  final total = totalItens == 0 ? 1 : totalItens;

  final primaryPercent = primaryItens / total;
  final secondaryPercent = secondaryItens / total;

    return SizedBox(
      width: 160,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              LinearProgressIndicator(
                value: 1,
                backgroundColor: Colors.transparent,
                valueColor: AlwaysStoppedAnimation<Color>(
                  color.outline,
                ),
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
              LinearProgressIndicator(
                value: secondaryPercent.clamp(0.0, 1.0),                backgroundColor: Colors.transparent,
                valueColor: AlwaysStoppedAnimation<Color>(
                  triageColors.stateKept,
                ),
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
              LinearProgressIndicator(
                value: primaryPercent.clamp(0.0, 1.0),                backgroundColor: Colors.transparent,
                valueColor: AlwaysStoppedAnimation<Color>(
                  triageColors.stateClassified,
                ),
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          ),
          SizedBox(height: 12,),
          Text.rich(
            TextSpan(
              text: '●',
              style: text.titleMedium?.copyWith(
                color: triageColors.stateClassified,
              ),
              children: [
                TextSpan(
                  text: ' Classificados - ',
                  style: text.titleSmall?.copyWith(
                    color: color.onSurfaceVariant,
                  ),
                ),
                TextSpan(
                  text: '$primaryItens',
                  style: text.titleSmall?.copyWith(
                    color: color.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Text.rich(
            TextSpan(
              text: '●',
              style: text.titleMedium?.copyWith(
                color: triageColors.stateKept,
              ),
              children: [
                TextSpan(
                  text: ' Mantidos - ',
                  style: text.titleSmall?.copyWith(
                    color: color.onSurfaceVariant,
                  ),
                ),
                TextSpan(
                  text: '$secondaryItens',
                  style: text.titleSmall?.copyWith(
                    color: color.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}