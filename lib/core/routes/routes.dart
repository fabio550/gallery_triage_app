import 'package:gallery_triage_app/core/presentation/pages/home_page.dart';
import 'package:go_router/go_router.dart';

final routes = [
  GoRoute(
    path: '/',
    builder: (context, state) => const HomePage(),
  ),
];
