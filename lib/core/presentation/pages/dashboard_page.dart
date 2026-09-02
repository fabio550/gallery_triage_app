import 'package:flutter/material.dart';
import 'package:gallery_triage_app/core/presentation/theme/triage_colors.dart';
import 'package:gallery_triage_app/core/presentation/widgets/progress_bar.dart';
import 'package:gallery_triage_app/core/presentation/widgets/progress_circular.dart';
import 'package:gallery_triage_app/core/presentation/widgets/total_itens_info.dart';
import 'package:gallery_triage_app/core/presentation/widgets/granularity_selector.dart';
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  
  CategoryGranularity _granularity = CategoryGranularity.all;

  @override
  Widget build(BuildContext context) {
    
    const totalItems = 62418;
    const totalSizeGb = 21.7;
    const classifiedItems = 18902;
    const keptItems = 27310;

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
          const Expanded(child: SizedBox()),
        ],
      ),
    );
  }
}
