import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gallery_triage_app/core/application/providers/media_repository_provider.dart';
import 'package:gallery_triage_app/core/application/providers/preferences_repository_provider.dart';
import 'package:gallery_triage_app/core/application/providers/triage_repository_provider.dart';
import 'package:gallery_triage_app/core/application/services/sync_service.dart';

final syncServiceProvider = Provider<SyncService>((ref) {
  return SyncService(
    mediaRepository: ref.watch(mediaRepositoryProvider),
    triageRepository: ref.watch(triageRepositoryProvider),
    preferencesRepository: ref.watch(preferencesRepositoryProvider),
  );
});
