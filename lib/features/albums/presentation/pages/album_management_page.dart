import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gallery_triage_app/core/application/providers/albums_provider.dart';
import 'package:gallery_triage_app/core/application/providers/categories_provider.dart';
import 'package:gallery_triage_app/core/application/providers/discoverable_albums_provider.dart';
import 'package:gallery_triage_app/core/domain/entities/album_entity.dart';
import 'package:gallery_triage_app/core/domain/exceptions/album_name_exception.dart';

/// 6.5.2 — "Tela dedicada para criar, renomear e excluir álbuns."
/// Criação rápida continua vivendo no painel de álbuns da Triagem
/// (6.5.1/6.2.16); esta tela cobre o que falta: renomear (6.5.4),
/// excluir (6.5.5) e criar fora do fluxo de triagem.
class AlbumManagementPage extends ConsumerWidget {
  const AlbumManagementPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final albums = ref.watch(albumsProvider);
    // Riverpod 3.x: `.value` já é nullable (equivalente ao antigo
    // `valueOrNull`) — enquanto carrega, mostra 0 em vez de travar.
    final counts = ref.watch(albumItemCountsProvider).value ?? const {};
    // 6.5.8 — pastas do sistema com mídia ainda não conhecidas pelo
    // app; `.value` nullable também aqui, some da lista até carregar.
    final discoverable =
        ref.watch(discoverableAlbumsProvider).value ?? const [];

    // Ordem alfabética — mesma convenção da lista de álbuns vazios do
    // painel de triagem (6.2.16); aqui não há distinção por contagem,
    // é uma tela de gestão, não de escolha rápida.
    final sorted = [...albums]..sort((a, b) => a.name.compareTo(b.name));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Álbuns'),
        actions: [
          IconButton(
            tooltip: 'Criar álbum',
            icon: const Icon(Icons.add),
            onPressed: () => _createAlbum(context, ref),
          ),
        ],
      ),
      body: sorted.isEmpty && discoverable.isEmpty
          ? const _EmptyState()
          : ListView(
              children: [
                for (final album in sorted)
                  _albumTile(context, ref, album, counts[album.id] ?? 0),
                if (discoverable.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Álbuns da galeria do sistema'),
                    ),
                  ),
                  for (final folder in discoverable)
                    ListTile(
                      leading: const Icon(Icons.folder_outlined),
                      title: Text(folder.name),
                      subtitle: Text(folder.relativePath),
                      trailing: TextButton(
                        onPressed: () => _importFolder(context, ref, folder),
                        child: const Text('Importar'),
                      ),
                    ),
                ],
              ],
            ),
    );
  }

  Widget _albumTile(
    BuildContext context,
    WidgetRef ref,
    AlbumEntity album,
    int count,
  ) {
    return ListTile(
      title: Text(album.name),
      subtitle: Text(count == 1 ? '1 item' : '$count itens'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Renomear',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => _renameAlbum(context, ref, album),
          ),
          IconButton(
            tooltip: 'Excluir',
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _deleteAlbum(context, ref, album, count),
          ),
        ],
      ),
    );
  }

  /// 6.5.8 — importa sem diálogo (o nome vem do próprio sistema, não
  /// há o que digitar); colisão de nome (`AlbumNameException`, raro)
  /// só avisa por SnackBar, sem campo pra corrigir inline.
  Future<void> _importFolder(
    BuildContext context,
    WidgetRef ref,
    DiscoveredFolder folder,
  ) async {
    try {
      await ref.read(albumsProvider.notifier).importFromFolder(
            folder.relativePath,
          );
    } on AlbumNameException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  Future<void> _createAlbum(BuildContext context, WidgetRef ref) {
    return _showNameDialog(
      context: context,
      title: 'Criar álbum',
      confirmLabel: 'Criar',
      initialName: '',
      onConfirm: (name) => ref.read(albumsProvider.notifier).create(name),
    );
  }

  Future<void> _renameAlbum(
    BuildContext context,
    WidgetRef ref,
    AlbumEntity album,
  ) {
    return _showNameDialog(
      context: context,
      title: 'Renomear álbum',
      confirmLabel: 'Salvar',
      initialName: album.name,
      onConfirm: (name) =>
          ref.read(albumsProvider.notifier).rename(album.id, name),
    );
  }

  /// Diálogo compartilhado por criar e renomear — mesma validação de
  /// nome (6.5.3), erro inline sem fechar o diálogo (§7).
  Future<void> _showNameDialog({
    required BuildContext context,
    required String title,
    required String confirmLabel,
    required String initialName,
    required Future<Object?> Function(String name) onConfirm,
  }) async {
    final controller = TextEditingController(text: initialName);
    String? errorText;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text(title),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Nome do álbum',
              errorText: errorText,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () async {
                try {
                  await onConfirm(controller.text);
                  if (dialogContext.mounted) {
                    Navigator.of(dialogContext).pop();
                  }
                } on AlbumNameException catch (e) {
                  setDialogState(() => errorText = e.message);
                }
              },
              child: Text(confirmLabel),
            ),
          ],
        ),
      ),
    );
  }

  /// 6.5.5 — confirmação mostrando a quantidade de itens vinculados e
  /// alertando que serão desclassificados (6.5.6: `albumId` null,
  /// `decision` mantido intacto). 6.5.7 — nenhum arquivo é apagado, mas
  /// quem já tinha sido movido pra pasta real do álbum volta pra pasta
  /// de origem no próximo lote confirmado (`AlbumMoveService`).
  Future<void> _deleteAlbum(
    BuildContext context,
    WidgetRef ref,
    AlbumEntity album,
    int count,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Excluir "${album.name}"?'),
        content: Text(
          count == 0
              ? 'Este álbum não tem itens vinculados.'
              : '$count ${count == 1 ? 'item ficará' : 'itens ficarão'} sem '
                  'álbum. Eles continuam mantidos na galeria — nenhum '
                  'arquivo é apagado, mas quem já estava na pasta do álbum '
                  'volta pra pasta de origem.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(albumsProvider.notifier).delete(album.id);
    }
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 34),
        child: Text(
          'Nenhum álbum criado ainda. Toque em "+" pra criar um, ou '
          'crie direto ao classificar um item na Triagem.',
          textAlign: TextAlign.center,
          style: text.bodySmall,
        ),
      ),
    );
  }
}
