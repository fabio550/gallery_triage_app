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
    return Scaffold(
      appBar: AppBar(
        title: Text(category.label),
      ),
      body: Center(
        child: Text('data')
      ),
    );
  }
}