import 'package:flutter/material.dart';
import 'package:gallery_triage_app/core/domain/enums/category_granularity.dart';
import 'package:gallery_triage_app/features/dashboard/presentation/widgets/granularity_picker_sheet.dart';

class GranularitySelector extends StatelessWidget {
  const GranularitySelector({
    required this.selected,
    required this.onChanged,
    super.key,
  });

  final CategoryGranularity selected;
  final ValueChanged<CategoryGranularity> onChanged;

  Future<void> _open(BuildContext context) async {
    final choice = await GranularityPickerSheet.show(
      context,
      selected: selected,
    );
    if (choice != null && choice != selected) onChanged(choice);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return SizedBox(
      width: double.infinity,
      // Sem `shape` próprio: herda o `CardThemeData` do app (raio 18,
      // sem borda) — tinha um raio menor e uma borda visível só aqui,
      // destoando de todo outro Card do app.
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _open(context),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Agrupar por ${selected.label.toLowerCase()}',
                    style: text.bodyMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(Icons.expand_more, size: 20, color: colors.onSurfaceVariant),
              ],
            ),
          ),
        ),
      )
    );
  }
}

extension CategoryGranularityLabel on CategoryGranularity {
  String get label => switch (this) {
        CategoryGranularity.all => 'Todos os itens',
        CategoryGranularity.month => 'Mês',
        CategoryGranularity.year => 'Ano',
        CategoryGranularity.type => 'Tipo',
        CategoryGranularity.album => 'Álbuns',
      };
}
