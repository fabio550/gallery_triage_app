import 'dart:ui' show Color;

import '../../domain/entities/media_item_entity.dart';
import '../../domain/enums/triage_decision.dart';
import 'triage_colors.dart';

enum TriageVisualState {
  markedForDeletion,
  classified,
  kept,
  undecided;

  static TriageVisualState of(MediaItemEntity item) {
    if (item.isInDeletionQueue) return TriageVisualState.markedForDeletion;
    if (item.isClassified) return TriageVisualState.classified;
    if (item.decision == TriageDecision.kept) return TriageVisualState.kept;
    return TriageVisualState.undecided;
  }

  Color colorIn(TriageColors colors) => switch (this) {
        TriageVisualState.markedForDeletion => colors.stateMarkedForDeletion,
        TriageVisualState.classified => colors.stateClassified,
        TriageVisualState.kept => colors.stateKept,
        TriageVisualState.undecided => colors.stateUndecided,
      };
}