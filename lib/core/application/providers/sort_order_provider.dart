import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gallery_triage_app/core/application/providers/preferences_repository_provider.dart';
import 'package:gallery_triage_app/core/domain/enums/sort_order.dart';

final sortOrderProvider = NotifierProvider<SortOrderNotifier, SortOrder>(
  SortOrderNotifier.new,
);

/// 6.2.3 — ordenação cronológica da Tela de Triagem. Global, atravessa
/// categorias e sessões (2.6.1) — por isso mora num provider à parte,
/// não dentro de `TriageSessionNotifier` (escopado por categoria).
/// Persistida via `PreferencesRepository`; mesmo padrão write-through
/// do `DeletionModeNotifier`.
class SortOrderNotifier extends Notifier<SortOrder> {
  late final _repository = ref.read(preferencesRepositoryProvider);

  @override
  SortOrder build() {
    _load();
    // Padrão antes da preferência persistida carregar: mais recente
    // primeiro (6.2.3).
    return SortOrder.newestFirst;
  }

  Future<void> _load() async {
    final saved = await _repository.sortOrder();
    if (ref.mounted) state = saved;
  }

  /// Ícone na AppBar da Triagem (6.2.3) alterna entre as duas opções.
  void toggle() {
    final next = state == SortOrder.newestFirst
        ? SortOrder.oldestFirst
        : SortOrder.newestFirst;
    state = next;
    unawaited(
      _repository.setSortOrder(next).catchError((Object e, StackTrace st) {
        debugPrint('PreferencesRepository.setSortOrder falhou: $e');
      }),
    );
  }
}
