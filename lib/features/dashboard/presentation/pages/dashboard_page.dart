import 'package:flutter/material.dart';
import 'package:gallery_triage_app/core/domain/enums/category_granularity.dart';
import 'package:gallery_triage_app/features/dashboard/infrastructure/data/mock_categories.dart';
import 'package:gallery_triage_app/features/dashboard/presentation/widgets/category_list.dart';
import 'package:gallery_triage_app/features/dashboard/presentation/widgets/granularity_selector.dart';
import 'package:gallery_triage_app/features/dashboard/presentation/widgets/info_stats_card.dart';
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  
  CategoryGranularity _granularity = CategoryGranularity.all;

  @override
  Widget build(BuildContext context) {
    
    // TEMPORÁRIO: dados fixos até o repositório existir.
    const totalItems = 62418;
    const totalSizeGb = 21.7;
    const classifiedItems = 18902;
    const keptItems = 27310;
    final categories = MockCategories.of(_granularity);
    
    return Scaffold(
      appBar: AppBar(title: const Text('Triagem')),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: InfoStatsCard(
              totalItems: totalItems,
              totalSizeGb: totalSizeGb,
              classifiedItems: classifiedItems,
              keptItems: keptItems,
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GranularitySelector(
              selected: _granularity,
              onChanged: (value) => setState(() => _granularity = value),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: CategoryList(
                categories: categories,
                granularity: _granularity,
                onCategoryTap: (summary) => debugPrint(summary.ref.key),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
