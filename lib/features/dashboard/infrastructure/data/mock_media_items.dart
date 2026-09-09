
import 'package:gallery_triage_app/core/domain/enums/category_granularity.dart';
import 'package:gallery_triage_app/core/domain/enums/triage_decision.dart';
import 'package:gallery_triage_app/core/domain/models/category_summary.dart';

import '../../../../core/domain/entities/media_item_entity.dart';

/// Placeholder até a entidade `Album` (2.2.2) entrar no domínio. Mapeia
/// albumId → nome só para rotular os testes mockados; some quando o
/// domínio real de álbum existir.
abstract final class MockAlbums {
  static const familia = 'alb-familia';
  static const viagens = 'alb-viagens';
  static const documentos = 'alb-documentos';

  static const names = <String, String>{
    familia: 'Família',
    viagens: 'Viagens',
    documentos: 'Documentos',
  };
}

/// Dataset único de [MediaItemEntity] para a fase mockada.
///
/// Fonte de verdade única: `MockCategories` deriva seus totais a partir
/// daqui, e a Tela de Triagem consome os mesmos itens por categoria. Não
/// há números digitados à parte — evita o dashboard mostrar uma
/// contagem que a triagem não consegue reproduzir.
///
/// Substituído pelo `MediaRepository` real quando o `SyncService`
/// existir (5.2/5.3).
abstract final class MockMediaItems {
  static final List<MediaItemEntity> all = _build();

  static String monthKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}';

  static List<MediaItemEntity> byMonth(String key) =>
      all.where((i) => monthKey(i.dateTaken) == key).toList();

  static List<MediaItemEntity> byYear(String key) =>
      all.where((i) => i.dateTaken.year.toString() == key).toList();

  static List<MediaItemEntity> byAlbum(String albumId) =>
      all.where((i) => i.albumId == albumId).toList();

  // Tipo não forma partição (6.1.5): Imagens contém Fotos e Screenshots.
  static List<MediaItemEntity> photos() => all
      .where((i) => i.mediaType == MediaType.image && !i.isScreenshot)
      .toList();

  static List<MediaItemEntity> screenshots() => all
      .where((i) => i.mediaType == MediaType.image && i.isScreenshot)
      .toList();

  static List<MediaItemEntity> images() =>
      all.where((i) => i.mediaType == MediaType.image).toList();

  static List<MediaItemEntity> videos() =>
      all.where((i) => i.mediaType == MediaType.video).toList();

  /// Ponto único de resolução `CategoryRef → itens`. Usado pela Tela de
  /// Triagem e, futuramente, pelo `TriageRepository` real como contrato
  /// de referência. Filtra por [MediaItemEntity.isCountable] (6.1.10):
  /// itens retidos ou indisponíveis não entram em nenhum recorte.
  static List<MediaItemEntity> forCategory(CategoryRef ref) {
    final items = switch (ref.granularity) {
      CategoryGranularity.all => all,
      CategoryGranularity.month => byMonth(ref.key),
      CategoryGranularity.year => byYear(ref.key),
      CategoryGranularity.album => byAlbum(ref.key),
      CategoryGranularity.type => switch (ref.key) {
          'photos' => photos(),
          'screenshots' => screenshots(),
          'images' => images(),
          'videos' => videos(),
          _ => const <MediaItemEntity>[],
        },
    };
    return items.where((i) => i.isCountable).toList();
  }

  static int _seq = 0;

  static MediaItemEntity _photo(
    DateTime dateTaken, {
    bool isScreenshot = false,
    int sizeMb = 4,
  }) {
    _seq++;
    return MediaItemEntity(
      id: 'mock-$_seq',
      mediaStoreId: 1000 + _seq,
      fingerprint: 'fp-$_seq',
      dateTaken: dateTaken,
      sizeBytes: sizeMb * 1024 * 1024,
      mimeType: isScreenshot ? 'image/png' : 'image/jpeg',
      relativePath: isScreenshot ? 'Pictures/Screenshots' : 'DCIM/Camera',
      mediaType: MediaType.image,
      isScreenshot: isScreenshot,
    );
  }

  static MediaItemEntity _video(
    DateTime dateTaken, {
    int sizeMb = 40,
    int durationMs = 15000,
  }) {
    _seq++;
    return MediaItemEntity(
      id: 'mock-$_seq',
      mediaStoreId: 1000 + _seq,
      fingerprint: 'fp-$_seq',
      dateTaken: dateTaken,
      sizeBytes: sizeMb * 1024 * 1024,
      mimeType: 'video/mp4',
      relativePath: 'DCIM/Camera',
      mediaType: MediaType.video,
      isScreenshot: false,
      durationMs: durationMs,
    );
  }

  static List<MediaItemEntity> _build() {
    final now = DateTime(2025, 10, 20);
    final items = <MediaItemEntity>[];

    // --- Outubro de 2025: recém-triado, quase tudo classificado ----------
    items.addAll([
      _photo(DateTime(2025, 10, 2, 9, 10))
          .assignToAlbum(MockAlbums.familia, now),
      _photo(DateTime(2025, 10, 5, 18, 40))
          .assignToAlbum(MockAlbums.viagens, now),
      _video(DateTime(2025, 10, 8, 20), durationMs: 32000)
          .assignToAlbum(MockAlbums.viagens, now),
      _photo(DateTime(2025, 10, 12, 14)).keep(now),
      // Classificado que caiu na fila: preserva albumId (3.2.5). Testa a
      // precedência visual (vermelho > verde, 3.3) e o fix do agregado —
      // não deve contar nem como mantido nem como classificado (6.1.2).
      _photo(DateTime(2025, 10, 15, 11))
          .assignToAlbum(MockAlbums.familia, now)
          .markForDeletion(now),
    ]);

    // --- Setembro de 2025: categoria fechada, tudo decidido ---------------
    items.addAll([
      _photo(DateTime(2025, 9, 3, 8))
          .assignToAlbum(MockAlbums.documentos, now),
      _photo(DateTime(2025, 9, 10, 19, 30)).keep(now),
      _photo(DateTime(2025, 9, 18, 12), isScreenshot: true, sizeMb: 1)
          .markForDeletion(now),
      _video(DateTime(2025, 9, 22, 16, 45), durationMs: 9000).keep(now),
      _photo(DateTime(2025, 9, 27, 10))
          .assignToAlbum(MockAlbums.familia, now),
    ]);

    // --- Agosto de 2025: mal começado --------------------------------------
    items.addAll([
      _photo(DateTime(2025, 8, 1, 9)),
      _photo(DateTime(2025, 8, 6, 17)),
      _photo(DateTime(2025, 8, 14, 13, 20)).keep(now),
      _video(DateTime(2025, 8, 25, 21), durationMs: 51000),
    ]);

    // --- Julho de 2025: intocado, exercita o caso 0 na barra e no anel ----
    items.addAll([
      _photo(DateTime(2025, 7, 2, 10), isScreenshot: true, sizeMb: 1),
      _photo(DateTime(2025, 7, 9, 15)),
      _photo(DateTime(2025, 7, 19, 11, 30)),
      _video(DateTime(2025, 7, 30, 19), durationMs: 22000),
    ]);

    // --- Junho de 2025: mantidas sem álbum dominam -------------------------
    items.addAll([
      _photo(DateTime(2025, 6, 4, 8, 30)).keep(now),
      _photo(DateTime(2025, 6, 11, 12)).keep(now),
      _photo(DateTime(2025, 6, 20, 17, 40)).keep(now),
      _photo(DateTime(2025, 6, 28, 9))
          .assignToAlbum(MockAlbums.viagens, now),
    ]);

    // --- Maio de 2025: mix kept / classificado ------------------------------
    items.addAll([
      _photo(DateTime(2025, 5, 3, 10))
          .assignToAlbum(MockAlbums.familia, now),
      _photo(DateTime(2025, 5, 12, 14)).keep(now),
      _video(DateTime(2025, 5, 19, 20), durationMs: 18000)
          .assignToAlbum(MockAlbums.viagens, now),
      _photo(DateTime(2025, 5, 26, 16)).keep(now),
    ]);

    // --- Abril de 2025: categoria minúscula, testa singular implícito ------
    items.add(_photo(DateTime(2025, 4, 5, 9)).keep(now));

    // --- Anos anteriores: variedade para a granularidade Ano ---------------
    items.addAll([
      _photo(DateTime(2024, 11, 3, 9))
          .assignToAlbum(MockAlbums.documentos, now),
      _photo(DateTime(2024, 11, 14, 13)).keep(now),
      _video(DateTime(2024, 11, 22, 18), durationMs: 27000),
      _photo(DateTime(2023, 3, 6, 10)),
      _photo(DateTime(2023, 3, 21, 15, 30)).markForDeletion(now),
    ]);

    return items;
  }
}
