import 'package:flutter/material.dart';
import 'package:gallery_triage_app/core/presentation/theme/triage_colors.dart';
class ProgressBar extends StatelessWidget {
  final bool showLegend;
  final int totalItems;
  final int classifiedItems;
  final int keptItems;

  const ProgressBar({
    this.showLegend = true,
    required this.totalItems,
    required this.classifiedItems,
    required this.keptItems,
    super.key
  });

  @override
  Widget build(BuildContext context) {

  final color = Theme.of(context).colorScheme;
  final triageColors = context.triageColors;
  final text = Theme.of(context).textTheme;

  final total = totalItems == 0 ? 1 : totalItems;

  final classifiedPercent = classifiedItems / total;
  final keptPercent = keptItems / total;

    return Column(
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
              value: keptPercent.clamp(0.0, 1.0),                
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation<Color>(
                triageColors.stateKept,
              ),
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            LinearProgressIndicator(
              value: classifiedPercent.clamp(0.0, 1.0),                
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation<Color>(
                triageColors.stateClassified,
              ),
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
        SizedBox(height: 12,),
        !showLegend ? SizedBox() : 
        Wrap(
          spacing: 12,
          runSpacing: 4,
          children: [
            Text.rich(
              TextSpan(
                text: '●',
                style: text.labelSmall?.copyWith(
                  color: triageColors.stateClassified,
                ),
                children: [
                  TextSpan(
                    text: ' Classificados - ',
                    style: text.labelSmall?.copyWith(
                      color: color.onSurfaceVariant,
                    ),
                  ),
                  TextSpan(
                    text: '$classifiedItems',
                    style: text.labelSmall?.copyWith(
                      color: color.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Text.rich(
              TextSpan(
                text: '●',
                style: text.labelSmall?.copyWith(
                  color: triageColors.stateKept,
                ),
                children: [
                  TextSpan(
                    text: ' Mantidos - ',
                    style: text.labelSmall?.copyWith(
                      color: color.onSurfaceVariant,
                    ),
                  ),
                  TextSpan(
                    text: '$keptItems',
                    style: text.labelSmall?.copyWith(
                      color: color.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Text.rich(
              TextSpan(
                text: '●',
                style: text.labelSmall?.copyWith(
                  color: color.outline,
                ),
                children: [
                  TextSpan(
                    text: ' Não decididos - ',
                    style: text.labelSmall?.copyWith(
                      color: color.onSurfaceVariant,
                    ),
                  ),
                  TextSpan(
                    text: '${total - keptItems}',
                    style: text.labelSmall?.copyWith(
                      color: color.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
