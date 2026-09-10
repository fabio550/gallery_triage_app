import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gallery_triage_app/core/application/providers/deletion_mode_provider.dart';
import 'package:gallery_triage_app/core/domain/entities/media_item_entity.dart';
import 'package:gallery_triage_app/core/domain/enums/deletion_mode.dart';
import 'package:gallery_triage_app/core/domain/models/category_summary.dart';
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
            // TODO Etapa 7b concluída: diálogo de confirmação (6.3.5) +
            // execução simulada (6.3.6/6.3.7, 6.4). O diálogo real do
            // sistema (4.3) continua fora de escopo — não há
            // MethodChannel ainda.
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

    ref.read(deletionModeProvider.notifier).set(confirmedMode);
    ref
        .read(triageSessionProvider(widget.categoryRef).notifier)
        .confirmDeletion(selected.map((i) => i.id).toList(), confirmedMode);

    // 6.4.1 — texto condicionado ao modo (4.4.5). Quem exibe é o
    // TriagePage: 6.4.5 manda voltar pra lá, então o resumo não faz
    // sentido aparecer numa tela que já está fechando.
    final message = confirmedMode == DeletionMode.trash
        ? '${selected.length} itens movidos para a lixeira do sistema '
            '(retidos por cerca de 30 dias).'
        : '${selected.length} itens excluídos — '
            '${(totalSize / (1024 * 1024)).toStringAsFixed(0)} MB liberados.';

    if (!mounted) return;
    Navigator.of(context).pop(message);
  }
}