import '../enums/triage_decision.dart';

/// Metadados síncronos de um ativo do MediaStore (5.1), sem `sizeBytes`
/// — a única propriedade que exige uma chamada de canal por item
/// (`photo_manager`'s `AssetEntity.fileSize`). Ponte entre a leitura
/// nativa (`MediaRepository`, camada `data`) e a entidade de domínio
/// completa (`MediaItemEntity`), que só é montada para os itens que a
/// sincronização (5.3.4) realmente precisa persistir — a maioria dos
/// itens, já indexados e sem mudança, nunca chega a pedir o tamanho.
class MediaStoreAsset {
  const MediaStoreAsset({
    required this.mediaStoreId,
    required this.fileName,
    required this.dateTaken,
    required this.mimeType,
    required this.relativePath,
    required this.mediaType,
    required this.isScreenshot,
    this.durationMs,
  });

  /// `MediaStore._ID` no momento desta leitura — não é a chave
  /// primária do domínio (2.5.1/2.5.2), só o ponto de correspondência
  /// com o índice local.
  final int mediaStoreId;

  final String fileName;

  /// `DATE_TAKEN`, com fallback para `DATE_MODIFIED` já resolvido pela
  /// camada `data` (2.2.1).
  final DateTime dateTaken;

  final String mimeType;
  final String relativePath;
  final MediaType mediaType;

  /// Derivado de [relativePath] na leitura (6.1.9), não recalculado
  /// depois.
  final bool isScreenshot;

  final int? durationMs;
}
