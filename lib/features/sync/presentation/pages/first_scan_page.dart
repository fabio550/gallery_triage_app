import 'package:flutter/material.dart';

/// 5.2.1 — "Tela dedicada com progresso... dashboard não abre antes da
/// conclusão." Progresso indeterminado (o total real só é conhecido no
/// fim, e mostrar um total desatualizado seria pior que não mostrar
/// nenhum) com a contagem de itens já indexados, que é o número que
/// importa pro usuário.
class FirstScanPage extends StatelessWidget {
  const FirstScanPage({required this.processed, super.key});

  final int processed;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 24),
                Text('Organizando sua galeria', style: text.headlineSmall),
                const SizedBox(height: 8),
                Text(
                  '$processed itens indexados',
                  style: text.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Só acontece uma vez — pode levar alguns minutos numa '
                  'galeria grande.',
                  style: text.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
