import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gallery_triage_app/core/application/providers/media_permission_provider.dart';

/// 4.2.1 — "aviso persistente de galeria incompleta e oferece atalho
/// para ampliar a seleção." Fica sempre visível enquanto o estado for
/// `limited`: sem isso os contadores ficam silenciosamente errados e o
/// usuário não sabe por quê (4.2.1).
class PartialAccessBanner extends ConsumerWidget {
  const PartialAccessBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Material(
      color: scheme.surfaceContainerHigh,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 18,
                color: scheme.onSurfaceVariant,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Acesso parcial à galeria — alguns itens podem não '
                  'aparecer.',
                  style: text.bodySmall,
                ),
              ),
              // 4.2.1/6.2.18 — no Android 14+, pedir a permissão de
              // novo com o estado já `limited` reabre o seletor do
              // sistema para adicionar mais itens, sem sair pra
              // Configurações.
              TextButton(
                onPressed: () =>
                    ref.read(mediaPermissionProvider.notifier).request(),
                child: const Text('Ampliar seleção'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
