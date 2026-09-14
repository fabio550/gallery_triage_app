import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gallery_triage_app/core/application/providers/media_permission_provider.dart';
import 'package:gallery_triage_app/core/domain/enums/media_permission_status.dart';

/// §7 — "Permissão negada: tela dedicada com explicação e atalho para
/// as configurações do sistema." Cobre `denied` (o diálogo do sistema
/// ainda pode aparecer) e `permanentlyDenied` (só as Configurações
/// resolvem, 4.2.2) — só o botão principal muda de ação entre os dois.
class PermissionDeniedPage extends ConsumerStatefulWidget {
  const PermissionDeniedPage({super.key});

  @override
  ConsumerState<PermissionDeniedPage> createState() =>
      _PermissionDeniedPageState();
}

class _PermissionDeniedPageState extends ConsumerState<PermissionDeniedPage> {
  /// Estado local só pra desabilitar o botão durante o request —
  /// o resultado em si chega pelo `mediaPermissionProvider`, que o
  /// `PermissionGate` acima já observa pra trocar de tela.
  bool _requesting = false;

  Future<void> _onPrimaryAction(MediaPermissionStatus status) async {
    setState(() => _requesting = true);
    if (status == MediaPermissionStatus.permanentlyDenied) {
      await ref.read(mediaPermissionProvider.notifier).openSystemSettings();
    } else {
      await ref.read(mediaPermissionProvider.notifier).request();
    }
    if (mounted) setState(() => _requesting = false);
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    // Riverpod 3.x: `.value` já é o getter nullable (equivalente ao
    // `valueOrNull` da v2) — não lança em erro/loading.
    final status =
        ref.watch(mediaPermissionProvider).value ??
            MediaPermissionStatus.denied;
    final isPermanent = status == MediaPermissionStatus.permanentlyDenied;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.photo_library_outlined,
                  size: 64,
                  color: scheme.onSurfaceVariant,
                ),
                const SizedBox(height: 24),
                Text(
                  'Acesso à galeria necessário',
                  style: text.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  isPermanent
                      ? 'A permissão foi negada e o app não pode mais '
                          'perguntar diretamente. Ative o acesso a fotos e '
                          'vídeos nas configurações do sistema para '
                          'continuar.'
                      : 'Este app organiza e ajuda a limpar sua galeria de '
                          'fotos e vídeos no aparelho — sem essa permissão '
                          'ele não tem função (nada é enviado para fora do '
                          'dispositivo).',
                  style: text.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed:
                        _requesting ? null : () => _onPrimaryAction(status),
                    child: _requesting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            isPermanent
                                ? 'Abrir configurações'
                                : 'Permitir acesso',
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
