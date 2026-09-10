import '../entities/album_entity.dart';
import '../entities/media_item_entity.dart';
import '../models/category_summary.dart';

/// Leitura e escrita de decisão, álbum e fila de exclusão (2.4.2).
/// Implementação concreta (Drift) vive na camada `data`.
///
/// `summaryFor`/enumeração de categorias por granularidade ficam para a
/// etapa seguinte, junto da troca de `mock_categories.dart` — dependem
/// de rótulo formatado por locale, que não é responsabilidade daqui
/// (ver comentário em `CategorySummary.label`).
abstract class TriageRepository {
  /// Itens contáveis (6.1.10) do recorte. Sem paginação ainda — mesmo
  /// comportamento de `MockMediaItems.forCategory` hoje; paginação
  /// (8.4) fica para quando o volume real (8.1) exigir.
  Future<List<MediaItemEntity>> itemsForCategory(CategoryRef ref);

  /// Upsert genérico — grava a entidade inteira, não campos
  /// individuais. Chamado a cada transição de domínio (write-through).
  Future<void> updateItem(MediaItemEntity item);

  Future<List<AlbumEntity>> albums();

  /// Valida 6.5.3 (nome único case-insensitive, ≤64 caracteres,
  /// caracteres proibidos) antes de inserir.
  Future<AlbumEntity> createAlbum(String name);

  /// Popula com o dataset mockado na primeira leitura, se a tabela
  /// estiver vazia. Espelha "primeiro scan" (5.2) com o mock como
  /// fonte em vez do MediaStore.
  Future<void> seedIfEmpty();

  /// Remove as linhas de verdade, nos dois modos (lixeira ou
  /// definitivo). Reproduz a simplificação já documentada em
  /// `confirmDeletion` do notifier (sem simular retenção de 30 dias) —
  /// diverge do modelo final de 3.6, onde o modo lixeira deveria só
  /// marcar `trashedInSystem`, não apagar a linha. Revisitar quando o
  /// MethodChannel real existir.
  Future<void> deleteItems(List<String> ids);
}