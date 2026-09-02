
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
                    // TODO: SegmentedProgressBar(
                    //   total: summary.totalItems,
                    //   kept: summary.keptItems,
                    //   classified: summary.classifiedItems,
                    // )
                    const SizedBox(height: 6, width: double.infinity),
                    const SizedBox(height: 6),
                  ] else
                    const SizedBox(height: 3),
                  Text(summary.countLabel, style: text.labelSmall),
                ],
              ),
            ),
            const SizedBox(width: 12),
            if (_showMetrics)
              // TODO: ProgressRing(value: summary.keptRatio, size: 38)
              const SizedBox(width: 38, height: 38)
            else
              Icon(Icons.chevron_right, color: colors.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
