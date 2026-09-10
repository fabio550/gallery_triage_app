import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gallery_triage_app/core/application/providers/albums_provider.dart';
import 'package:gallery_triage_app/core/domain/entities/media_item_entity.dart';
import 'package:gallery_triage_app/core/domain/enums/triage_decision.dart';

/// 6.2.11 — "Modal rolável com tamanho, extensão, data, caminho e
/// demais metadados."
Future<void> showMediaInfoModal(BuildContext context, MediaItemEntity item) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => _MediaInfoSheet(item: item),
  );
}

class _MediaInfoSheet extends ConsumerWidget {
  const _MediaInfoSheet({required this.item});

  final MediaItemEntity item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final albums = ref.watch(albumsProvider);
    String? albumName;
    for (final album in albums) {
      if (album.id == item.albumId) {
        albumName = album.name;
        break;
      }
    }

    final rows = <MapEntry<String, String>>[
      MapEntry(
        'Tamanho',
        '${(item.sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB',
      ),
      MapEntry('Extensão', item.mimeType),
      MapEntry('Data', _formatDate(item.dateTaken)),
      MapEntry('Caminho', item.relativePath),
      if (item.isVideo && item.durationMs != null)
        MapEntry('Duração', _formatDuration(item.durationMs!)),
      MapEntry('Screenshot', item.isScreenshot ? 'Sim' : 'Não'),
      MapEntry('Decisão', _decisionLabel(item.decision)),
      if (albumName != null) MapEntry('Álbum', albumName),
    ];

    final text = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.6,
          ),
          child: ListView(
            shrinkWrap: true,
            children: [
              Text('Informações', style: text.titleMedium),
              const SizedBox(height: 12),
              for (final row in rows)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 90,
                        child: Text(
                          row.key,
                          style: text.bodyMedium
                              ?.copyWith(color: colors.onSurfaceVariant),
                        ),
                      ),
                      Expanded(
                        child: Text(row.value, style: text.bodyMedium),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

String _formatDate(DateTime d) {
  final day = d.day.toString().padLeft(2, '0');
  final month = d.month.toString().padLeft(2, '0');
  final hour = d.hour.toString().padLeft(2, '0');
  final minute = d.minute.toString().padLeft(2, '0');
  return '$day/$month/${d.year} $hour:$minute';
}

String _formatDuration(int ms) {
  final totalSeconds = ms ~/ 1000;
  final minutes = totalSeconds ~/ 60;
  final seconds = totalSeconds % 60;
  return '$minutes:${seconds.toString().padLeft(2, '0')}';
}

String _decisionLabel(TriageDecision decision) => switch (decision) {
      TriageDecision.undecided => 'Não decidido',
      TriageDecision.kept => 'Mantido',
      TriageDecision.markedForDeletion => 'Na fila de exclusão',
    };