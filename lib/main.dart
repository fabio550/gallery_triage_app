import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gallery_triage_app/core/routes/app_router.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    ProviderScope(
      child: Consumer(
        builder: (context, ref, _) {
          final router = ref.watch(appRouterProvider);

          return MaterialApp.router(
            title: 'Driver Analytics',
            debugShowCheckedModeBanner: false,
            themeMode: ThemeMode.system,
            routerConfig: router,
          );
        },
      ),
    ),
  );
}
