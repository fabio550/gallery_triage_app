import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gallery_triage_app/core/application/providers/album_move_service_provider.dart';
import 'package:gallery_triage_app/core/application/providers/deletion_mode_provider.dart';
import 'package:gallery_triage_app/core/domain/entities/media_item_entity.dart';
import 'package:gallery_triage_app/core/domain/enums/deletion_mode.dart';
import 'package:gallery_triage_app/core/domain/models/category_summary.dart';
import 'package:gallery_triage_app/features/triage/application/deletion_outcome.dart';
import 'package:gallery_triage_app/features/triage/application/triage_session_notifier.dart';
import 'package:gallery_triage_app/features/triage/presentation/widgets/album_move_grid_tile.dart';
import 'package:gallery_triage_app/features/triage/presentation/widgets/queue_grid_tile.dart';

/// 6.3/6.5.7 — revisão unificada de tudo que pede confirmação antes de
/// mexer de verdade nos arquivos: fila de exclusão (decision ==
/// naLixeira, escopada à categoria ativa) e movimentos de álbum
/// pendentes (albumMovePending, globais — qualquer categoria, não só
/// esta). Um diálogo do sistema por ação, mas um só ponto de revisão —
/// não dois fluxos separados que o usuário precisa achar em lugares
/// diferentes.
///
/// O roster de exclusão é um snapshot capturado na abertura
/// (`initState`): alternar um item individualmente (6.3.4) não pode
/// fazê-lo sumir da tela, senão "Marcar Todas" não teria como
/// remarcá-lo depois. O de álbum segue o mesmo princípio (carregado
/// uma vez), mas a seleção ali é só local a esta tela — excluir um
/// item da confirmação não desclassifica nada, só adia o movimento
/// físico pra próxima revisão.
class TriageReviewPage extends ConsumerStatefulWidget {
  const TriageReviewPage({
    required this.categoryRef,
    required this.categoryLabel,
    super.key,
  });

  final CategoryRef categoryRef;
  final String categoryLabel;

  @override
  ConsumerState<TriageReviewPage> createState() => _TriageReviewPageState();
}

class _TriageReviewPageState extends ConsumerState<TriageReviewPage> {
  late final List<String> _queueSnapshot;

  List<MediaItemEntity> _albumMoveSnapshot = const [];
  Set<String> _albumSelected = {};
  bool _loadingAlbumMoves = true;

  @override
  void initState() {
    super.initState();
    final session = ref.read(triageSessionProvider(widget.categoryRef));
    _queueSnapshot = session.items
        .where((i) => i.isInDeletionQueue)
        .map((i) => i.id)
        .toList();
    _loadAlbumMoves();
  }

  Future<void> _loadAlbumMoves() async {
    final pending = await ref.read(albumMoveServiceProvider).pendingItems();
    if (!mounted) return;
    setState(() {
      _albumMoveSnapshot = pending;
      _albumSelected = pending.map((i) => i.id).toSet();
      _loadingAlbumMoves = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(triageSessionProvider(widget.categoryRef));
    final notifier =
        ref.read(triageSessionProvider(widget.categoryRef).notifier);

    final byId = {for (final i in session.items) i.id: i};
    final queueItems = _queueSnapshot
        .map((id) => byId[id])
        .whereType<MediaItemEntity>()
        .toList();

    final selectedDeletion =
        queueItems.where((i) => i.isInDeletionQueue).toList();
    final selectedDeletionBytes =
        selectedDeletion.fold<int>(0, (sum, i) => sum + i.sizeBytes);

    final selectedAlbum = _albumMoveSnapshot
        .where((i) => _albumSelected.contains(i.id))
        .toList();

    final nothingToReview =
        queueItems.isEmpty && !_loadingAlbumMoves && _albumMoveSnapshot.isEmpty;

    return Scaffold(
      appBar: AppBar(title: Text('Revisão — ${widget.categoryLabel}')),
      body: nothingToReview
          ? const Center(child: Text('Nada para revisar.'))
          : ListView(
              padding: const EdgeInsets.all(12),
              children: [
                if (queueItems.isNotEmpty) ...[
                  _SectionHeader(
                    title: 'Pra excluir (${queueItems.length})',
                    onSelectAll: () => notifier.markAllInQueue(_queueSnapshot),
                    onSelectNone: () =>
                        notifier.unmarkAllInQueue(_queueSnapshot),
                    selectAllLabel: 'Marcar Todas',
                    selectNoneLabel: 'Desmarcar Todas',
                  ),
                  const SizedBox(height: 8),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: queueItems.length,
                    itemBuilder: (context, index) {
                      final item = queueItems[index];
                      return QueueGridTile(
                        item: item,
                        onTap: () => notifier.toggleQueueMembership(item.id),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                ],
                if (_loadingAlbumMoves)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_albumMoveSnapshot.isNotEmpty) ...[
                  _SectionHeader(
                    title: 'Pra mover de álbum (${_albumMoveSnapshot.length})',
                    onSelectAll: () => setState(
                      () => _albumSelected =
                          _albumMoveSnapshot.map((i) => i.id).toSet(),
                    ),
                    onSelectNone: () => setState(() => _albumSelected = {}),
                    selectAllLabel: 'Mover Todas',
                    selectNoneLabel: 'Não Mover Nenhuma',
                  ),
                  const SizedBox(height: 8),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: _albumMoveSnapshot.length,
                    itemBuilder: (context, index) {
                      final item = _albumMoveSnapshot[index];
                      final isSelected = _albumSelected.contains(item.id);
                      return AlbumMoveGridTile(
                        item: item,
                        selected: isSelected,
                        onTap: () => setState(() {
                          if (isSelected) {
                            _albumSelected.remove(item.id);
                          } else {
                            _albumSelected.add(item.id);
                          }
                        }),
                      );
                    },
                  ),
                ],
              ],
            ),
      bottomNavigationBar: nothingToReview
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: FilledButton(
                  onPressed: selectedDeletion.isEmpty && selectedAlbum.isEmpty
                      ? null
                      : () => _confirm(selectedDeletion, selectedAlbum),
                  child: Text(
                    _confirmLabel(
                      selectedDeletion.length,
                      selectedDeletionBytes,
                      selectedAlbum.length,
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  String _confirmLabel(int deletionCount, int deletionBytes, int albumCount) {
    if (deletionCount == 0 && albumCount == 0) return 'Confirmar';
    if (deletionCount > 0 && albumCount > 0) {
      return 'Confirmar ($deletionCount excluir · $albumCount mover)';
    }
    if (deletionCount > 0) {
      final deletionMb = (deletionBytes / (1024 * 1024)).toStringAsFixed(0);
      return 'Excluir Selecionadas ($deletionCount · $deletionMb MB)';
    }
    return 'Mover Selecionados ($albumCount)';
  }

  /// 6.3.5/6.3.6/6.5.7 — as duas ações são independentes: cancelar o
  /// diálogo de modo da exclusão não impede o movimento de álbum de
  /// acontecer, e vice-versa. Cada uma pede seu próprio diálogo do
  /// sistema, em sequência — nunca junta os dois num diálogo só.
  Future<void> _confirm(
    List<MediaItemEntity> selectedDeletion,
    List<MediaItemEntity> selectedAlbum,
  ) async {
    String? deletionMessage;
    if (selectedDeletion.isNotEmpty) {
      deletionMessage = await _runDeletion(selectedDeletion);
      if (!mounted) return;
    }

    String? albumMessage;
    if (selectedAlbum.isNotEmpty) {
      final result = await ref
          .read(albumMoveServiceProvider)
          .confirmPendingMoves(
            onlyItemIds: selectedAlbum.map((i) => i.id).toSet(),
          );
      if (!mounted) return;
      if (result.movedCount > 0 || result.hasFailures) {
        albumMessage = result.hasFailures
            ? '${result.movedCount} movidos pra álbum, '
                '${result.failedCount} não confirmados.'
            : '${result.movedCount} movidos pra álbum.';
      }
    }

    if (!mounted) return;

    final combined =
        [deletionMessage, albumMessage].whereType<String>().join(' ');

    if (combined.isEmpty) {
      // 4.3.6 — os diálogos do sistema envolvidos foram cancelados (ou
      // não havia nada selecionado); nada mudou, permanece aqui.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nada foi confirmado.')),
      );
      return;
    }

    Navigator.of(context).pop(combined);
  }

  /// Diálogo de modo (6.3.5) + diálogo real do sistema (4.3, via
  /// MediaRepository) — sequência de 6.3.6. `null` = cancelado, sem
  /// efeito nenhum.
  Future<String?> _runDeletion(List<MediaItemEntity> selected) async {
    final currentMode = ref.read(deletionModeProvider);
    final totalSize = selected.fold<int>(0, (sum, i) => sum + i.sizeBytes);

    final confirmedMode = await showDialog<DeletionMode>(
      context: context,
      builder: (dialogContext) {
        // Fora do StatefulBuilder de propósito: se estivesse dentro, a
        // seleção voltaria pro padrão a cada toque no radio, já que o
        // builder interno reexecuta a cada setDialogState.
        var selectedMode = currentMode;
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) => AlertDialog(
            title: const Text('Excluir itens'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${selected.length} itens · '
                  '${(totalSize / (1024 * 1024)).toStringAsFixed(0)} MB',
                ),
                const SizedBox(height: 8),
                RadioGroup<DeletionMode>(
                  groupValue: selectedMode,
                  onChanged: (v) => setDialogState(() => selectedMode = v!),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      RadioListTile<DeletionMode>(
                        contentPadding: EdgeInsets.zero,
                        title: Text('Lixeira do sistema'),
                        subtitle: Text('Reversível por cerca de 30 dias.'),
                        value: DeletionMode.trash,
                      ),
                      RadioListTile<DeletionMode>(
                        contentPadding: EdgeInsets.zero,
                        title: Text('Excluir definitivamente'),
                        subtitle: Text('Não pode ser desfeito.'),
                        value: DeletionMode.permanent,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () =>
                    Navigator.of(dialogContext).pop(selectedMode),
                child: const Text('Excluir'),
              ),
            ],
          ),
        );
      },
    );

    if (confirmedMode == null || !mounted) return null;

    // 4.4.2 — a escolha do modo em si já vale, independente do que o
    // diálogo do sistema (a seguir) decidir.
    ref.read(deletionModeProvider.notifier).set(confirmedMode);

    final sessionNotifier =
        ref.read(triageSessionProvider(widget.categoryRef).notifier);
    final outcome = await sessionNotifier.confirmDeletion(
      selected.map((i) => i.id).toList(),
      confirmedMode,
    );

    if (!mounted) return null;
    if (outcome == DeletionOutcome.cancelled) return null;

    // 6.4.1 — texto condicionado ao modo (4.4.5), fonte única em
    // DeletionSummary.text; usa o resumo real (itens efetivamente
    // processados, não os selecionados — §7, exclusão parcial).
    final summary = ref
        .read(triageSessionProvider(widget.categoryRef))
        .lastDeletionSummary;
    return outcome == DeletionOutcome.partial
        ? '${summary?.text ?? ''} Alguns itens não foram processados e '
            'permanecem na fila.'
        : summary?.text;
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.onSelectAll,
    required this.onSelectNone,
    required this.selectAllLabel,
    required this.selectNoneLabel,
  });

  final String title;
  final VoidCallback onSelectAll;
  final VoidCallback onSelectNone;
  final String selectAllLabel;
  final String selectNoneLabel;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Row(
      children: [
        Expanded(child: Text(title, style: text.titleMedium)),
        TextButton(onPressed: onSelectAll, child: Text(selectAllLabel)),
        TextButton(onPressed: onSelectNone, child: Text(selectNoneLabel)),
      ],
    );
  }
}
