import 'package:flutter/material.dart';
import 'package:gallery_triage_app/core/domain/enums/category_granularity.dart';
import 'package:gallery_triage_app/features/dashboard/infrastructure/data/mock_categories.dart';
import 'package:gallery_triage_app/features/dashboard/presentation/widgets/category_list.dart';
import 'package:gallery_triage_app/features/dashboard/presentation/widgets/granularity_selector.dart';
import 'package:gallery_triage_app/features/dashboard/presentation/widgets/info_stats_card.dart';
import 'package:go_router/go_router.dart';
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  
  CategoryGranularity _granularity = CategoryGranularity.all;

  @override
  Widget build(BuildContext context) {
    
    // O card geral é a categoria "Todos os itens" — mesma fonte que
    // MockCategories.of(album/mês/ano/tipo), nunca um número à parte.
    final overall = MockCategories.of(CategoryGranularity.all).first;
    final categories = MockCategories.of(_granularity);
    
    return Scaffold(
      appBar: AppBar(title: const Text('Triagem')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: InfoStatsCard(
              totalItems: overall.totalItems,
              totalSizeGb: overall.sizeBytes / (1024 * 1024 * 1024),
              classifiedItems: overall.classifiedItems,
              keptItems: overall.keptItems,
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
                onCategoryTap: (summary) =>
                    context.push('/triage-page', extra: summary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
