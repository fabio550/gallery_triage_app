import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gallery_triage_app/core/domain/entities/media_item_entity.dart';
import 'package:gallery_triage_app/core/domain/enums/triage_decision.dart';
import 'package:gallery_triage_app/core/domain/models/category_summary.dart';
import 'package:gallery_triage_app/core/infrastructure/mock/mock_media_items.dart';
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
/// Etapa 8) e a limpeza da pilha ao "sair da categoria" (6.2.14) — não
/// há hook de ciclo de vida limpo para isso enquanto a navegação não
/// tiver um dono explícito; `clearUndoStack()` existe pronta para
/// quando esse ponto for definido.
class TriageSessionNotifier extends Notifier<TriageSessionState> {
  TriageSessionNotifier(this._categoryRef);

  // Riverpod 3.0 fundiu FamilyNotifier em Notifier: o argumento da
  // family chega pelo construtor, não mais por parâmetro de build().
  final CategoryRef _categoryRef;

  static const _maxUndoEntries = 40;

  /// Posição do cursor imediatamente antes do último movimento (avanço
  /// ou salto). É o que 6.2.15 chama de âncora: não é aritmético
  /// (`currentIndex - 1`), é literalmente de onde o cursor veio — o que
  /// distingue avanço sequencial de salto pelo carrossel.
  int? _previousIndex;

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
    _pushUndo(current, anchor: _previousIndex ?? state.currentIndex);
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
      // 3.2.4: não avança. A âncora de desfazer é a própria posição
      // atual — não existe "posição anterior" para essa ação, porque
      // o cursor nunca saiu daqui.
      _pushUndo(current, anchor: state.currentIndex);
      _replaceCurrent(current.unassignAlbum());
      return;
    }

    _pushUndo(current, anchor: _previousIndex ?? state.currentIndex);
    _replaceCurrent(current.assignToAlbum(albumId, DateTime.now()));
    _advance();
  }

  /// Toque no carrossel (6.2.6). Não passa por transição de domínio e
  /// não entra na pilha (6.2.14) — mas ainda atualiza `_previousIndex`,
  /// porque é isso que torna a próxima ação "primeira ação após um
  /// salto" (6.2.15).
  void jumpTo(int index) {
    if (index < 0 || index >= state.items.length) return;
    _moveCursorTo(index);
  }

  /// Ação explícita da tela de fim de fila (§7) para reabrir uma
  /// categoria já percorrida. Só reposiciona o cursor — as decisões já
  /// tomadas continuam intactas; existe porque "mantido" não implica
  /// "classificado" (3.2.2) e o usuário pode querer voltar só para
  /// classificar em álbum itens que já estão mantidos.
  void restartFromBeginning() {
    if (state.items.isEmpty) return;
    _moveCursorTo(0);
  }

  // --- Desfazer (6.2.14 / 6.2.15) -------------------------------------

  /// Reverte a última ação. Restaura decisão e álbum aos valores
  /// anteriores e move o cursor para a âncora gravada na entrada — não
  /// necessariamente um passo atrás (ver [UndoEntry]).
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

    state = state.copyWith(items: items, undoStack: remaining);
    _moveCursorTo(entry.anchorPosition);
  }

  /// 6.2.14 — "a pilha é zerada ao sair da categoria". Ainda sem
  /// chamador: falta o ponto de navegação que marca "saiu da
  /// categoria" (Etapa 8, junto do diálogo de 3.5.3).
  void clearUndoStack() {
    state = state.copyWith(undoStack: const []);
  }

  void _pushUndo(MediaItemEntity beforeAction, {required int anchor}) {
    final entry = UndoEntry(
      itemId: beforeAction.id,
      previousDecision: beforeAction.decision,
      previousAlbumId: beforeAction.albumId,
      anchorPosition: anchor,
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
    _pushUndo(current, anchor: _previousIndex ?? state.currentIndex);
    _replaceCurrent(transition(current, DateTime.now()));
    _advance();
  }

  void _replaceCurrent(MediaItemEntity updated) {
    final items = [...state.items];
    items[state.currentIndex] = updated;
    state = state.copyWith(items: items);
  }

  void _advance() {
    _moveCursorTo(state.hasNext ? state.currentIndex + 1 : state.items.length);
  }

  void _moveCursorTo(int index) {
    _previousIndex = state.currentIndex;
    state = state.copyWith(currentIndex: index);
  }
}
