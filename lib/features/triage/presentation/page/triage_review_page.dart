import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gallery_triage_app/core/application/providers/deletion_mode_provider.dart';
import 'package:gallery_triage_app/core/domain/entities/media_item_entity.dart';
import 'package:gallery_triage_app/core/domain/enums/deletion_mode.dart';
import 'package:gallery_triage_app/core/domain/models/category_summary.dart';
import 'package:gallery_triage_app/features/triage/application/deletion_outcome.dart';
import 'package:gallery_triage_app/features/triage/application/triage_session_notifier.dart';
import 'package:gallery_triage_app/features/triage/presentation/widgets/queue_grid_tile.dart';

/// 6.3 — itens com `decision == naLixeira` na categoria ativa.
/// Acessível só pelo ícone da AppBar da Triagem (6.2.1).
///
/// O roster exibido é um snapshot capturado na abertura (`initState`),
/// não uma consulta ao vivo: alternar um item individualmente (6.3.4)
/// não pode fazê-lo sumir da tela, senão "Marcar Todas" não teria como
/// remarcá-lo depois.
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

  @override
  void initState() {
    super.initState();
    final session = ref.read(triageSessionProvider(widget.categoryRef));
    _queueSnapshot = session.items
        .where((i) => i.isInDeletionQueue)
        .map((i) => i.id)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(triageSessionProvider(widget.categoryRef));
    final notifier =
        ref.read(triageSessionProvider(widget.categoryRef).notifier);

    final byId = {for (final i in session.items) i.id: i};
    final items = _queueSnapshot
        .map((id) => byId[id])
        .whereType<MediaItemEntity>()
        .toList();

    final selected = items.where((i) => i.isInDeletionQueue).toList();
    final selectedSize = selected.fold<int>(0, (sum, i) => sum + i.sizeBytes);

    return Scaffold(
      appBar: AppBar(
        title: Text('Revisão — ${widget.categoryLabel}'),
        actions: [
          TextButton(
            onPressed: () => notifier.markAllInQueue(_queueSnapshot),
            child: const Text('Marcar Todas'),
          ),
          TextButton(
            onPressed: () => notifier.unmarkAllInQueue(_queueSnapshot),
            child: const Text('Desmarcar Todas'),
          ),
        ],
      ),
      body: items.isEmpty
          ? const Center(child: Text('Nada para revisar.'))
          : GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return QueueGridTile(
                  item: item,
                  onTap: () => notifier.toggleQueueMembership(item.id),
                );
              },
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton.icon(
            icon: const Icon(Icons.delete_outline),
            label: Text(
              selected.isEmpty
                  ? 'Excluir Selecionadas'
                  : 'Excluir Selecionadas (${selected.length} · '
                      '${(selectedSize / (1024 * 1024)).toStringAsFixed(0)} MB)',
            ),
            // Diálogo de confirmação do app (6.3.5), seguido do
            // diálogo real do sistema (4.3, via MediaRepository) —
            // sequência de 6.3.6.
            onPressed: selected.isEmpty
                ? null
                : () => _confirmDeletion(selected),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDeletion(List<MediaItemEntity> selected) async {
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

    if (confirmedMode == null || !mounted) return;

    // 4.4.2 — a escolha do modo em si já vale, independente do que o
    // diálogo do sistema (a seguir) decidir.
    ref.read(deletionModeProvider.notifier).set(confirmedMode);

    final sessionNotifier =
        ref.read(triageSessionProvider(widget.categoryRef).notifier);
    final outcome = await sessionNotifier.confirmDeletion(
      selected.map((i) => i.id).toList(),
      confirmedMode,
    );

    if (!mounted) return;

    if (outcome == DeletionOutcome.cancelled) {
      // 4.3.6 — aviso não bloqueante; fila preservada, permanece aqui.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nada foi excluído.')),
      );
      return;
    }

    // 6.4.1 — texto condicionado ao modo (4.4.5), fonte única em
    // DeletionSummary.text; usa o resumo real (itens efetivamente
    // processados, não os selecionados — §7, exclusão parcial). Quem
    // exibe é o TriagePage: 6.4.5 manda voltar pra lá.
    final summary =
        ref.read(triageSessionProvider(widget.categoryRef)).lastDeletionSummary;
    final message = outcome == DeletionOutcome.partial
        ? '${summary?.text ?? ''} Alguns itens não foram processados e '
            'permanecem na fila.'
        : summary?.text;

    Navigator.of(context).pop(message);
  }
}