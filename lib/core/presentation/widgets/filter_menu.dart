class FilterMenu extends StatelessWidget {
  final FilterType selectedFilter;
  final ValueChanged<FilterType> onFilterChanged;
  
  const FilterMenu({
    required this.selectedFilter,
    required this.onFilterChanged,
    super.key,
  });
  
  @override
  Widget build(BuildContext context) {
    
    final color = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    Future<void> _showModal(BuildContext context) async {
      
      final FilterType? selected = await showModalBottomSheet<FilterType>(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (BuildContext context) {
          return Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 6,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Agrupar por',
                  style: text.bodyLarge,
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: FilterType.values.asMap().entries.map((entry) {

                      final index = entry.key;
                      final t = entry.value;
                      final isLast = index == FilterType.values.length - 1;
                      final isSelected = t == selectedFilter;

                      return InkWell(
                        onTap: () {
                          Navigator.pop(context, t);
                        },
                        child: Container(
                          decoration: BoxDecoration(
                          border: isLast ? null : Border(
                              bottom: BorderSide(
                                color: color.outline,
                                width: 1.0,
                              ),
                            ),                          
                          ),
                          child: ListTile(
                            trailing: isSelected
                            ? Icon(Icons.check, color: color.primary)
                            : null,
                            title: Text(
                              t.label,
                              style: text.bodyMedium,
                            ),
                          )
                        ),
                      );
                    }).toList(),
                  ),
                )
              ],
            ),
          );
        },
      );
      
      if (selected != null) {
        onFilterChanged(selected);
      }
    }
    
    

    return InkWell(
      onTap: () => _showModal(context),
      child: Center(
        child: SizedBox(
          width: MediaQuery.of(context).size.width-50,
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
              side: BorderSide(
                  color: color.outline,
                  width: 1.0,
                ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 12,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children:[
                  Text(selectedFilter.label),
                  Icon(Icons.menu),
                ]
              ),
            ),
          ),
        ),
      ),
    );
  }
}
