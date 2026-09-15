import '../entities/album_entity.dart';
import '../entities/media_item_entity.dart';
import '../enums/category_granularity.dart';
import '../models/category_summary.dart';

/// Leitura e escrita de decisão, álbum e fila de exclusão (2.4.2), mais
/// as consultas agregadas do Dashboard (6.1) e o ponto de escrita do
/// `SyncService` (5.2/5.3). Implementação concreta (Drift) vive na
/// camada `data`.
abstract class TriageRepository {
  /// Itens contáveis (6.1.10) do recorte. Sem paginação ainda — o
  /// volume real (8.1) ainda não exigiu (8.4).
  Future<List<MediaItemEntity>> itemsForCategory(CategoryRef ref);

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

  /// 5.5.6 — item ausente da varredura, mas sem confirmação de que é
  /// órfão de verdade (sem o canal nativo de 5.5.2 ainda não dá pra
  /// distinguir de retido na lixeira do sistema). Marca `isAvailable`
  /// false em vez de excluir — reversível se o item reaparecer.
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

  Future<List<AlbumEntity>> albums();

  /// Valida 6.5.3 (nome único case-insensitive, ≤64 caracteres,
  /// caracteres proibidos) antes de inserir.
  Future<AlbumEntity> createAlbum(String name);

  /// Remove as linhas de verdade, nos dois modos (lixeira ou
  /// definitivo). Reproduz a simplificação já documentada em
  /// `confirmDeletion` do notifier (sem simular retenção de 30 dias) —
  /// diverge do modelo final de 3.6, onde o modo lixeira deveria só
  /// marcar `trashedInSystem`, não apagar a linha. Revisitar quando o
  /// MethodChannel real existir.
  Future<void> deleteItems(List<String> ids);
}
