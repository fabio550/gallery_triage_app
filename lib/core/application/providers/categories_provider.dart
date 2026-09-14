import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gallery_triage_app/core/application/providers/triage_repository_provider.dart';
import 'package:gallery_triage_app/core/domain/enums/category_granularity.dart';
import 'package:gallery_triage_app/core/domain/models/category_summary.dart';

/// Recortes agregados do Dashboard (6.1), por granularidade — fonte
/// real (Drift), substitui o antigo `MockCategories`. `autoDispose`
/// porque o Dashboard é a única tela que consome isto; não precisa
/// sobreviver fora dele.
final categoriesProvider = FutureProvider.autoDispose
    .family<List<CategorySummary>, CategoryGranularity>((ref, granularity) {
  return ref.watch(triageRepositoryProvider).categoriesFor(granularity);
});

/// Contagem por álbum, incluindo vazios (6.2.16) — usado pelo painel
/// de álbuns, que precisa mostrar "0" em vez de esconder o álbum.
final albumItemCountsProvider =
    FutureProvider.autoDispose<Map<String, int>>((ref) {
  return ref.watch(triageRepositoryProvider).albumItemCounts();
});
