import '../enums/deletion_mode.dart';
import '../enums/sort_order.dart';
import '../models/category_summary.dart';

/// Estado global do app, fora do índice de mídia (2.6). Perdê-lo
/// degrada a ergonomia, não o trabalho de triagem acumulado (2.6.1) —
/// ao contrário do `TriageRepository`, cuja perda é irrecuperável.
/// Implementação concreta (Drift) vive na camada `data`.
abstract class PreferencesRepository {
  /// 6.2.3 — ordenação cronológica da Tela de Triagem. Global,
  /// atravessa categorias e sessões. Padrão: mais recente primeiro.
  Future<SortOrder> sortOrder();
  Future<void> setSortOrder(SortOrder order);

  /// 4.4.2 — última escolha no diálogo de confirmação da Tela de
  /// Revisão, pré-selecionada na próxima. Padrão: lixeira do sistema
  /// (opção reversível, antes de existir qualquer escolha do usuário).
  Future<DeletionMode> deletionMode();
  Future<void> setDeletionMode(DeletionMode mode);

  /// 6.2.18 — arma o atalho de swipe para cima. `null` = pílula não
  /// renderizada, gesto inerte. Escopo global, não por categoria
  /// (2.6.2: quem tria Agosto e depois Julho tende a usar os mesmos
  /// álbuns).
  Future<String?> lastUsedAlbumId();
  Future<void> setLastUsedAlbumId(String? albumId);

  /// 6.2.4 — última posição da sessão anterior naquela categoria,
  /// gravada como o id do item. `null` = sem posição registrada (cai no
  /// fallback: primeiro item não decidido, ou primeiro item).
  Future<String?> cursorPosition(CategoryRef ref);
  Future<void> setCursorPosition(CategoryRef ref, String itemId);

  /// 5.3.6 — geração usada pelo caminho preferencial da sincronização
  /// incremental (`MediaStore.getGeneration`, 5.3.2). `null` em ambos =
  /// nunca sincronizou.
  Future<DateTime?> lastSyncAt();
  Future<int?> lastGeneration();
  Future<void> setLastSync({required DateTime at, required int generation});

  /// 5.2.4 — offset processado do primeiro scan, para retomar após
  /// encerramento do app. Só existe durante o primeiro scan; `null`
  /// fora dele.
  Future<int?> scanOffset();
  Future<void> setScanOffset(int? offset);
}
