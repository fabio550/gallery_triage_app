import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gallery_triage_app/core/application/providers/thumbnail_provider.dart';
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
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: Row(
          children: [
            _Cover(mediaStoreId: summary.coverMediaStoreId),
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
                    Padding(
                      padding: EdgeInsetsGeometry.only(right: 16),
                      child: ProgressBar(
                        showLegend: false,
                        totalItems: summary.totalItems,
                        classifiedItems: summary.classifiedItems,
                        keptItems: summary.keptItems,
                      ),
                    )
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
                progressPercent: summary.totalItems == 0
                    ? 0
                    : summary.keptItems / summary.totalItems,
                progressColor: triageColors.stateKept,
              ) : Icon(Icons.chevron_right, color: colors.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

class _Cover extends ConsumerWidget {
  const _Cover({this.mediaStoreId});

  final int? mediaStoreId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final radius = BorderRadius.circular(12);
    final id = mediaStoreId;

    // Sem capa (categoria de álbuns, cujo `coverMediaStoreId` pode não
    // ter chegado ainda) — placeholder liso. Falha de leitura não
    // impede a linha de funcionar (§7).
    if (id == null) {
      return Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHigh,
          borderRadius: radius,
        ),
      );
    }

    final thumbnail = ref.watch(thumbnailProvider((id, 200)));

    return ClipRRect(
      borderRadius: radius,
      child: SizedBox(
        width: 72,
        height: 72,
        child: thumbnail.when(
          data: (bytes) => bytes == null
              ? _placeholder(context)
              : Image.memory(bytes, fit: BoxFit.cover),
          loading: () => _placeholder(context),
          error: (Object error, StackTrace stackTrace) =>
              _placeholder(context),
        ),
      ),
    );
  }

  Widget _placeholder(BuildContext context) => Container(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
      );
}
