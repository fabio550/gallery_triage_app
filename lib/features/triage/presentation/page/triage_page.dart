import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gallery_triage_app/core/application/providers/last_used_album_provider.dart';
import 'package:gallery_triage_app/core/domain/models/category_summary.dart';
import 'package:gallery_triage_app/core/presentation/widgets/progress_bar.dart';
import 'package:gallery_triage_app/features/dashboard/infrastructure/data/mock_media_items.dart';
import 'package:gallery_triage_app/features/triage/application/triage_session_notifier.dart';
import 'package:gallery_triage_app/features/triage/presentation/widgets/album_panel.dart';
import 'package:gallery_triage_app/features/triage/presentation/widgets/media_card.dart';
import 'package:gallery_triage_app/features/triage/presentation/widgets/triage_action_bar.dart';
import 'package:gallery_triage_app/features/triage/presentation/widgets/triage_card.dart';
import 'package:gallery_triage_app/features/triage/presentation/widgets/triage_carousel.dart';

/// Sem estado próprio de triagem (2.1.2 — "Nenhum estado de triagem
/// reside em widget"). Cursor, itens e decisões vivem em
/// [TriageSessionNotifier]; esta página só lê o estado e encaminha os
/// callbacks de gesto/botão para os métodos do notifier.
///
/// É `ConsumerStatefulWidget` só pelo `initState()`: é o hook que
/// dispara `resetSessionNavigation()` ao entrar na categoria (ver nota
/// no notifier) — não guarda nenhum estado de triagem em si.
class TriagePage extends ConsumerStatefulWidget {
  const TriagePage({required this.category, super.key});

  final CategorySummary category;

  @override
  ConsumerState<TriagePage> createState() => _TriagePageState();
}

class _TriagePageState extends ConsumerState<TriagePage> {
  @override
  void initState() {
    super.initState();
    // Uma vez por entrada na tela, não a cada rebuild — por isso mora
    // aqui e não no build().
    Future.microtask(
      () => ref
          .read(triageSessionProvider(widget.category.ref).notifier)
          .resetSessionNavigation(),
    );
  }

  /// Segundo ponto de entrada do painel (6.2.16) — o primeiro é o
  /// swipe para baixo, já cablado no TriageCard. Os dois convergem
  /// aqui: abrir o painel, e se algo foi escolhido (existente ou
  /// recém-criado), delegar pro mesmo `toggleAlbum` que a vinculação
  /// por toque já usa.
  Future<void> _openAlbumPanel(String? currentAlbumId) async {
    final selectedAlbumId = await showAlbumPanel(
      context,
      currentAlbumId: currentAlbumId,
    );
    if (selectedAlbumId == null || !mounted) return;
    ref
        .read(triageSessionProvider(widget.category.ref).notifier)
        .toggleAlbum(selectedAlbumId);
  }

  @override
  Widget build(BuildContext context) {
    final category = widget.category;
    final text = Theme.of(context).textTheme;
    final provider = triageSessionProvider(category.ref);
    final session = ref.watch(provider);
    final notifier = ref.read(provider.notifier);

    final lastUsedAlbumId = ref.watch(lastUsedAlbumProvider);
    final lastUsedAlbumLabel =
        lastUsedAlbumId == null ? null : MockAlbums.names[lastUsedAlbumId];

    // TODO §7 (Etapa 8): estado de conclusão real, com resumo das duas
    // métricas e ação de retorno ao dashboard. Por ora, só o botão que
    // evita o beco sem saída: reabrir a categoria para classificar em
    // álbum itens que ficaram mantidos sem álbum (3.2.2).
    if (session.isAtEnd) {
      return Scaffold(
        appBar: AppBar(title: Text(category.label)),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Fila concluída', style: text.titleMedium),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: notifier.restartFromBeginning,
                child: const Text('Rever itens'),
              ),
            ],
          ),
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
            child: Stack(
              children: [
                TriageCard(
                  // Key por item: sem ela o State do card sobrevive à
                  // troca e o próximo entra deslocado, onde o anterior
                  // saiu.
                  key: ValueKey(current.id),
                  item: current,
                  behind: nextItem != null ? MediaCard(item: nextItem) : null,
                  onSwipeLeft: notifier.markForDeletion,
                  onSwipeRight: notifier.keep,
                  onSwipeUp: notifier.classifyWithLastUsedAlbum,
                  onSwipeDown: () => _openAlbumPanel(current.albumId),
                  lastUsedAlbumLabel: lastUsedAlbumLabel,
                ),
                // Overlay topo-esquerdo (6.2.10). Desabilitado com a
                // pilha vazia — `onPressed: null` já cobre isso, sem
                // precisar de um estado visual separado.
                Positioned(
                  top: 8,
                  left: 8,
                  child: IconButton.filledTonal(
                    icon: const Icon(Icons.undo),
                    tooltip: 'Desfazer',
                    onPressed: session.canUndo ? notifier.undo : null,
                  ),
                ),
                // Pílula de último álbum (6.2.18) — affordance sempre
                // visível, distinta do feedback de arrasto (que só
                // aparece dentro do TriageCard durante o gesto).
                if (lastUsedAlbumLabel != null)
                  Positioned(
                    top: 8,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.arrow_upward,
                                size: 14,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                lastUsedAlbumLabel,
                                style: text.labelSmall
                                    ?.copyWith(color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Alça no rodapé (6.2.16) — segundo ponto de entrada do
          // painel, equivalente ao swipe para baixo.
          GestureDetector(
            onTap: () => _openAlbumPanel(current.albumId),
            behavior: HitTestBehavior.opaque,
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 6),
              child: Center(
                child: SizedBox(
                  width: 32,
                  height: 4,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.all(Radius.circular(2)),
                    ),
                  ),
                ),
              ),
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