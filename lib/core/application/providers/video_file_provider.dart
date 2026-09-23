import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gallery_triage_app/core/application/providers/media_repository_provider.dart';

/// Caminho do arquivo local de um vídeo (6.2.17) — resolvido uma vez
/// por item, reaproveitado enquanto o `VideoPreview` correspondente
/// estiver montado. `autoDispose`: sem cache dedicado, o card ativo é
/// o único observador (o preview do próximo item foi removido).
final videoFilePathProvider =
    FutureProvider.autoDispose.family<String?, int>((ref, mediaStoreId) {
  return ref.watch(mediaRepositoryProvider).videoFilePath(mediaStoreId);
});
