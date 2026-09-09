
final triageSessionProvider = NotifierProvider.family<TriageSessionNotifier,
    TriageSessionState, CategoryRef>(TriageSessionNotifier.new);

/// Estado de triagem em memória, escopado por categoria (3.5.1 — a fila
/// é sempre relativa à categoria ativa). Opera sobre o dataset mockado
/// hoje; a interface pública (métodos de transição + getters de
/// progresso, em [TriageSessionState]) é o contrato que o
/// `TriageRepository` real (2.4.2) deve preencher depois — a Tela de
/// Triagem não muda na troca.
///
/// Fora de escopo aqui, entram em etapas seguintes: pilha de desfazer
/// (6.2.14/6.2.15 — Etapa 5) e diálogo de saída com fila pendente
/// (3.5.3 — Etapa 8).
class TriageSessionNotifier extends Notifier<TriageSessionState> {
  TriageSessionNotifier(this._categoryRef);

  // Riverpod 3.0 fundiu FamilyNotifier em Notifier: o argumento da
  // family chega pelo construtor, não mais por parâmetro de build().
  final CategoryRef _categoryRef;

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

  /// Não altera decisão nem classificação (3.2.6).
  void skip() => _advance();

  /// Painel de álbuns (6.2.16): toque em álbum diferente vincula e
  /// avança; toque no álbum atual desvincula e não avança (3.2.4). Um
  /// único método cobre as duas regras porque a UI não distingue os
  /// casos — só sabe qual álbum foi tocado.
  void toggleAlbum(String albumId) {
    final current = state.currentItem;
    if (current == null) return;

    if (current.albumId == albumId) {
      _replaceCurrent(current.unassignAlbum());
      return;
    }
    _replaceCurrent(current.assignToAlbum(albumId, DateTime.now()));
    _advance();
  }

  /// Toque no carrossel (6.2.6). Não passa por transição de domínio —
  /// só reposiciona o cursor.
  void jumpTo(int index) {
    if (index < 0 || index >= state.items.length) return;
    state = state.copyWith(currentIndex: index);
  }

  void _applyToCurrentAndAdvance(
    MediaItemEntity Function(MediaItemEntity item, DateTime at) transition,
  ) {
    final current = state.currentItem;
    if (current == null) return;
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
