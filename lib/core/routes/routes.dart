import 'package:gallery_triage_app/core/domain/models/category_summary.dart';
import 'package:gallery_triage_app/core/presentation/widgets/permission_gate.dart';
import 'package:gallery_triage_app/features/albums/presentation/pages/album_management_page.dart';
import 'package:gallery_triage_app/features/triage/presentation/page/triage_page.dart';
import 'package:go_router/go_router.dart';

final routes = [
  // 4.2.2 — "o app não tem função sem a permissão". O Dashboard só
  // aparece atrás do PermissionGate, nunca direto: é o único lugar que
  // decide entre Dashboard, aviso de acesso parcial (4.2.1) ou a tela
  // de permissão negada (§7).
  GoRoute(
    path: '/',
    builder: (context, state) => const PermissionGate(),
  ),
  GoRoute(
    path: '/triage-page',
    builder: (context, state) {
      final category = state.extra as CategorySummary;

      return TriagePage(category: category);
    }
  ),
  // 6.5.2 — tela dedicada de gestão de álbuns. Ponto de entrada (P-08)
  // decidido: ícone na AppBar do Dashboard.
  GoRoute(
    path: '/albums',
    builder: (context, state) => const AlbumManagementPage(),
  ),
];
