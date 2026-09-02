import 'package:flutter/material.dart';
import 'package:gallery_triage_app/core/presentation/theme/triage_colors.dart';
import 'package:gallery_triage_app/core/presentation/widgets/progress_bar.dart';
import 'package:gallery_triage_app/core/presentation/widgets/progress_circular.dart';
import 'package:gallery_triage_app/core/presentation/widgets/total_itens_info.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {

    final text = Theme.of(context).textTheme;

    final totalItens = 62418 == 0 ? 1 : 62418;
    final totalSize = 21.7;
    final primaryItens = 18902;
    final secondaryItens = 27310;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Triagem',
          style: text.titleMedium,
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          InfoStatsCard(
            totalItens: totalItens,
            totalSize: totalSize,
            primaryItens: primaryItens,
            secondaryItens: secondaryItens,
          ),
        ],
      ),
    );
  }
}
