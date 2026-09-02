import 'package:flutter/material.dart';
import 'package:gallery_triage_app/core/domain/enums/category_granularity.dart';
import 'package:gallery_triage_app/features/dashboard/presentation/widgets/granularity_selector.dart';

class GranularityPickerSheet extends StatelessWidget {
  const GranularityPickerSheet({required this.selected, super.key});

  final CategoryGranularity selected;

  static Future<CategoryGranularity?> show(
    BuildContext context, {
    required CategoryGranularity selected,
  }) {
    return showModalBottomSheet<CategoryGranularity>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => GranularityPickerSheet(selected: selected),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: Text('Agrupar por', style: text.titleMedium),
          ),
          for (final granularity in CategoryGranularity.values)
            ListTile(
              title: Text(granularity.label, style: text.bodyMedium),
              trailing: granularity == selected
                  ? Icon(Icons.check, color: colors.primary)
                  : null,
              onTap: () => Navigator.pop(context, granularity),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
