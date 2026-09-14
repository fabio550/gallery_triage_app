import 'package:flutter/material.dart';

/// Estado transitório da primeira checagem de permissão (4.2) — não
/// dispara diálogo nenhum, só aguarda `MediaPermissionRepository.status()`
/// responder.
class PermissionCheckingPage extends StatelessWidget {
  const PermissionCheckingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
