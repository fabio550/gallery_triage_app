import 'package:flutter/material.dart';
import 'package:gallery_triage_app/core/domain/models/category_summary.dart';
class TriagePage extends StatelessWidget {
  final CategorySummary category;
  
  const TriagePage({
    required this.category,
    super.key
  });

  @override
  Widget build(BuildContext context) {
    
    final text = Theme.of(context).textTheme;
    final List<Color> items = [
      Colors.green,
      Colors.red,
      Colors.orange,
      Colors.amber,
      Colors.blueGrey,
      Colors.indigo,
      Colors.green,
      Colors.red,
      Colors.orange,
      Colors.amber,
      Colors.blueGrey,
      Colors.indigo,
    ];

    
    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            Text(category.label),
            Text(
              'Item X de ${category.totalItems}',
              style: text.bodySmall,
            ),
          ]
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsetsGeometry.symmetric(horizontal: 40),
              child: ProgressBar(
              showLegend: true,
              totalItems: category.totalItems,
              classifiedItems: category.classifiedItems,
              keptItems: category.keptItems,
            ),
          ),
          Expanded(
            child: TriageCarousel(items: items),
          )
        ]
      ),
    );
  }
}
