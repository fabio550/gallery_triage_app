import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gallery_triage_app/core/domain/repositories/triage_repository.dart';
import 'package:gallery_triage_app/core/infrastructure/data/local/app_database.dart';
import 'package:gallery_triage_app/core/infrastructure/data/local/drift_triage_repository.dart';

/// Instância única do banco Drift para todo o app.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final triageRepositoryProvider = Provider<TriageRepository>((ref) {
  return DriftTriageRepository(ref.watch(appDatabaseProvider));
});