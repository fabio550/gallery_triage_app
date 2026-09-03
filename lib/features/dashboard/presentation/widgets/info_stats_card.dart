import 'package:flutter/material.dart';
import 'package:gallery_triage_app/core/presentation/theme/triage_colors.dart';
import 'package:gallery_triage_app/core/presentation/widgets/progress_bar.dart';
import 'package:gallery_triage_app/core/presentation/widgets/progress_circular.dart';
import 'package:gallery_triage_app/features/dashboard/presentation/widgets/total_items_info.dart';
class InfoStatsCard extends StatelessWidget {
    final int totalItems;
    final double totalSizeGb;
    final int classifiedItems;
    final int keptItems;

  const InfoStatsCard({
    required this.totalItems,
    required this.totalSizeGb,
    required this.classifiedItems,
    required this.keptItems,
    super.key,
  });
  
  @override
  Widget build(BuildContext context) {
    
    final triageColors = context.triageColors;
    final classifiedIPercent = classifiedItems / totalItems;
    final keptPercent = keptItems / totalItems;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TotalItemsInfo(
                    totalItems: totalItems,
                    totalSizeGb: totalSizeGb,
                  ),
                  SizedBox(height: 8,),
                  Padding(
                    padding: EdgeInsetsGeometry.only(right: 16),
                    child: ProgressBar(
                      totalItems: totalItems,
                      classifiedItems: classifiedItems,
                      keptItems: keptItems,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 20,),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ProgressCircular(
                  context: context,
                  progressPercent: classifiedIPercent,
                  progressColor: triageColors.stateClassified,
                ),
                SizedBox(height: 20,),
                ProgressCircular(
                  context: context,
                  progressPercent: keptPercent,
                  progressColor: triageColors.stateKept,
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
