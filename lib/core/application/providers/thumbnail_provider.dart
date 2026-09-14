import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gallery_triage_app/core/application/providers/media_repository_provider.dart';

/// Miniatura real (8.5) por `mediaStoreId` + tamanho — chave composta
/// porque o carrossel/capas (200x200) e o card principal (maior,
/// 6.2.8) pedem resoluções diferentes do mesmo item. `autoDispose`:
/// sem cache LRU dedicado ainda (8.5 documenta um, ficou pra depois),
/// o cache do Riverpod + o cache de disco do `photo_manager` cobrem o
/// caso comum.
final thumbnailProvider =
    FutureProvider.autoDispose.family<Uint8List?, (int mediaStoreId, int size)>(
  (ref, key) {
    final (mediaStoreId, size) = key;
    return ref
        .watch(mediaRepositoryProvider)
        .readThumbnail(mediaStoreId, size: size);
  },
);
