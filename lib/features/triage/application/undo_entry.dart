import 'package:gallery_triage_app/core/domain/enums/triage_decision.dart';

/// Uma entrada da pilha de desfazer (6.2.15).
///
/// `anchorPosition` é a posição para a qual o cursor deve voltar ao
/// desfazer — não é necessariamente a posição do item, e não é sempre
/// "a posição anterior" no sentido aritmético. Duas regras (6.2.15):
///
/// - Ação sobre item alcançado por avanço sequencial: âncora = posição
///   imediatamente anterior no percurso.
/// - Primeira ação após um salto pelo carrossel: âncora = posição de
///   origem do salto.
/// - Ação que não avança o cursor (desclassificar, 3.2.4): âncora = a
///   própria posição atual, já que não há posição anterior a restaurar.
class UndoEntry {
  const UndoEntry({
    required this.itemId,
    required this.previousDecision,
    required this.previousAlbumId,
    required this.anchorPosition,
  });

  final String itemId;
  final TriageDecision previousDecision;
  final String? previousAlbumId;
  final int anchorPosition;
}
