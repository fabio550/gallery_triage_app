import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gallery_triage_app/core/domain/repositories/media_permission_repository.dart';
import 'package:gallery_triage_app/core/infrastructure/platform/permission_handler_media_permission_repository.dart';

final mediaPermissionRepositoryProvider =
    Provider<MediaPermissionRepository>((ref) {
  return PermissionHandlerMediaPermissionRepository();
});
