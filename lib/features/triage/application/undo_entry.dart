import 'package:gallery_triage_app/core/domain/enums/triage_decision.dart';

/// Uma entrada da pilha de desfazer.
///
/// `anchorPosition` é a posição do próprio item de origem da ação —
/// não uma "posição anterior". Ao desfazer, o cursor volta exatamente
/// para onde a ação aconteceu, independente de o item ter sido
/// alcançado por avanço sequencial ou salto pelo carrossel. (Revisão
/// de 6.2.15: o texto original distinguia os dois casos com âncoras
/// diferentes; simplificado para uma regra única após teste real
/// mostrar que voltar para uma posição anterior ao item revertido,
/// como o texto original pedia, não fazia sentido para quem está
/// desfazendo — a ação que motivou o desfazer foi a mais recente, e o
/// usuário espera vê-la, não pular por cima dela.)
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
