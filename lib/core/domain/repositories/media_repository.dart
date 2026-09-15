import 'dart:typed_data';

import '../models/media_store_asset.dart';

/// Acesso de leitura ao MediaStore (2.4.1). Implementação concreta
/// (`photo_manager`) vive na camada `data`/`infrastructure` — o
/// domínio e o `SyncService` não conhecem o pacote de plataforma.
abstract class MediaRepository {
  /// Handshake com o plugin de mídia antes de qualquer consulta. A
  /// permissão real já foi concedida via `MediaPermissionRepository`
  /// (seção 4) antes de qualquer chamador chegar aqui — isto não deve
  /// nunca abrir diálogo, só confirmar o estado já concedido junto ao
  /// plugin.
  Future<void> ensureReady();

  /// Varre o MediaStore em lotes (5.2.3 — 500 a 1000 por vez), sem
  /// filtrar ainda pelo escopo de 5.1 (DCIM + Pictures/Screenshots) —
  /// isso é responsabilidade de quem consome o stream, porque o
  /// `relativePath` de cada item já vem na leitura síncrona e não
  /// exige mais nenhuma chamada de canal pra decidir.
  ///
  /// [startPage] permite retomar depois de `page * batchSize` itens já
  /// processados (5.2.4).
  Stream<List<MediaStoreAsset>> scanBatches({
    int batchSize = 500,
    int startPage = 0,
  });

  /// Tamanho em bytes de um ativo — único campo de [MediaStoreAsset]
  /// que exige uma chamada de canal isolada por item.
  Future<int> readSizeBytes(int mediaStoreId);

  /// Miniatura para exibição (8.5 — ~200x200 no carrossel/capas; um
  /// tamanho maior é usado pelo card principal, 6.2.8). `null` em
  /// falha de leitura — a UI cai no placeholder (§7).
  Future<Uint8List?> readThumbnail(int mediaStoreId, {required int size});

  /// Dispara `MediaStore.createTrashRequest` (4.3.1) para o lote
  /// inteiro — um único diálogo do sistema (4.3.2). Retorna só os
  /// `mediaStoreId` efetivamente movidos pro sistema, nunca os
  /// enviados (4.3.5); vazio se `RESULT_CANCELED` (4.3.6).
  Future<List<int>> moveToSystemTrash(List<int> mediaStoreIds);

  /// Dispara `MediaStore.createDeleteRequest` (4.3.1), mesma regra de
  /// lote único e retorno pelo processado de fato (4.3.5/4.3.6).
  /// Irreversível (4.4.4).
  Future<List<int>> deletePermanently(List<int> mediaStoreIds);
}
