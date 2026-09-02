class CategoryList extends StatelessWidget {
  final List<CategorySummary> categories;
  final CategoryGranularity granularity;
  final ValueChanged<CategorySummary> onCategoryTap;
  
  const CategoryList({
    required this.categories,
    required this.granularity,
    required this.onCategoryTap,
    super.key,
  });
  
    @override
  Widget build(BuildContext context) {
    
      if (categories.isEmpty) return const _EmptyGallery();

    final isAlbum = granularity == CategoryGranularity.album;

    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: categories.length,
      separatorBuilder: (_, __) => const Divider(indent: 74, endIndent: 0),
      itemBuilder: (context, index) {
        final summary = categories[index];
        return isAlbum
          ? CategoryTile.album(
              summary: summary,
              onTap: () => onCategoryTap(summary),
            )
          : CategoryTile(
              summary: summary,
              onTap: () => onCategoryTap(summary),
            );
      },
    );
  }
}

class _EmptyGallery extends StatelessWidget {
  const _EmptyGallery();
 
  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 34),
        child: Text(
          'Nenhum item indexado em DCIM ou Pictures/Screenshots.',
          textAlign: TextAlign.center,
          style: text.bodySmall,
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
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}
