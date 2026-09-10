import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gallery_triage_app/core/application/providers/last_used_album_provider.dart';
import 'package:gallery_triage_app/core/domain/enums/deletion_mode.dart';
import 'package:gallery_triage_app/core/domain/models/category_summary.dart';
import 'package:gallery_triage_app/core/presentation/widgets/progress_bar.dart';
import 'package:gallery_triage_app/features/dashboard/infrastructure/data/mock_media_items.dart';
import 'package:gallery_triage_app/features/triage/application/deletion_summary.dart';
import 'package:gallery_triage_app/features/triage/application/triage_session_notifier.dart';
import 'package:gallery_triage_app/features/triage/presentation/page/triage_review_page.dart';
import 'package:gallery_triage_app/features/triage/presentation/widgets/album_panel.dart';
import 'package:gallery_triage_app/features/triage/presentation/widgets/media_card.dart';
import 'package:gallery_triage_app/features/triage/presentation/widgets/media_info_modal.dart';
import 'package:gallery_triage_app/features/triage/presentation/widgets/triage_action_bar.dart';
import 'package:gallery_triage_app/features/triage/presentation/widgets/triage_card.dart';
import 'package:gallery_triage_app/features/triage/presentation/widgets/triage_carousel.dart';

/// 4.4.5 — texto condicionado ao modo: lixeira menciona a retenção,
/// definitivo informa o espaço liberado. Nunca anuncia espaço liberado
/// que não aconteceu (modo lixeira não libera nada de fato ainda).
String _deletionSummaryText(DeletionSummary summary) {
  final mb = (summary.freedBytes / (1024 * 1024)).toStringAsFixed(0);
  return summary.mode == DeletionMode.trash
      ? '${summary.count} itens movidos para a lixeira do sistema '
          '(retidos por cerca de 30 dias).'
      : '${summary.count} itens excluídos — $mb MB liberados.';
}

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

enum _ExitAction { cancel, discard, deleteNow }

class _TriagePageState extends ConsumerState<TriagePage> {
  /// Guarda contra reabrir a Revisão a cada rebuild enquanto a fila
  /// segue esgotada. Reseta quando `isAtEnd` deixa de ser verdade (ex.:
  /// "Rever itens"), pra disparar de novo na próxima vez que a fila
  /// esgotar de verdade.
  bool _autoOpenedReview = false;

  /// 6.2.17 — estado local de UI, não de domínio: play/pause é
  /// simulado (sem `photo_manager` não há vídeo real pra decodificar).
  /// `_playingItemId` existe só pra saber quando resetar `_isPlaying`
  /// ao trocar de item ("ao avançar, a reprodução é interrompida").
  bool _isPlaying = false;
  String? _playingItemId;

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

  /// Único caminho pra abrir a Revisão — usado pelo ícone da AppBar
  /// (6.2.1) e pelo gatilho automático de fim de fila (3.5.2: a fila
  /// deve ser resolvida dentro da sessão, então chegar ao fim com
  /// itens pendentes não é "concluído").
  Future<void> _openReviewPage(CategorySummary category) async {
    final message = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => TriageReviewPage(
          categoryRef: category.ref,
          categoryLabel: category.label,
        ),
      ),
    );
    if (message != null && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }

  /// 3.5.3 — diálogo bloqueante ao tentar sair (AppBar ou botão de
  /// voltar do sistema, os dois passam por aqui via PopScope) com
  /// itens marcados. Três opções, sem meio-termo silencioso.
  Future<void> _handlePendingQueueOnExit() async {
    final categoryRef = widget.category.ref;

    final action = await showDialog<_ExitAction>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Fila de exclusão pendente'),
        content: const Text(
          'Você tem itens marcados para exclusão nesta categoria. '
          'A fila não é salva entre sessões — o que fazer com eles?',
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(_ExitAction.cancel),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(_ExitAction.discard),
            child: const Text('Descartar marcações'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(_ExitAction.deleteNow),
            child: const Text('Excluir agora'),
          ),
        ],
      ),
    );

    if (!mounted || action == null || action == _ExitAction.cancel) return;

    if (action == _ExitAction.discard) {
      // 3.5.3 — restaura cada item a partir de preQueueDecision e
      // preQueueAlbumId (mesmo mecanismo de unmarkAllInQueue, 6.3.3).
      final queuedIds = ref
          .read(triageSessionProvider(categoryRef))
          .items
          .where((i) => i.isInDeletionQueue)
          .map((i) => i.id)
          .toList();
      ref
          .read(triageSessionProvider(categoryRef).notifier)
          .unmarkAllInQueue(queuedIds);
      if (mounted) Navigator.of(context).pop();
      return;
    }

    // _ExitAction.deleteNow — mesmo diálogo de confirmação da Revisão
    // (6.3.5), não uma exclusão silenciosa sem escolher o modo.
    await _openReviewPage(widget.category);
    if (!mounted) return;
    final stillPending =
        ref.read(triageSessionProvider(categoryRef)).queueCount > 0;
    // Só sai se a Revisão realmente esvaziou a fila — se o usuário
    // cancelou ou deixou itens pra trás lá, continua nesta tela.
    if (!stillPending) Navigator.of(context).pop();
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

    if (!session.isAtEnd) {
      _autoOpenedReview = false;
    }

    // TODO §7 (Etapa 8): estado de conclusão real, com resumo das duas
    // métricas e ação de retorno ao dashboard.
    if (session.isAtEnd) {
      if (session.queueCount > 0 && !_autoOpenedReview) {
        // 3.5.2 — não dá pra considerar a categoria concluída com
        // marcações pendentes. Agendado pro próximo frame porque não
        // se navega durante o build.
        _autoOpenedReview = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _openReviewPage(category);
        });
      }

      return PopScope(
        canPop: session.queueCount == 0,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          _handlePendingQueueOnExit();
        },
        child: Scaffold(
          appBar: AppBar(title: Text(category.label)),
          body: session.queueCount > 0
              // Estado transitório — o postFrameCallback acima já vai
              // empilhar a Revisão no próximo frame. Chega a renderizar
              // por um instante, então não pode ficar em branco.
              ? Center(
                  child: Text(
                    'Abrindo revisão da fila…',
                    style: text.titleMedium,
                  ),
                )
              // §7 — "estado de conclusão com resumo das duas métricas
              // e ação de retorno". Só chega aqui com queueCount == 0
              // (senão caía no ramo acima), então nunca sobra fila
              // pendente por trás deste resumo.
              : Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          size: 56,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: 16),
                        Text('Fila concluída', style: text.headlineSmall),
                        if (session.lastDeletionSummary != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            _deletionSummaryText(session.lastDeletionSummary!),
                            style: text.bodyMedium?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                        const SizedBox(height: 24),
                        ProgressBar(
                          showLegend: true,
                          totalItems: session.totalCount,
                          classifiedItems: session.classifiedCount,
                          keptItems: session.keptCount,
                        ),
                        const SizedBox(height: 32),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: notifier.restartFromBeginning,
                                child: const Text('Rever itens'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: FilledButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(),
                                child: const Text('Voltar ao Dashboard'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      );
    }

    final current = session.currentItem!;
    final nextItem =
        session.hasNext ? session.items[session.currentIndex + 1] : null;

    // 6.2.17 — "ao avançar, a reprodução é interrompida". Cobre swipe,
    // botões e salto pelo carrossel, já que todos mudam `current.id`.
    if (current.id != _playingItemId) {
      _isPlaying = false;
      _playingItemId = current.id;
    }

    return PopScope(
      canPop: session.queueCount == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handlePendingQueueOnExit();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            children: [
              Text(category.label),
              // `session.totalCount` em vez de `category.totalItems`:
              // os dois vêm do mesmo `MockMediaItems.forCategory`, mas
              // usar o da sessão evita depender de dois caminhos de
              // agregação ficarem sincronizados manualmente.
              Text(
                'Item ${session.currentIndex + 1} de ${session.totalCount}',
                style: text.bodySmall,
              ),
            ],
          ),
          actions: [
            // 6.2.1 — badge com a contagem da fila na categoria ativa.
            // Oculto com a fila vazia (7 — "Tela de Revisão
            // inacessível").
            if (session.queueCount > 0)
              IconButton(
                tooltip: 'Revisar fila de exclusão',
                icon: Badge(
                  label: Text('${session.queueCount}'),
                  child: const Icon(Icons.delete_outline),
                ),
                onPressed: () => _openReviewPage(category),
              ),
          ],
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
                    // troca e o próximo entra deslocado, onde o
                    // anterior saiu.
                    key: ValueKey(current.id),
                    item: current,
                    behind:
                        nextItem != null ? MediaCard(item: nextItem) : null,
                    onSwipeLeft: notifier.markForDeletion,
                    onSwipeRight: notifier.keep,
                    onSwipeUp: notifier.classifyWithLastUsedAlbum,
                    onSwipeDown: () => _openAlbumPanel(current.albumId),
                    lastUsedAlbumLabel: lastUsedAlbumLabel,
                    isPlaying: _isPlaying,
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
                  // Overlay topo-direito (6.2.11).
                  Positioned(
                    top: 8,
                    right: 8,
                    child: IconButton.filledTonal(
                      icon: const Icon(Icons.info_outline),
                      tooltip: 'Informações',
                      onPressed: () => showMediaInfoModal(context, current),
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
              isVideo: current.isVideo,
              isPlaying: _isPlaying,
              onTogglePlay: () => setState(() => _isPlaying = !_isPlaying),
            ),
          ],
        ),
      ),
    );
  }
}