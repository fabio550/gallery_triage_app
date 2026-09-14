import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gallery_triage_app/core/application/providers/preferences_repository_provider.dart';
import 'package:gallery_triage_app/core/domain/enums/deletion_mode.dart';

final deletionModeProvider =
    NotifierProvider<DeletionModeNotifier, DeletionMode>(
  DeletionModeNotifier.new,
);

/// 4.4.2 — "a última escolha é memorizada como padrão e vem
/// pré-selecionada nas próximas operações". Persistida em
/// `PreferencesRepository` (2.6); write-through, mesmo padrão do
/// `TriageSessionNotifier` (`build()` não pode ser `async` — carrega em
/// background e substitui o estado quando o Drift responder).
class DeletionModeNotifier extends Notifier<DeletionMode> {
  late final _repository = ref.read(preferencesRepositoryProvider);

  @override
  DeletionMode build() {
    _load();
    // Padrão inicial antes da preferência persistida carregar: lixeira
    // do sistema — reversível, a opção mais segura (4.4.2/4.4.3).
    return DeletionMode.trash;
  }

  Future<void> _load() async {
    final saved = await _repository.deletionMode();
    if (ref.mounted) state = saved;
  }

  void set(DeletionMode mode) {
    state = mode;
    unawaited(
      _repository.setDeletionMode(mode).catchError((Object e, StackTrace st) {
        debugPrint('PreferencesRepository.setDeletionMode falhou: $e');
      }),
    );
  }
}
