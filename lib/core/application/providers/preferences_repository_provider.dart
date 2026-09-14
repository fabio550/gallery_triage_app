import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gallery_triage_app/core/application/providers/triage_repository_provider.dart';
import 'package:gallery_triage_app/core/domain/repositories/preferences_repository.dart';
import 'package:gallery_triage_app/core/infrastructure/data/local/drift_preferences_repository.dart';

/// Mesma instância de [AppDatabase] do `triageRepositoryProvider` — só
/// a tabela consultada muda (2.6 vive junto no mesmo arquivo Drift, não
/// exige banco à parte).
final preferencesRepositoryProvider = Provider<PreferencesRepository>((ref) {
  return DriftPreferencesRepository(ref.watch(appDatabaseProvider));
});
