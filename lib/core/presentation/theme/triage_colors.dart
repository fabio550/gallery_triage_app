import 'package:flutter/material.dart';

@immutable
class TriageColors extends ThemeExtension<TriageColors> {
  const TriageColors({
    required this.stateMarkedForDeletion,
    required this.stateClassified,
    required this.stateKept,
    required this.stateUndecided,
  });

  /// Prioridade 1 — item na fila de exclusão da categoria ativa.
  final Color stateMarkedForDeletion;

  /// Prioridade 2 — item vinculado a um álbum.
  final Color stateClassified;

  /// Prioridade 3 — item mantido sem álbum.
  final Color stateKept;

  /// Prioridade 4 — item ainda não alcançado ou pulado.
  final Color stateUndecided;

  static const dark = TriageColors(
    stateMarkedForDeletion: Color(0xFFF2554B),
    stateClassified: Color(0xFF2FBF87),
    stateKept: Color(0xFF4C8DFF),
    stateUndecided: Color(0xFF5A6270),
  );

  @override
  TriageColors copyWith({
    Color? stateMarkedForDeletion,
    Color? stateClassified,
    Color? stateKept,
    Color? stateUndecided,
  }) {
    return TriageColors(
      stateMarkedForDeletion:
          stateMarkedForDeletion ?? this.stateMarkedForDeletion,
      stateClassified: stateClassified ?? this.stateClassified,
      stateKept: stateKept ?? this.stateKept,
      stateUndecided: stateUndecided ?? this.stateUndecided,
    );
  }

  @override
  TriageColors lerp(covariant TriageColors? other, double t) {
    if (other == null) return this;
    return TriageColors(
      stateMarkedForDeletion: Color.lerp(
        stateMarkedForDeletion,
        other.stateMarkedForDeletion,
        t,
      )!,
      stateClassified: Color.lerp(stateClassified, other.stateClassified, t)!,
      stateKept: Color.lerp(stateKept, other.stateKept, t)!,
      stateUndecided: Color.lerp(stateUndecided, other.stateUndecided, t)!,
    );
  }
}

extension TriageColorsX on BuildContext {
  TriageColors get triageColors => Theme.of(this).extension<TriageColors>()!;
}