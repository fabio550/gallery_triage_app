import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gallery_triage_app/core/application/providers/media_permission_repository_provider.dart';
import 'package:gallery_triage_app/core/domain/enums/media_permission_status.dart';

final mediaPermissionProvider = NotifierProvider<MediaPermissionNotifier,
    AsyncValue<MediaPermissionStatus>>(MediaPermissionNotifier.new);

/// Gate de acesso à galeria (seção 4). `AsyncValue.loading` cobre a
/// checagem inicial — não dispara diálogo nenhum, só lê o estado atual
/// (`status()`); [request] é o único método que pode abrir o diálogo
/// do sistema ou, em [MediaPermissionStatus.limited] no Android 14+, o
/// seletor de ampliar seleção.
class MediaPermissionNotifier
    extends Notifier<AsyncValue<MediaPermissionStatus>> {
  late final _repository = ref.read(mediaPermissionRepositoryProvider);

  @override
  AsyncValue<MediaPermissionStatus> build() {
    _check();
    return const AsyncValue.loading();
  }

  Future<void> _check() async {
    final status = await _repository.status();
    if (ref.mounted) state = AsyncValue.data(status);
  }

  /// Dispara o diálogo do sistema (tela de permissão negada, §7) ou —
  /// já em [MediaPermissionStatus.limited] — o atalho de "ampliar a
  /// seleção" do aviso persistente (4.2.1).
  Future<void> request() async {
    final status = await _repository.request();
    if (ref.mounted) state = AsyncValue.data(status);
  }

  /// 5.3.1 — reavalia ao voltar do primeiro plano ou das Configurações
  /// do sistema, sem abrir diálogo nenhum.
  Future<void> refresh() => _check();

  Future<bool> openSystemSettings() => _repository.openSystemSettings();
}
