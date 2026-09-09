import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gallery_triage_app/core/domain/models/category_summary.dart';
import 'package:gallery_triage_app/core/presentation/widgets/progress_bar.dart';
import 'package:gallery_triage_app/features/triage/application/triage_session_notifier.dart';
import 'package:gallery_triage_app/features/triage/presentation/widgets/media_card.dart';
import 'package:gallery_triage_app/features/triage/presentation/widgets/triage_action_bar.dart';
import 'package:gallery_triage_app/features/triage/presentation/widgets/triage_card.dart';
import 'package:gallery_triage_app/features/triage/presentation/widgets/triage_carousel.dart';

/// Sem estado próprio (2.1.2 — "Nenhum estado de triagem reside em
/// widget"). Cursor, itens e decisões vivem em [TriageSessionNotifier];
/// esta página só lê o estado e encaminha os callbacks de gesto/botão
/// para os métodos do notifier.
class TriagePage extends ConsumerWidget {
  const TriagePage({required this.category, super.key});

  final CategorySummary category;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final provider = triageSessionProvider(category.ref);
    final session = ref.watch(provider);
    final notifier = ref.read(provider.notifier);

    // TODO §7 (Etapa 8): estado de conclusão real, com resumo das duas
    // métricas e ação de retorno. Isto é só o guard mínimo para não
    // indexar `session.items` fora do intervalo quando a fila acaba ou
    // a categoria está vazia.
    if (session.isAtEnd) {
      return Scaffold(
        appBar: AppBar(title: Text(category.label)),
        body: Center(
          child: Text('Fila concluída', style: text.titleMedium),
        ),
      );
    }

    final current = session.currentItem!;
    final nextItem =
        session.hasNext ? session.items[session.currentIndex + 1] : null;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            Text(category.label),
            // `session.totalCount` em vez de `category.totalItems`: os
            // dois vêm do mesmo `MockMediaItems.forCategory`, mas usar o
            // da sessão evita depender de dois caminhos de agregação
            // ficarem sincronizados manualmente.
            Text(
              'Item ${session.currentIndex + 1} de ${session.totalCount}',
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
              totalItems: session.totalCount,
              classifiedItems: session.classifiedCount,
              keptItems: session.keptCount,
            ),
          ),
          TriageCarousel(
            items: session.items,
            currentIndex: session.currentIndex,
            onThumbTap: notifier.jumpTo,
          ),
          Expanded(
            child: TriageCard(
              // Key por item: sem ela o State do card sobrevive à troca e
              // o próximo entra deslocado, onde o anterior saiu.
              key: ValueKey(current.id),
              item: current,
              behind: nextItem != null ? MediaCard(item: nextItem) : null,
              onSwipeLeft: notifier.markForDeletion,
              onSwipeRight: notifier.keep,
            ),
          ),
          TriageActionBar(
            onDelete: notifier.markForDeletion,
            onSkip: notifier.skip,
            onKeep: notifier.keep,
          ),
        ],
      ),
    );
  }
}
