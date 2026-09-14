import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gallery_triage_app/core/application/providers/media_permission_provider.dart';
import 'package:gallery_triage_app/core/presentation/theme/app_theme.dart';
import 'package:gallery_triage_app/core/routes/app_router.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    ProviderScope(
      child: Consumer(
        builder: (context, ref, _) {
          final router = ref.watch(appRouterProvider);

          return MaterialApp.router(
            title: 'Triagem de Galeria',
            debugShowCheckedModeBanner: false,
            themeMode: ThemeMode.dark,
            theme: AppTheme.dark,
            routerConfig: router,
            builder: (context, child) =>
                _AppLifecycleGate(child: child ?? const SizedBox.shrink()),
          );
        },
      ),
    ),
  );
}

/// 5.3.1 — "toda abertura do app e retomada do primeiro plano" é
/// gatilho de reavaliação. Aqui cobre a permissão de mídia (4.2): sem
/// isso, voltar das Configurações do sistema depois de conceder acesso
/// deixaria o app preso na tela de permissão negada até reiniciar.
class _AppLifecycleGate extends ConsumerStatefulWidget {
  const _AppLifecycleGate({required this.child});

  final Widget child;

  @override
  ConsumerState<_AppLifecycleGate> createState() => _AppLifecycleGateState();
}

class _AppLifecycleGateState extends ConsumerState<_AppLifecycleGate>
    with WidgetsBindingObserver {
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
    if (state == AppLifecycleState.resumed) {
      ref.read(mediaPermissionProvider.notifier).refresh();
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
