abstract final class MockCategories {
  static List<CategorySummary> of(CategoryGranularity granularity) {
    return switch (granularity) {
      CategoryGranularity.all => _all,
      CategoryGranularity.month => _months,
      CategoryGranularity.year => _years,
      CategoryGranularity.type => _types,
      CategoryGranularity.album => _albums,
    };
  }

  static CategorySummary _make(
    CategoryGranularity granularity,
    String key,
    String label,
    int total,
    int kept,
    int classified,
    int sizeMb,
  ) {
    return CategorySummary(
      ref: CategoryRef(granularity: granularity, key: key),
      label: label,
      totalItems: total,
      keptItems: kept,
      classifiedItems: classified,
      sizeBytes: sizeMb * 1024 * 1024,
    );
  }

  static final _all = [
    _make(CategoryGranularity.all, 'all', 'Todos os itens',
        62418, 27310, 18902, 22220),
  ];

  static final _months = [
    // Recém-triado: quase tudo classificado.
    _make(CategoryGranularity.month, '2025-10', 'Outubro de 2025',
        1284, 901, 411, 4100),
    // Categoria fechada: tudo decidido.
    _make(CategoryGranularity.month, '2025-09', 'Setembro de 2025',
        906, 906, 798, 2900),
    // Mal começado.
    _make(CategoryGranularity.month, '2025-08', 'Agosto de 2025',
        2041, 449, 184, 6800),
    // Intocado: exercita o caso 0 na barra e no anel.
    _make(CategoryGranularity.month, '2025-07', 'Julho de 2025',
        3118, 0, 0, 9700),
    // Mantidas sem álbum dominam: segmento azul bem maior que o verde.
    _make(CategoryGranularity.month, '2025-06', 'Junho de 2025',
        874, 806, 91, 2600),
    _make(CategoryGranularity.month, '2025-05', 'Maio de 2025',
        1502, 640, 512, 5100),
    // Categoria minúscula: testa o rótulo no singular implícito.
    _make(CategoryGranularity.month, '2025-04', 'Abril de 2025',
        3, 1, 1, 12),
  ];

  static final _years = [
    _make(CategoryGranularity.year, '2025', '2025', 18402, 9210, 6104, 61000),
    _make(CategoryGranularity.year, '2024', '2024', 21876, 21876, 19340, 74000),
    _make(CategoryGranularity.year, '2023', '2023', 14330, 2011, 640, 48000),
    _make(CategoryGranularity.year, '2022', '2022', 7810, 0, 0, 26000),
  ];

  // Tipo não forma partição: Imagens contém Fotos e Screenshots (6.1.5).
  // Somar as quatro linhas não fecha o total, e é esperado.
  static final _types = [
    _make(CategoryGranularity.type, 'photos', 'Fotos',
        41209, 19004, 13880, 152000),
    _make(CategoryGranularity.type, 'screenshots', 'Screenshots',
        9877, 3120, 402, 3900),
    _make(CategoryGranularity.type, 'images', 'Imagens',
        51086, 22124, 14282, 155900),
    _make(CategoryGranularity.type, 'videos', 'Vídeos',
        11332, 5186, 4620, 66300),
  ];

  // Álbum: keptItems == classifiedItems == totalItems por definição.
  // O tile de álbum ignora as métricas, mas o assert de CategorySummary
  // não — se inverter, quebra em debug.
  static final _albums = [
    _make(CategoryGranularity.album, 'alb-1', 'Família',
        4219, 4219, 4219, 1900),
    _make(CategoryGranularity.album, 'alb-2', 'Viagens',
        3740, 3740, 3740, 2400),
    _make(CategoryGranularity.album, 'alb-3', 'Documentos',
        1108, 1108, 1108, 210),
    _make(CategoryGranularity.album, 'alb-4', 'Receitas',
        332, 332, 332, 96),
    _make(CategoryGranularity.album, 'alb-5', 'Trabalho',
        9503, 9503, 9503, 6100),
    _make(CategoryGranularity.album, 'alb-6',
        'Comprovantes de pagamento e recibos', 87, 87, 87, 14),
  ];
}
