import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gallery_triage_app/core/application/providers/media_permission_provider.dart';
import 'package:gallery_triage_app/core/domain/enums/media_permission_status.dart';
import 'package:gallery_triage_app/core/presentation/widgets/sync_gate.dart';
import 'package:gallery_triage_app/features/permission/presentation/pages/permission_checking_page.dart';
import 'package:gallery_triage_app/features/permission/presentation/pages/permission_denied_page.dart';
import 'package:gallery_triage_app/features/permission/presentation/widgets/partial_access_banner.dart';

/// Porta de entrada do app (4.2.2 — "o app não tem função sem a
/// permissão"). A rota `/` passa por aqui antes do Dashboard; nenhuma
/// outra tela verifica permissão de novo, porque a Tela de Triagem só
/// é alcançável a partir do Dashboard.
class PermissionGate extends ConsumerWidget {
  const PermissionGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permission = ref.watch(mediaPermissionProvider);

    return permission.when(
      loading: () => const PermissionCheckingPage(),
      // Falha inesperada ao consultar o plugin — trata como negado em
      // vez de travar numa tela em branco; o botão "Permitir acesso"
      // tenta de novo.
      error: (Object error, StackTrace stackTrace) =>
          const PermissionDeniedPage(),
      data: (status) => switch (status) {
        MediaPermissionStatus.granted => const SyncGate(),
        // 4.2.1 — sync/Dashboard funcionam normalmente, só com o aviso
        // persistente no topo.
        MediaPermissionStatus.limited => const Column(
          children: [PartialAccessBanner(), Expanded(child: SyncGate())],
        ),
        MediaPermissionStatus.denied ||
        MediaPermissionStatus.permanentlyDenied =>
          const PermissionDeniedPage(),
      },
    );
  }
}
