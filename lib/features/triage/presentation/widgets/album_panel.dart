import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gallery_triage_app/core/application/providers/albums_provider.dart';
import 'package:gallery_triage_app/core/application/providers/categories_provider.dart';
import 'package:gallery_triage_app/core/domain/entities/album_entity.dart';
import 'package:gallery_triage_app/core/domain/exceptions/album_name_exception.dart';
import 'package:gallery_triage_app/core/presentation/widgets/media_placeholder.dart';

/// Bottom sheet de 6.2.16. Devolve o id do álbum escolhido (existente
/// ou recém-criado) via `Navigator.pop`, ou `null` se fechado sem
/// seleção. Quem chama decide o que fazer com o id — este widget não
/// conhece `TriageSessionNotifier`.
Future<String?> showAlbumPanel(BuildContext context, {String? currentAlbumId}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    builder: (_) => AlbumPanel(currentAlbumId: currentAlbumId),
  );
}

class AlbumPanel extends ConsumerStatefulWidget {
  const AlbumPanel({required this.currentAlbumId, super.key});

  final String? currentAlbumId;

  @override
  ConsumerState<AlbumPanel> createState() => _AlbumPanelState();
}

class _AlbumPanelState extends ConsumerState<AlbumPanel> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// 6.2.16 — com itens por contagem decrescente, depois vazios em
  /// ordem alfabética.
  List<AlbumEntity> _ordered(List<AlbumEntity> albums, Map<String, int> counts) {
    final filtered = _query.isEmpty
        ? albums
        : albums
            .where((a) => a.name.toLowerCase().contains(_query.toLowerCase()))
            .toList();

    final withItems = filtered.where((a) => (counts[a.id] ?? 0) > 0).toList()
      ..sort((a, b) {
        final byCount = (counts[b.id] ?? 0).compareTo(counts[a.id] ?? 0);
        return byCount != 0 ? byCount : a.name.compareTo(b.name);
      });
    final empty = filtered.where((a) => (counts[a.id] ?? 0) == 0).toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    return [...withItems, ...empty];
  }

  @override
  Widget build(BuildContext context) {
    final albums = ref.watch(albumsProvider);
    // Riverpod 3.x: `.value` já é nullable, cumpre o papel do antigo
    // `valueOrNull` — enquanto carrega, o painel mostra os álbuns com
    // contagem 0 em vez de travar numa tela de loading.
    final counts = ref.watch(albumItemCountsProvider).value ?? const {};
    final ordered = _ordered(albums, counts);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          // Sobe o painel acima do teclado ao focar a busca.
          bottom: 16 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _query = value),
              decoration: const InputDecoration(
                hintText: 'Buscar álbum',
                prefixIcon: Icon(Icons.search),
                isDense: true,
              ),
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.5,
              ),
              child: ListView(
                shrinkWrap: true,
                children: [
                  // Primeiro item da lista, sempre — mesmo com busca
                  // ativa e álbuns vazios (7 — "estado vazio, primeira
                  // sessão: apenas Criar Álbum").
                  ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.add)),
                    title: const Text('Criar Álbum'),
                    onTap: () => _createAlbum(context),
                  ),
                  for (final album in ordered)
                    ListTile(
                      leading: CircleAvatar(
                        backgroundColor: mediaPlaceholderColor(album.id),
                      ),
                      title: Text(album.name),
                      trailing: Text('${counts[album.id] ?? 0}'),
                      selected: album.id == widget.currentAlbumId,
                      onTap: () => Navigator.of(context).pop(album.id),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createAlbum(BuildContext sheetContext) async {
    final nameController = TextEditingController();
    String? errorText;

    final createdId = await showDialog<String>(
      context: sheetContext,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('Criar álbum'),
          content: TextField(
            controller: nameController,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Nome do álbum',
              errorText: errorText,
            ),
            // Erro inline, sem fechar o diálogo (7).
            onSubmitted: (_) => setDialogState(() {}),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () async {
                try {
                  final id = await ref
                      .read(albumsProvider.notifier)
                      .create(nameController.text);
                  if (dialogContext.mounted) {
                    Navigator.of(dialogContext).pop(id);
                  }
                } on AlbumNameException catch (e) {
                  setDialogState(() => errorText = e.message);
                }
              },
              child: const Text('Criar'),
            ),
          ],
        ),
      ),
    );

    if (createdId != null && sheetContext.mounted) {
      // Fecha o painel inteiro com o id do álbum recém-criado — quem
      // chamou showAlbumPanel trata os dois casos (existente ou novo)
      // do mesmo jeito.
      Navigator.of(sheetContext).pop(createdId);
    }
  }
}