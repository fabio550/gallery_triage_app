import 'package:flutter/material.dart';
import 'package:gallery_triage_app/core/domain/models/category_summary.dart';
import 'package:gallery_triage_app/core/presentation/theme/triage_colors.dart';
import 'package:gallery_triage_app/core/presentation/widgets/progress_bar.dart';
import 'package:gallery_triage_app/core/presentation/widgets/progress_circular.dart';

class CategoryTile extends StatelessWidget {
  final CategorySummary summary;
  final VoidCallback onTap;
  final bool _showMetrics;

  const CategoryTile({
    required this.summary,
    required this.onTap,
    super.key,
  }) : _showMetrics = true;

  const CategoryTile.album({
    required this.summary,
    required this.onTap,
    super.key,
  }) : _showMetrics = false;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    final triageColors = context.triageColors;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        child: Row(
          children: [
            _Cover(itemId: summary.coverItemId),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    summary.label,
                    style: text.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (_showMetrics) ...[
                    const SizedBox(height: 7),
                    ProgressBar(
                      showLegend: false,
                      totalItems: summary.totalItems,
                      classifiedItems: summary.classifiedItems,
                      keptItems: summary.keptItems,
                    ),
                  ] else
                    const SizedBox(height: 3),
                  Text(summary.countLabel, style: text.titleSmall),
                ],
              ),
            ),
            const SizedBox(width: 12),
            (_showMetrics) ?
              ProgressCircular(
                context: context,
                progressPercent: summary.keptItems / summary.totalItems,
                progressColor: triageColors.stateKept,
              ) : Icon(Icons.chevron_right, color: colors.onSurfaceVariant),
            Divider(),
          ],
        ),
      ),
    );
  }
}

class _Cover extends StatelessWidget {
  const _Cover({this.itemId});
 
  final String? itemId;
 
  @override
  Widget build(BuildContext context) {
    // Placeholder até o provider de miniatura existir. Falha de leitura
    // não impede a linha de funcionar (§7).
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}
