import '../entities/album_entity.dart';
import '../entities/media_item_entity.dart';
import '../enums/category_granularity.dart';
import '../enums/sort_order.dart';
import '../models/category_summary.dart';

/// Leitura e escrita de decisão, álbum e fila de exclusão (2.4.2), mais
/// as consultas agregadas do Dashboard (6.1) e o ponto de escrita do
/// `SyncService` (5.2/5.3). Implementação concreta (Drift) vive na
/// camada `data`.
abstract class TriageRepository {
  /// Itens contáveis (6.1.10) do recorte, ordenados por `dateTaken`
  /// conforme [sortOrder] (6.2.3 — sempre cronológica, nunca por outro
  /// critério). Sem paginação ainda — o volume real (8.1) ainda não
  /// exigiu (8.4).
  Future<List<MediaItemEntity>> itemsForCategory(
    CategoryRef ref, {
    required SortOrder sortOrder,
  });

  /// Recortes da granularidade selecionada (6.1.3), já com os totais
  /// agregados (`COUNT`/soma, 8.3) — usado pelo Dashboard. Uma
  /// categoria sem item contável não aparece (6.1.11: "null se vazio"
  /// na implementação).
  Future<List<CategorySummary>> categoriesFor(CategoryGranularity granularity);

  /// Contagem de itens por álbum, incluindo álbuns sem nenhum item
  /// (diferente de [categoriesFor] com granularidade `album`, que omite
  /// os vazios porque o Dashboard não lista categoria vazia). Usado
  /// pelo painel de álbuns (6.2.16), que precisa mostrar "0" nos vazios
  /// em vez de escondê-los.
  Future<Map<String, int>> albumItemCounts();

  /// Upsert genérico — grava a entidade inteira, não campos
  /// individuais. Chamado a cada transição de domínio (write-through).
  Future<void> updateItem(MediaItemEntity item);

  /// Inserção em lote dos itens novos encontrados pelo `SyncService`
  /// (5.2.3 — lotes de 500 a 1000, uma transação por lote). Distinto de
  /// [updateItem]: aquele é write-through de uma transição de triagem;
  /// este é o caminho de escrita em massa da sincronização.
  Future<void> upsertScanned(List<MediaItemEntity> items);

  /// `mediaStoreId` de todo item já indexado (qualquer decisão,
  /// qualquer álbum) — usado pelo `SyncService` para diferenciar itens
  /// novos de já conhecidos (2.5.4) sem reconstruir a entidade inteira.
  Future<Set<int>> indexedMediaStoreIds();

  /// 5.5.6 — item ausente da varredura que também não está retido na
  /// lixeira do sistema (checado via canal nativo, 2.1.5) nem foi
  /// purgado de lá — ainda ambíguo entre órfão de verdade e volume
  /// desmontado, então marca `isAvailable` false em vez de excluir;
  /// reversível se o item reaparecer.
  Future<void> markUnavailable(Set<int> mediaStoreIds);

  /// 3.6.1 — confirmação de `createTrashRequest` com `RESULT_OK`.
  /// Mantém `decision`, `albumId` e demais campos intactos; só marca
  /// `trashedInSystem` true e grava `trashedAt`. Não apaga a linha —
  /// diferente do modo definitivo (`deleteItems`).
  Future<void> markTrashedInSystem(List<String> ids, DateTime at);

  /// `mediaStoreId` de todo item com `trashedInSystem` true — usado
  /// pelo `SyncService` (5.5.1) para não confundir ausência esperada
  /// (item retido, some das consultas normais por definição) com
  /// ausência real (órfão/excluído por fora do app).
  Future<Set<int>> trashedMediaStoreIds();

  /// 3.6.3/5.5.5 — item retido que reaparece na consulta normal do
  /// MediaStore foi restaurado pelo usuário na lixeira do sistema.
  /// Marca `trashedInSystem` false e limpa `trashedAt`, preservando
  /// decisão e álbum — não é tratado como item novo.
  Future<void> restoreFromSystemTrash(Set<int> mediaStoreIds);

  /// 5.5.2/5.5.3 — retido na lixeira do sistema por fora deste app
  /// (outro app, Fotos do sistema) — descoberto via canal nativo
  /// (2.1.5), não pelo fluxo próprio de `moveToSystemTrash`/
  /// [markTrashedInSystem]. Mesmo efeito daquele, mas indexado por
  /// `mediaStoreId` porque o `SyncService` não tem o `id` local aqui.
  Future<void> markTrashedInSystemByMediaStoreId(
    Set<int> mediaStoreIds,
    DateTime at,
  );

  /// 5.5.4 — item que estava retido na lixeira do sistema e não está
  /// mais lá (canal nativo, 2.1.5) nem voltou a aparecer na varredura
  /// normal: foi purgado de verdade (expirou os 30 dias, ou a lixeira
  /// foi esvaziada por fora do app). Remove a linha — diferente de
  /// [markUnavailable], que preserva o registro por ser um caso
  /// ambíguo.
  Future<void> deleteByMediaStoreIds(Set<int> mediaStoreIds);

  /// 5.4.1 — restaura todo item com `decision naLixeira` e
  /// `trashedInSystem` false a partir de `preQueueDecision`/
  /// `preQueueAlbumId`. Chamado na inicialização, antes do Dashboard
  /// abrir (5.4.2) — garante o invariante de 3.5.2 ("a fila não
  /// sobrevive à saída da categoria") mesmo quando o app foi encerrado
  /// pelo Android sem passar pelo diálogo de saída (3.5.3/3.5.4).
  Future<void> restorePendingQueueItems();

  Future<List<AlbumEntity>> albums();

  /// Valida 6.5.3 (nome único case-insensitive, ≤64 caracteres,
  /// caracteres proibidos) antes de inserir.
  Future<AlbumEntity> createAlbum(String name);

  /// 6.5.4 — renomeia, sem afetar os vínculos existentes. Mesmas
  /// regras de nome de [createAlbum] (6.5.3), excluindo o próprio
  /// álbum da checagem de duplicidade. 6.5.7 — pasta real: marca
  /// `albumMovePending` em todo item já vinculado, pro `AlbumMoveService`
  /// mover fisicamente pro nome novo no próximo lote confirmado.
  Future<AlbumEntity> renameAlbum(String albumId, String newName);

  /// 6.5.8 — importa uma pasta já existente no sistema (descoberta via
  /// `MediaRepository.discoverMediaFolders`, ex.: "DCIM/Camera/") como
  /// álbum selecionável, gravando [relativePath] explícito em vez da
  /// convenção padrão `Pictures/<nome>/` (6.5.7). O nome exibido é o
  /// último segmento do caminho (ex.: "Camera"); mesmas regras de nome
  /// de [createAlbum] (6.5.3) — pode lançar `AlbumNameException` se
  /// colidir com um álbum já existente. Não vincula nenhum item
  /// retroativamente: a pasta só passa a ser uma opção de destino,
  /// igual a qualquer outro álbum.
  Future<AlbumEntity> importAlbumFromFolder(String relativePath);

  /// Espelha uma pasta real do sistema (descoberta via
  /// `MediaRepository.discoverMediaFolders`) como álbum do app --
  /// reaproveita um álbum já existente com o mesmo `relativePath`
  /// (manual ou espelhado numa sincronização anterior) em vez de
  /// duplicar. Sempre cria/reaproveita o álbum; só vincula
  /// retroativamente (mantido + classificado) os itens ainda não
  /// decididos que já estão fisicamente nele quando a pasta NÃO é uma
  /// categoria automática da galeria (Câmera padrão, Screenshots --
  /// "onde a mídia cai sozinha", não uma organização deliberada, e
  /// fazer isso ali esvaziaria o propósito da triagem, 3.1/3.2, já que
  /// é onde mora a maioria das fotos de um aparelho normal). Qualquer
  /// outra pasta (WhatsApp Images, Instagram, um álbum que o usuário já
  /// organizou pela Galeria do sistema etc.) É vinculada: representa
  /// uma classificação que o usuário já fez fora do app, e espelhar
  /// isso como mantido/classificado reconhece essa decisão em vez de
  /// pular a triagem. Nunca sobrescreve uma decisão já tomada dentro do
  /// app (item já mantido sem álbum, excluído, ou classificado noutro
  /// álbum fica intocado). Mesmo nas pastas automáticas,
  /// `itemsForCategory`/`categoriesFor` (granularidade álbum) mostram
  /// os itens que já moram fisicamente ali por localização, sem
  /// `albumId` — a categoria aparece com contagem real, aberta pra
  /// triagem normal, sem nada pré-decidido. Chamado pelo `SyncService`
  /// a cada sincronização, não pela UI. Retorna quantos itens foram
  /// vinculados nesta chamada (0 se a pasta é automática, ou se já não
  /// sobrou item pra vincular).
  Future<int> mirrorSystemFolder(String relativePath);

  /// 6.5.5/6.5.6 — exclui o álbum. Os itens vinculados passam a
  /// `albumId` null, preservando `decision` (mantido não muda). A
  /// contagem de itens afetados (pro diálogo de confirmação) vem de
  /// [albumItemCounts], lida antes de chamar isto. 6.5.7 — pasta real:
  /// nenhum arquivo é tocado aqui, mas todo item que já tinha sido
  /// movido pra pasta do álbum é marcado `albumMovePending`, pro
  /// `AlbumMoveService` devolvê-lo pra `preAlbumRelativePath` no
  /// próximo lote confirmado.
  Future<void> deleteAlbum(String albumId);

  /// Remove as linhas de verdade — só o modo definitivo chama isto
  /// (4.4.4); o modo lixeira usa [markTrashedInSystem], que preserva a
  /// linha (3.6.1).
  Future<void> deleteItems(List<String> ids);

  /// 6.5.7 — todo item com `albumMovePending` true, em qualquer
  /// categoria (o movimento físico não é escopado por sessão de
  /// triagem, diferente da fila de exclusão). Usado pelo
  /// `AlbumMoveService` pra montar o lote confirmado no fim da sessão.
  Future<List<MediaItemEntity>> itemsPendingAlbumMove();

  /// 6.5.7 — grava o resultado de um lote de movimentos físicos bem
  /// sucedidos (entidades já transitadas via
  /// [MediaItemEntity.applyAlbumMove]). Só os itens realmente movidos
  /// entram aqui — os que falharam continuam `albumMovePending` true,
  /// pro próximo lote tentar de novo.
  Future<void> applyAlbumMoveOutcome(List<MediaItemEntity> movedItems);
}
