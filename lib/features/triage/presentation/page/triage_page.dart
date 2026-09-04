import 'package:flutter/material.dart';

import 'package:gallery_triage_app/core/domain/models/category_summary.dart';
import 'package:gallery_triage_app/core/presentation/widgets/progress_bar.dart';
import 'package:gallery_triage_app/features/triage/presentation/widgets/media_card.dart';
import 'package:gallery_triage_app/features/triage/presentation/widgets/triage_card.dart';
import 'package:gallery_triage_app/features/triage/presentation/widgets/triage_carousel.dart';

class TriagePage extends StatefulWidget {
  const TriagePage({required this.category, super.key});

  final CategorySummary category;

  @override
  State<TriagePage> createState() => _TriagePageState();
}

class _TriagePageState extends State<TriagePage> {

  final List<Color> _items = const [
    Colors.green,
    Colors.red,
    Colors.orange,
    Colors.amber,
    Colors.blueGrey,
    Colors.indigo,
    Colors.teal,
    Colors.purple,
    Colors.brown,
    Colors.cyan,
  ];

  late int _currentIndex = _resolveInitialIndex();

  int _resolveInitialIndex() => 0; // TODO: 6.2.4

  bool get _hasNext => _currentIndex < _items.length - 1;

  void _advance() {
    if (_hasNext) setState(() => _currentIndex++);
    // TODO: §7 — fim da fila da categoria quando não há próximo.
  }

  // --- Decisões (3.4) -----------------------------------------------------
  // Swipe e botão chamam o mesmo método de propósito: são caminhos
  // equivalentes, e lambdas duplicadas divergiriam no primeiro ajuste.

  void _markForDeletion() {
    debugPrint('EXCLUIR item $_currentIndex');
    // TODO: gravar UndoEntry com âncora (6.2.15) e incrementar o badge.
    _advance();
  }

  void _keep() {
    debugPrint('MANTER item $_currentIndex');
    _advance();
  }

  /// Não altera decisão nem classificação. Apenas move o cursor (3.2.6).
  void _skip() => _advance();

  /// Toque no carrossel. Não entra na pilha de desfazer (6.2.14), mas
  /// define a âncora da próxima ação (6.2.15).
  void _jumpTo(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final category = widget.category;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            Text(category.label),
            Text(
              'Item ${_currentIndex + 1} de ${category.totalItems}',
              style: text.bodySmall,
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: ProgressBar(
              showLegend: true,
              totalItems: category.totalItems,
              classifiedItems: category.classifiedItems,
              keptItems: category.keptItems,
            ),
          ),
          TriageCarousel(
            items: _items,
            currentIndex: _currentIndex,
            onThumbTap: _jumpTo,
          ),
          Expanded(
            child: TriageCard(
              // Key por item: sem ela o State do card sobrevive à troca e
              // o próximo entra deslocado, onde o anterior saiu.
              key: ValueKey(_currentIndex),
              item: _items[_currentIndex],
              behind: _hasNext ? MediaCard(color: _items[_currentIndex + 1]) : null,
              onSwipeLeft: _markForDeletion,
              onSwipeRight: _keep,
            ),
          ),
          // TODO: TriageActionBar(onDelete:, onSkip:, onKeep:) — 6.2.12.
          // Enquanto não existe, _skip fica sem chamador.
        ],
      ),
    );
  }
}