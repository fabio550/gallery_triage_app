import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gallery_triage_app/core/domain/entities/media_item_entity.dart';
import 'package:gallery_triage_app/core/domain/enums/triage_decision.dart';
import 'package:gallery_triage_app/core/domain/models/category_summary.dart';
import 'package:gallery_triage_app/features/dashboard/infrastructure/data/mock_media_items.dart';
import 'package:gallery_triage_app/features/triage/application/triage_session_state.dart';
import 'package:gallery_triage_app/features/triage/application/undo_entry.dart';

final triageSessionProvider = NotifierProvider.family<TriageSessionNotifier,
    TriageSessionState, CategoryRef>(TriageSessionNotifier.new);

/// Estado de triagem em memória, escopado por categoria (3.5.1 — a fila
/// é sempre relativa à categoria ativa). Opera sobre o dataset mockado
/// hoje; a interface pública (métodos de transição + getters de
/// progresso, em [TriageSessionState]) é o contrato que o
/// `TriageRepository` real (2.4.2) deve preencher depois — a Tela de
/// Triagem não muda na troca.
///
/// Fora de escopo aqui: diálogo de saída com fila pendente (3.5.3 —
/// Etapa 8).
class TriageSessionNotifier extends Notifier<TriageSessionState> {
  TriageSessionNotifier(this._categoryRef);

  // Riverpod 3.0 fundiu FamilyNotifier em Notifier: o argumento da
  // family chega pelo construtor, não mais por parâmetro de build().
  final CategoryRef _categoryRef;

  static const _maxUndoEntries = 40;

  @override
  TriageSessionState build() {
    final items = MockMediaItems.forCategory(_categoryRef);
    return TriageSessionState(
      items: items,
      currentIndex: _resolveInitialIndex(items),
    );
  }

  /// 6.2.4, parcial: primeiro item não decidido; sem nenhum, primeiro
  /// item. A parte "última posição da sessão anterior" depende de
  /// persistência (Drift) e fica para quando o índice real existir —
  /// não há onde gravar isso ainda.
  static int _resolveInitialIndex(List<MediaItemEntity> items) {
    if (items.isEmpty) return 0;
    final firstUndecided =
        items.indexWhere((i) => i.decision == TriageDecision.undecided);
    return firstUndecided == -1 ? 0 : firstUndecided;
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
      // 3.2.4: não avança.
      _pushUndo(current);
      _replaceCurrent(current.unassignAlbum());
      return;
    }

    _pushUndo(current);
    _replaceCurrent(current.assignToAlbum(albumId, DateTime.now()));
    _advance();
  }

  /// Toque no carrossel (6.2.6). Não passa por transição de domínio e
  /// não entra na pilha (6.2.14).
  void jumpTo(int index) {
    if (index < 0 || index >= state.items.length) return;
    state = state.copyWith(currentIndex: index);
  }

  /// Ação explícita da tela de fim de fila (§7) para reabrir uma
  /// categoria já percorrida. Só reposiciona o cursor — as decisões já
  /// tomadas continuam intactas; existe porque "mantido" não implica
  /// "classificado" (3.2.2) e o usuário pode querer voltar só para
  /// classificar em álbum itens que já estão mantidos.
  void restartFromBeginning() {
    if (state.items.isEmpty) return;
    state = state.copyWith(currentIndex: 0);
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
    _replaceCurrent(transition(current, DateTime.now()));
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
  }
}
