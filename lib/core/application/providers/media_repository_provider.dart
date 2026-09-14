import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gallery_triage_app/core/domain/repositories/media_repository.dart';
import 'package:gallery_triage_app/core/infrastructure/platform/photo_manager_media_repository.dart';

final mediaRepositoryProvider = Provider<MediaRepository>((ref) {
  return PhotoManagerMediaRepository();
});
