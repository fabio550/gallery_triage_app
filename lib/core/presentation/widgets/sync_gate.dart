import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gallery_triage_app/core/application/providers/sync_provider.dart';
import 'package:gallery_triage_app/core/application/services/sync_status.dart';
import 'package:gallery_triage_app/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:gallery_triage_app/features/sync/presentation/pages/first_scan_page.dart';

/// Entre o `PermissionGate` (4.2) e o Dashboard — decide entre a
/// checagem inicial, o primeiro scan bloqueante (5.2.1) e o Dashboard
/// já pronto (a sincronização incremental, 5.3.5, roda por trás sem
/// passar por aqui de novo).
class SyncGate extends ConsumerStatefulWidget {
  const SyncGate({super.key});

  @override
  ConsumerState<SyncGate> createState() => _SyncGateState();
}

class _SyncGateState extends ConsumerState<SyncGate> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // 5.3.1 — retomada do primeiro plano também dispara sincronização.
    // Vive aqui (não em `main.dart`) porque `syncProvider` só deve ser
    // criado depois que a permissão de mídia já foi confirmada — este
    // widget só existe na árvore nesse ponto.
    if (state == AppLifecycleState.resumed) {
      ref.read(syncProvider.notifier).resyncOnResume();
    }
  }

  @override
  Widget build(BuildContext context) {
    final sync = ref.watch(syncProvider);

    return switch (sync.phase) {
      SyncPhase.checking => const _SyncCheckingPage(),
      SyncPhase.firstScanning => FirstScanPage(processed: sync.processed),
      SyncPhase.ready => const DashboardPage(),
      SyncPhase.failed => _SyncFailedPage(error: sync.error),
    };
  }
}

class _SyncCheckingPage extends StatelessWidget {
  const _SyncCheckingPage();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

class _SyncFailedPage extends ConsumerWidget {
  const _SyncFailedPage({this.error});

  final Object? error;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 48,
                  color: scheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  'Não foi possível indexar a galeria',
                  style: text.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () =>
                      ref.read(syncProvider.notifier).retryFirstScan(),
                  child: const Text('Tentar de novo'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
