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

  /// 2.1.5 — `mediaStoreId` de tudo que está na lixeira do sistema
  /// agora (`IS_TRASHED`), via canal nativo. Cobre também o que foi
  /// retido por fora deste app (outro app, Fotos do sistema) — algo
  /// que `photo_manager` não expõe.
  ///
  /// `null` quando o canal falha ou está indisponível — nunca vira
  /// exceção pro `SyncService` (§7), mas também nunca é confundido com
  /// "nada retido agora": um conjunto vazio por falha de canal faria a
  /// sincronização tratar tudo que estava retido como purgado de
  /// verdade e apagar essas linhas do índice.
  Future<Set<int>?> systemTrashedMediaStoreIds();

  /// 6.5.7 — move um lote heterogêneo (cada item pode ter um destino
  /// diferente) via canal nativo próprio — um único diálogo do sistema
  /// (`createWriteRequest`, API 30+) pro lote inteiro, mesmo com vários
  /// destinos distintos. Diferente de usar `photo_manager` direto, que
  /// só aceita um destino por chamada (um diálogo por álbum). Retorna
  /// só os `mediaStoreId` efetivamente movidos (§7) — `RESULT_CANCELED`
  /// do diálogo, ou qualquer falha, devolve lista vazia; os itens
  /// continuam pendentes do lado de quem chama.
  ///
  /// `isVideo` por item é necessário porque `createWriteRequest` exige
  /// a URI da coleção certa (`Images`/`Video`) — a URI genérica de
  /// `Files` (usada pra consulta/lixeira) é rejeitada por ele com
  /// `IllegalArgumentException: All requested items must be Media
  /// items`, mesmo apontando pra mesma linha.
  Future<List<int>> moveAssetsToPaths(
    Map<int, ({String targetRelativePath, bool isVideo})> movesByMediaStoreId,
  );

  /// 6.5.8 — todo `RELATIVE_PATH` distinto que já tem pelo menos um
  /// item de mídia agora (Câmera, WhatsApp Images, pastas de outro
  /// app etc.), via canal nativo. Mesma convenção usada pelas galerias
  /// do sistema: pasta vazia não é "álbum" — não há como distinguir
  /// uma pasta vazia de verdade de uma que nunca existiu no MediaStore
  /// (não é uma entidade própria, só um valor de coluna compartilhado
  /// entre arquivos). Lista vazia se o canal falhar — nunca exceção.
  Future<List<String>> discoverMediaFolders();
}
