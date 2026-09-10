import 'package:gallery_triage_app/core/domain/entities/media_item_entity.dart';
import 'package:gallery_triage_app/core/domain/enums/triage_decision.dart';
import 'package:gallery_triage_app/features/triage/application/deletion_summary.dart';
import 'package:gallery_triage_app/features/triage/application/undo_entry.dart';

/// Estado de uma sessão de triagem: os itens da categoria ativa e o
/// cursor. Não é o [MediaItemEntity] cru — é o recorte que a Tela de
/// Triagem está navegando.
class TriageSessionState {
  const TriageSessionState({
    required this.items,
    required this.currentIndex,
    this.undoStack = const [],
    this.lastDeletionSummary,
    this.isLoading = false,
  });

  final List<MediaItemEntity> items;

  /// `build()` do notifier não pode ser `async`, mas a consulta ao
  /// Drift é. Sem isto, `isAtEnd` (items.isEmpty) confundiria
  /// "carregando" com "categoria vazia" no instante entre abrir a
  /// tela e o banco responder.
  final bool isLoading;

  /// Pode chegar a `items.length` — é o estado de fim da fila (§7), não
  /// um índice inválido a ser evitado.
  final int currentIndex;

  /// 6.2.14 — limitada a 40 entradas pelo notifier. Exposta aqui para a
  /// UI decidir se o botão de desfazer (6.2.10) fica habilitado.
  final List<UndoEntry> undoStack;

  /// 6.4.1 — resumo da última exclusão confirmada nesta sessão, para a
  /// tela de fim de fila (§7) exibir de forma permanente, não só como
  /// SnackBar transitório.
  final DeletionSummary? lastDeletionSummary;

  MediaItemEntity? get currentItem =>
      currentIndex >= 0 && currentIndex < items.length
          ? items[currentIndex]
          : null;

  bool get hasNext => currentIndex < items.length - 1;

  /// §7 — cursor passou do último item. Categoria nunca é marcada como
  /// concluída automaticamente (3.2.7); isto é só progresso informativo
  /// para a UI decidir mostrar o estado de conclusão.
  bool get isAtEnd => items.isEmpty || currentIndex >= items.length;

  bool get canUndo => undoStack.isNotEmpty;

  /// 6.1.10 — itens retidos ou indisponíveis não entram em nenhum
  /// contador. Sem filtro aqui, a barra de progresso ficaria errada
  /// assim que algo fosse excluído (moveToSystemTrash).
  int get keptCount => items
      .where((i) => i.isCountable && i.decision == TriageDecision.kept)
      .length;

  /// Mesma restrição de mock_categories.dart: um item classificado que
  /// caiu na fila (3.2.5) não conta como classificado no agregado —
  /// 6.1.2 manda esse item para o trilho vazio.
  int get classifiedCount => items
      .where((i) =>
          i.isCountable &&
          i.decision == TriageDecision.kept &&
          i.albumId != null)
      .length;

  int get queueCount =>
      items.where((i) => i.isCountable && i.isInDeletionQueue).length;

  int get totalCount => items.where((i) => i.isCountable).length;

  TriageSessionState copyWith({
    List<MediaItemEntity>? items,
    int? currentIndex,
    List<UndoEntry>? undoStack,
    DeletionSummary? lastDeletionSummary,
    bool? isLoading,
  }) {
    return TriageSessionState(
      items: items ?? this.items,
      currentIndex: currentIndex ?? this.currentIndex,
      undoStack: undoStack ?? this.undoStack,
      lastDeletionSummary: lastDeletionSummary ?? this.lastDeletionSummary,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}