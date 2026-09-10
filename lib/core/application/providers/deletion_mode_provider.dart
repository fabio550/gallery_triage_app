import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gallery_triage_app/core/domain/enums/deletion_mode.dart';

final deletionModeProvider =
    NotifierProvider<DeletionModeNotifier, DeletionMode>(
  DeletionModeNotifier.new,
);

/// 4.4.2 — "a última escolha é memorizada como padrão e vem
/// pré-selecionada nas próximas operações". Em memória por enquanto,
/// como o resto de 2.6 (viraria `shared_preferences`).
///
/// Padrão inicial: lixeira do sistema — reversível, a opção mais
/// segura antes de existir qualquer escolha do usuário.
class DeletionModeNotifier extends Notifier<DeletionMode> {
  @override
  DeletionMode build() => DeletionMode.trash;

  void set(DeletionMode mode) => state = mode;
}