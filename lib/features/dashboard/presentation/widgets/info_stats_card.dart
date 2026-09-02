class InfoStatsCard extends StatelessWidget {
    final int totalItens;
    final double totalSize;
    final int primaryItens;
    final int secondaryItens;

  const InfoStatsCard({
    required this.totalItens,
    required this.totalSize,
    required this.primaryItens,
    required this.secondaryItens,
    super.key,
  });
  
  @override
  Widget build(BuildContext context) {
    
    final triageColors = context.triageColors;
    final primaryPercent = primaryItens / totalItens;
    final secondaryPercent = secondaryItens / totalItens;

    return Center(
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
    );
  }
}
