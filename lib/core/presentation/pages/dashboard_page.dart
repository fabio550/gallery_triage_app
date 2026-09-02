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
    final triageColors = context.triageColors;

    final totalItens = 62418 == 0 ? 1 : 62418;
    final totalSize = 21.7;
    final primaryItens = 18902;
    final secondaryItens = 27310;
    final primaryPercent = primaryItens / totalItens;
    final secondaryPercent = secondaryItens / totalItens;

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
          Center(
            child: SizedBox(
              width: MediaQuery.of(context).size.width-50,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TotalItensInfo(
                            totalItens: totalItens,
                            totalSize: totalSize,
                          ),
                          SizedBox(height: 8,),
                          ProgressBar(
                            totalItens: totalItens,
                            primaryItens: primaryItens,
                            secondaryItens: secondaryItens,
                          ),
                        ],
                      ),
                      SizedBox(width: 20,),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          ProgressCircular(
                            context: context,
                            progressPercent: primaryPercent,
                            progressColor: triageColors.stateClassified,
                          ),
                          SizedBox(height: 20,),
                          ProgressCircular(
                            context: context,
                            progressPercent: secondaryPercent,
                            progressColor: triageColors.stateKept,
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}