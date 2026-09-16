import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gallery_triage_app/core/application/providers/media_repository_provider.dart';
import 'package:gallery_triage_app/core/application/providers/triage_repository_provider.dart';
import 'package:gallery_triage_app/core/application/services/album_move_service.dart';

final albumMoveServiceProvider = Provider<AlbumMoveService>((ref) {
  return AlbumMoveService(
    mediaRepository: ref.watch(mediaRepositoryProvider),
    triageRepository: ref.watch(triageRepositoryProvider),
  );
});
