import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gallery_triage_app/core/application/providers/last_used_album_provider.dart';
import 'package:gallery_triage_app/core/application/providers/media_repository_provider.dart';
import 'package:gallery_triage_app/core/application/providers/preferences_repository_provider.dart';
import 'package:gallery_triage_app/core/application/providers/sort_order_provider.dart';
import 'package:gallery_triage_app/core/application/providers/triage_repository_provider.dart';
import 'package:gallery_triage_app/core/domain/entities/media_item_entity.dart';
import 'package:gallery_triage_app/core/domain/enums/deletion_mode.dart';
import 'package:gallery_triage_app/core/domain/enums/sort_order.dart';
import 'package:gallery_triage_app/core/domain/enums/triage_decision.dart';
import 'package:gallery_triage_app/core/domain/models/category_summary.dart';
import 'package:gallery_triage_app/core/domain/repositories/media_repository.dart';
import 'package:gallery_triage_app/core/domain/repositories/preferences_repository.dart';
import 'package:gallery_triage_app/core/domain/repositories/triage_repository.dart';
import 'package:gallery_triage_app/features/triage/application/deletion_outcome.dart';
import 'package:gallery_triage_app/features/triage/application/deletion_summary.dart';
import 'package:gallery_triage_app/features/triage/application/triage_session_state.dart';
import 'package:gallery_triage_app/features/triage/application/undo_entry.dart';

final triageSessionProvider = NotifierProvider.family<TriageSessionNotifier,
    TriageSessionState, CategoryRef>(TriageSessionNotifier.new);

/// Estado de triagem em memória, escopado por categoria (3.5.1 — a fila
/// é sempre relativa à categoria ativa). Lista local + `copyWith` como
/// antes; cada transição também persiste no [TriageRepository]
/// (write-through) via [_persist]/`deleteItems`. A interface pública
/// (métodos de transição + getters de progresso, em
/// [TriageSessionState]) não mudou na troca do dataset mockado pelo
/// Drift.
class TriageSessionNotifier extends Notifier<TriageSessionState> {
  TriageSessionNotifier(this._categoryRef);

  // Riverpod 3.0 fundiu FamilyNotifier em Notifier: o argumento da
  // family chega pelo construtor, não mais por parâmetro de build().
  final CategoryRef _categoryRef;

  static const _maxUndoEntries = 40;

  late final TriageRepository _repository;
  late final MediaRepository _mediaRepository;
  late final PreferencesRepository _preferencesRepository;

  @override
  TriageSessionState build() {
    _repository = ref.read(triageRepositoryProvider);
    _mediaRepository = ref.read(mediaRepositoryProvider);
    _preferencesRepository = ref.read(preferencesRepositoryProvider);

    // 6.2.3 — reordena ao vivo quando a preferência global muda (ícone
    // na AppBar da Triagem), sem precisar sair e voltar pra categoria.
    ref.listen(sortOrderProvider, (previous, next) {
      if (previous != null && previous != next) _applySortOrder(next);
    });

    _load();
    return const TriageSessionState(
      items: [],
      currentIndex: 0,
      isLoading: true,
    );
  }

  /// `build()` não pode ser `async` (2.6, handoff) — carrega em
  /// background e substitui o estado quando a consulta ao Drift
  /// responder. Índice já vem populado pelo `SyncService` (5.2/5.3)
  /// antes de qualquer categoria ser aberta — sem seed mockado.
  Future<void> _load() async {
    final sortOrder = ref.read(sortOrderProvider);
    final items = await _repository.itemsForCategory(
      _categoryRef,
      sortOrder: sortOrder,
    );
    if (!ref.mounted) return;

    final initialIndex = await _resolveInitialIndex(items, sortOrder);
    if (!ref.mounted) return;

    state = state.copyWith(
      items: items,
      currentIndex: initialIndex,
      isLoading: false,
    );
  }

  /// Write-through (handoff): cada transição grava local primeiro
  /// (responsividade da UI) e persiste em paralelo, sem bloquear o
  /// cursor/pilha de desfazer na espera do banco.
  void _persist(MediaItemEntity item) {
    unawaited(
      _repository.updateItem(item).catchError((Object e, StackTrace st) {
        debugPrint('TriageRepository.updateItem falhou para ${item.id}: $e');
      }),
    );
  }

  /// 6.2.4 — última posição da sessão anterior naquela categoria,
  /// persistida por ID do item. Se o item não existir mais nesta lista,
  /// ou não houver posição salva: primeiro item não decidido; sem
  /// nenhum, primeiro item.
  ///
  /// Exceção: se fotos mais recentes que a posição salva já estão na
  /// lista (chegaram por sincronização depois da última visita), o
  /// cursor não retoma de onde parou — aponta pra mais nova, senão elas
  /// ficariam escondidas atrás da posição antiga.
  Future<int> _resolveInitialIndex(
    List<MediaItemEntity> items,
    SortOrder sortOrder,
  ) async {
    if (items.isEmpty) return 0;

    final newestIndex = sortOrder == SortOrder.newestFirst
        ? 0
        : items.length - 1;

    final savedId = await _preferencesRepository.cursorPosition(_categoryRef);
    if (savedId != null) {
      final savedIndex = items.indexWhere((i) => i.id == savedId);
      if (savedIndex != -1) {
        final newest = items[newestIndex];
        final saved = items[savedIndex];
        if (newest.dateTaken.isAfter(saved.dateTaken)) return newestIndex;
        return savedIndex;
      }
    }

    final firstUndecided =
        items.indexWhere((i) => i.decision == TriageDecision.undecided);
    return firstUndecided == -1 ? 0 : firstUndecided;
  }

  /// 6.2.4 — grava a posição atual pra sobreviver ao fechamento da
  /// categoria/app. Sem item atual (fila esgotada, §7), nada a gravar —
  /// a última posição válida continua servindo de referência.
  void _persistCursor() {
    final item = state.currentItem;
    if (item == null) return;
    unawaited(
      _preferencesRepository
          .setCursorPosition(_categoryRef, item.id)
          .catchError((Object e, StackTrace st) {
        debugPrint('PreferencesRepository.setCursorPosition falhou: $e');
      }),
    );
  }

  /// 6.2.3 — reordena a sessão já carregada quando a preferência global
  /// muda, sem recarregar do Drift. Mantém a mesma posição numérica
  /// (item 3 de 175 continua item 3 de 175), não o mesmo item — inverter
  /// a ordem move o item atual pra ponta oposta da lista (item 3 vira
  /// item 173 numa lista de 175), o que lia como um salto estranho pro
  /// meio da lista em vez de "virou a ordem".
  void _applySortOrder(SortOrder order) {
    final items = [...state.items]
      ..sort(
        order == SortOrder.newestFirst
            ? (a, b) => b.dateTaken.compareTo(a.dateTaken)
            : (a, b) => a.dateTaken.compareTo(b.dateTaken),
      );

    state = state.copyWith(items: items);
    // O item nesta posição mudou — persiste o novo pra não reabrir a
    // categoria depois apontando pro item antigo (6.2.4).
    _persistCursor();
  }

  // --- Decisões (3.4) ------------------------------------------------

  /// Swipe direita / Manter.
  void keep() => _applyToCurrentAndAdvance((item, at) => item.keep(at));

  /// Swipe esquerda / Excluir.
  void markForDeletion() =>
      _applyToCurrentAndAdvance((item, at) => item.markForDeletion(at));

  /// Não altera decisão nem classificação, mas ainda é reversível
  /// (6.2.14 lista "pular" entre as ações que o desfazer cobre) — só
  /// que desfazê-lo apenas recua o cursor, sem restaurar nada, porque
  /// o snapshot da entrada é idêntico ao estado atual.
  void skip() {
    final current = state.currentItem;
    if (current == null) return;
    _pushUndo(current);
    _advance();
  }

  /// Painel de álbuns (6.2.16): toque em álbum diferente vincula e
  /// avança; toque no álbum atual desvincula e não avança (3.2.4). Um
  /// único método cobre as duas regras porque a UI não distingue os
  /// casos — só sabe qual álbum foi tocado.
  void toggleAlbum(String albumId) {
    final current = state.currentItem;
    if (current == null) return;

    if (current.albumId == albumId) {
      // 3.2.4: não avança, e esta ação NÃO grava lastUsedAlbumId
      // (6.2.16 — só a vinculação a um álbum diferente grava).
      _pushUndo(current);
      final updated = current.unassignAlbum();
      _replaceCurrent(updated);
      _persist(updated);
      return;
    }

    _pushUndo(current);
    final updated = current.assignToAlbum(albumId, DateTime.now());
    _replaceCurrent(updated);
    _persist(updated);
    _advance();
    ref.read(lastUsedAlbumProvider.notifier).set(albumId);
  }

  /// Swipe para cima (6.2.9/6.2.18): classifica direto no álbum de
  /// `lastUsedAlbumId`, sem abrir o painel. Inerte se não houver
  /// nenhum álbum armado ainda — a UI decide se deixa o gesto chegar
  /// aqui (a pílula não é renderizada com `lastUsedAlbumId` nulo), mas
  /// o notifier também é defensivo.
  void classifyWithLastUsedAlbum() {
    final albumId = ref.read(lastUsedAlbumProvider);
    if (albumId == null) return;

    final current = state.currentItem;
    if (current == null) return;

    _pushUndo(current);
    final updated = current.assignToAlbum(albumId, DateTime.now());
    _replaceCurrent(updated);
    _persist(updated);
    _advance();
  }

  /// Toque no carrossel (6.2.6). Não passa por transição de domínio e
  /// não entra na pilha (6.2.14).
  void jumpTo(int index) {
    if (index < 0 || index >= state.items.length) return;
    state = state.copyWith(currentIndex: index);
    _persistCursor();
  }

  /// Ação explícita da tela de fim de fila (§7) para reabrir uma
  /// categoria já percorrida. Só reposiciona o cursor — as decisões já
  /// tomadas continuam intactas; existe porque "mantido" não implica
  /// "classificado" (3.2.2) e o usuário pode querer voltar só para
  /// classificar em álbum itens que já estão mantidos.
  void restartFromBeginning() {
    if (state.items.isEmpty) return;
    state = state.copyWith(currentIndex: 0);
    _persistCursor();
  }

  // --- Desfazer (6.2.14 / 6.2.15, revisado) ---------------------------
  //
  // Regra única, mais simples que a redação original de 6.2.15: cada
  // entrada guarda a posição do PRÓPRIO item de origem — não uma
  // "posição anterior" nem a "origem de um salto". Desfazer sempre
  // devolve o cursor exatamente para onde a ação aconteceu, esperando
  // nova decisão do usuário ali. Não importa se o item foi alcançado
  // por avanço sequencial ou salto pelo carrossel: o resultado é o
  // mesmo. Isto substitui a distinção sequencial/salto do texto
  // original de 6.2.15 — atualizar o arquitetura.md.

  /// Reverte a última ação: restaura decisão e álbum, e move o cursor
  /// de volta para o item que acabou de ser revertido.
  void undo() {
    if (state.undoStack.isEmpty) return;

    final entry = state.undoStack.last;
    final remaining = state.undoStack.sublist(0, state.undoStack.length - 1);

    final index = state.items.indexWhere((i) => i.id == entry.itemId);
    if (index == -1) {
      // Item não existe mais nesta sessão. Só ocorre depois que uma
      // exclusão real (fora de escopo ainda) remover itens da lista —
      // não há o que restaurar, só descarta a entrada.
      state = state.copyWith(undoStack: remaining);
      return;
    }

    final restored = state.items[index].copyWith(
      decision: entry.previousDecision,
      albumId: entry.previousAlbumId,
    );
    final items = [...state.items];
    items[index] = restored;

    state = state.copyWith(
      items: items,
      currentIndex: entry.anchorPosition,
      undoStack: remaining,
    );
    _persist(restored);
    _persistCursor();
  }

  /// 6.2.14 — "a pilha é zerada ao sair da categoria". Chamado no
  /// `initState()` da Tela de Triagem, não numa saída: o notifier
  /// sobrevive entre visitas (sem autoDispose, de propósito, para não
  /// perder decisões), e hoje não existe um hook limpo de "saída" —
  /// zerar na entrada tem o mesmo efeito prático.
  void resetSessionNavigation() {
    if (state.undoStack.isNotEmpty) {
      state = state.copyWith(undoStack: const []);
    }
  }

  // --- Tela de Revisão da Lixeira (6.3) -------------------------------
  //
  // Nada aqui entra na pilha de desfazer — 6.2.14 é explícito:
  // "Desmarcar item na Tela de Revisão não entra na pilha da Triagem."
  // E nada disso move o cursor da Triagem: a Revisão é uma tela à
  // parte, olhando pro mesmo `state.items` por id.

  /// Alterna um item entre selecionado para remoção e restaurado
  /// (6.3.4). Restaurar usa `preQueueDecision`/`preQueueAlbumId` —
  /// mesmo mecanismo de 3.5.3/5.4.1, não uma restauração inventada
  /// aqui.
  void toggleQueueMembership(String itemId) {
    final index = state.items.indexWhere((i) => i.id == itemId);
    if (index == -1) return;

    final item = state.items[index];
    final updated = item.isInDeletionQueue
        ? item.restoreFromQueue()
        : item.markForDeletion(DateTime.now());

    final items = [...state.items];
    items[index] = updated;
    state = state.copyWith(items: items);
    _persist(updated);
  }

  /// "Marcar Todas" (6.3.3) — remarca só os itens do roster passado que
  /// foram individualmente restaurados. O roster vem de fora (a tela de
  /// Revisão captura um snapshot dos ids ao abrir, 6.3.1) porque a lista
  /// de itens `naLixeira` muda à medida que se alterna cada um, e a
  /// tela precisa continuar mostrando o mesmo conjunto.
  void markAllInQueue(List<String> itemIds) {
    final items = [...state.items];
    final changed = <MediaItemEntity>[];
    for (final id in itemIds) {
      final index = items.indexWhere((i) => i.id == id);
      if (index == -1 || items[index].isInDeletionQueue) continue;
      final updated = items[index].markForDeletion(DateTime.now());
      items[index] = updated;
      changed.add(updated);
    }
    state = state.copyWith(items: items);
    changed.forEach(_persist);
  }

  /// "Desmarcar Todas" (6.3.3).
  void unmarkAllInQueue(List<String> itemIds) {
    final items = [...state.items];
    final changed = <MediaItemEntity>[];
    for (final id in itemIds) {
      final index = items.indexWhere((i) => i.id == id);
      if (index == -1 || !items[index].isInDeletionQueue) continue;
      final updated = items[index].restoreFromQueue();
      items[index] = updated;
      changed.add(updated);
    }
    state = state.copyWith(items: items);
    changed.forEach(_persist);
  }

  /// Dispara o diálogo do sistema de verdade (4.3.1/4.3.2 — um único
  /// diálogo pro lote inteiro) via [MediaRepository], e só então atualiza
  /// índice e sessão com base na lista efetivamente processada, nunca
  /// na enviada (4.3.5 — regra crítica). `RESULT_CANCELED` (lista vazia
  /// de volta) não toca em nada (4.3.6). Aplicação parcial (§7) remove
  /// da sessão só os itens processados; os demais permanecem na fila.
  ///
  /// Modo lixeira marca `trashedInSystem` (3.6.1), preservando a linha;
  /// modo definitivo apaga a linha (irreversível, 4.4.4).
  Future<DeletionOutcome> confirmDeletion(
    List<String> itemIds,
    DeletionMode mode,
  ) async {
    final oldItems = state.items;
    final targets = oldItems.where((i) => itemIds.contains(i.id)).toList();
    if (targets.isEmpty) return DeletionOutcome.cancelled;

    final domainIdByMediaStoreId = {
      for (final t in targets) t.mediaStoreId: t.id,
    };
    final mediaStoreIds = targets.map((t) => t.mediaStoreId).toList();

    List<int> processedMediaStoreIds;
    try {
      processedMediaStoreIds = mode == DeletionMode.trash
          ? await _mediaRepository.moveToSystemTrash(mediaStoreIds)
          : await _mediaRepository.deletePermanently(mediaStoreIds);
    } catch (e, st) {
      debugPrint('MediaRepository exclusão/lixeira falhou: $e\n$st');
      return DeletionOutcome.cancelled;
    }

    // 4.3.6 — RESULT_CANCELED (ou tudo falhou ao mapear pro sistema,
    // 6.2.16-style defensivo): fila permanece intacta.
    if (processedMediaStoreIds.isEmpty) return DeletionOutcome.cancelled;

    final processedIds = processedMediaStoreIds
        .map((id) => domainIdByMediaStoreId[id])
        .whereType<String>()
        .toSet();

    final removed = oldItems.where((i) => processedIds.contains(i.id)).toList();
    final newItems =
        oldItems.where((i) => !processedIds.contains(i.id)).toList();

    final freedBytes = removed.fold<int>(0, (sum, i) => sum + i.sizeBytes);
    final summary = DeletionSummary(
      count: removed.length,
      mode: mode,
      freedBytes: freedBytes,
    );

    final currentId = state.currentIndex < oldItems.length
        ? oldItems[state.currentIndex].id
        : null;
    final preservedIndex = currentId == null
        ? -1
        : newItems.indexWhere((i) => i.id == currentId);

    final newIndex = preservedIndex != -1
        ? preservedIndex
        : (newItems.isEmpty
            ? 0
            : state.currentIndex.clamp(0, newItems.length));

    state = state.copyWith(
      items: newItems,
      currentIndex: newIndex,
      lastDeletionSummary: summary,
    );

    final processedList = processedIds.toList();
    if (mode == DeletionMode.trash) {
      unawaited(
        _repository
            .markTrashedInSystem(processedList, DateTime.now())
            .catchError((Object e, StackTrace st) {
          debugPrint('TriageRepository.markTrashedInSystem falhou: $e');
        }),
      );
    } else {
      unawaited(
        _repository.deleteItems(processedList).catchError(
          (Object e, StackTrace st) {
            debugPrint('TriageRepository.deleteItems falhou: $e');
          },
        ),
      );
    }

    return processedIds.length == itemIds.length
        ? DeletionOutcome.completed
        : DeletionOutcome.partial;
  }

  void _pushUndo(MediaItemEntity beforeAction) {
    final entry = UndoEntry(
      itemId: beforeAction.id,
      previousDecision: beforeAction.decision,
      previousAlbumId: beforeAction.albumId,
      anchorPosition: state.currentIndex,
    );
    var stack = [...state.undoStack, entry];
    if (stack.length > _maxUndoEntries) {
      stack = stack.sublist(stack.length - _maxUndoEntries);
    }
    state = state.copyWith(undoStack: stack);
  }

  void _applyToCurrentAndAdvance(
    MediaItemEntity Function(MediaItemEntity item, DateTime at) transition,
  ) {
    final current = state.currentItem;
    if (current == null) return;
    _pushUndo(current);
    final updated = transition(current, DateTime.now());
    _replaceCurrent(updated);
    _persist(updated);
    _advance();
  }

  void _replaceCurrent(MediaItemEntity updated) {
    final items = [...state.items];
    items[state.currentIndex] = updated;
    state = state.copyWith(items: items);
  }

  void _advance() {
    state = state.copyWith(
      currentIndex:
          state.hasNext ? state.currentIndex + 1 : state.items.length,
    );
    _persistCursor();
  }
}