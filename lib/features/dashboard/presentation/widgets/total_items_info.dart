import 'package:flutter/material.dart';

class TotalItemsInfo extends StatelessWidget {
  final int totalItems;
  final double totalSize;

  const TotalItemsInfo({
    required this.totalItems,
    required this.totalSize,
    super.key
  });

  @override
  Widget build(BuildContext context) {

    final text = Theme.of(context).textTheme;
    final color = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            text: totalItens.toString().replaceAllMapped(
              RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), 
              (m) => '${m[1]}.'
            ).toString(),
            style: text.titleLarge,
            children: [
              TextSpan(
                text: ' itens',
                style: text.bodyMedium?.copyWith(
                  color: color.onSurfaceVariant, 
                ),
              )
            ]
          )
        ),
        Text(
          '${totalSize.toStringAsFixed(1)} GB',
          style: text.bodyMedium?.copyWith(
            color: color.onSurfaceVariant, 
          ),
        ),
      ],
    );
  }
}
