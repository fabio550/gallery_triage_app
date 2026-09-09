import 'package:gallery_triage_app/core/domain/entities/media_item_entity.dart';
import 'package:gallery_triage_app/core/domain/enums/category_granularity.dart';
import 'package:gallery_triage_app/core/domain/enums/triage_decision.dart';
import 'package:gallery_triage_app/core/domain/models/category_summary.dart';
import 'package:gallery_triage_app/features/dashboard/infrastructure/data/mock_media_items.dart';

const _monthNames = [
  '',
  'Janeiro',
  'Fevereiro',
  'Março',
  'Abril',
  'Maio',
  'Junho',
  'Julho',
  'Agosto',
  'Setembro',
  'Outubro',
  'Novembro',
  'Dezembro',
];

/// Deriva [CategorySummary] a partir de [MockMediaItems.all]. Nenhum
/// total é digitado — é a mesma garantia que o `TriageRepository` real
/// (2.4.2) vai dar via `COUNT` indexado (8.3).
abstract final class MockCategories {
  static List<CategorySummary> of(CategoryGranularity granularity) {
    return switch (granularity) {
      CategoryGranularity.all => _all(),
      CategoryGranularity.month => _months(),
      CategoryGranularity.year => _years(),
      CategoryGranularity.type => _types(),
      CategoryGranularity.album => _albums(),
    };
  }

  static List<CategorySummary> _all() {
    final summary = _summarize(
      CategoryRef(granularity: CategoryGranularity.all, key: 'all'),
      'Todos os itens',
      MockMediaItems.all,
    );
    return summary == null ? const [] : [summary];
  }

  static List<CategorySummary> _months() {
    final keys = MockMediaItems.all
        .map((i) => MockMediaItems.monthKey(i.dateTaken))
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a)); // 6.1.8: temporal decrescente.

    return keys
        .map((key) {
          final parts = key.split('-');
          final month = int.parse(parts[1]);
          final label = '${_monthNames[month]} de ${parts[0]}';
          return _summarize(
            CategoryRef(granularity: CategoryGranularity.month, key: key),
            label,
            MockMediaItems.byMonth(key),
          );
        })
        .whereType<CategorySummary>()
        .toList();
  }

  static List<CategorySummary> _years() {
    final keys = MockMediaItems.all
        .map((i) => i.dateTaken.year.toString())
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));

    return keys
        .map((key) => _summarize(
              CategoryRef(granularity: CategoryGranularity.year, key: key),
              key,
              MockMediaItems.byYear(key),
            ))
        .whereType<CategorySummary>()
        .toList();
  }

  static List<CategorySummary> _types() {
    // Ordem fixa (6.1.8). Mesmo padrão skip-se-vazio dos demais
    // granularidades: um tipo sem item contável não vira tile.
    return [
      _summarize(
        CategoryRef(granularity: CategoryGranularity.type, key: 'photos'),
        'Fotos',
        MockMediaItems.photos(),
      ),
      _summarize(
        CategoryRef(
            granularity: CategoryGranularity.type, key: 'screenshots'),
        'Screenshots',
        MockMediaItems.screenshots(),
      ),
      _summarize(
        CategoryRef(granularity: CategoryGranularity.type, key: 'images'),
        'Imagens',
        MockMediaItems.images(),
      ),
      _summarize(
        CategoryRef(granularity: CategoryGranularity.type, key: 'videos'),
        'Vídeos',
        MockMediaItems.videos(),
      ),
    ].whereType<CategorySummary>().toList();
  }

  static List<CategorySummary> _albums() {
    final ids = MockMediaItems.all
        .map((i) => i.albumId)
        .whereType<String>()
        .toSet()
        .toList()
      ..sort((a, b) =>
          (MockAlbums.names[a] ?? a).compareTo(MockAlbums.names[b] ?? b));

    return ids
        .map((id) => _summarize(
              CategoryRef(granularity: CategoryGranularity.album, key: id),
              MockAlbums.names[id] ?? id,
              MockMediaItems.byAlbum(id),
            ))
        .whereType<CategorySummary>()
        .toList();
  }

  /// `null` se a categoria não tiver nenhum item contável (6.1.10) —
  /// evita gerar um `CategoryTile` para um recorte vazio.
  static CategorySummary? _summarize(
    CategoryRef ref,
    String label,
    List<MediaItemEntity> items,
  ) {
    final countable = items.where((i) => i.isCountable).toList();
    if (countable.isEmpty) return null;

    final kept =
        countable.where((i) => i.decision == TriageDecision.kept).toList();

    // Fix deliberado: NÃO usar `isClassified` (albumId != null) aqui. Um
    // item classificado que entrou na fila de exclusão preserva albumId
    // (3.2.5) mas deixa de estar "mantido" — 6.1.2 manda esse item para
    // o trilho vazio, não para os segmentos preenchidos. Sem essa
    // restrição extra, `classifiedItems` podia superar `keptItems` e
    // quebrar o assert de CategorySummary.
    final classified = kept.where((i) => i.albumId != null).length;

    final sizeBytes = countable.fold<int>(0, (sum, i) => sum + i.sizeBytes);

    return CategorySummary(
      ref: ref,
      label: label,
      totalItems: countable.length,
      keptItems: kept.length,
      classifiedItems: classified,
      sizeBytes: sizeBytes,
      coverItemId: countable.first.id,
    );
  }
}
