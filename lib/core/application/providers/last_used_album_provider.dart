import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gallery_triage_app/core/application/providers/preferences_repository_provider.dart';

/// 2.6 — preferência global, fora do índice de mídia. Sobrevive entre
/// categorias e sessões (2.6.2: "quem tria Agosto e depois Julho tende
/// a usar os mesmos álbuns, então o atalho já nasce armado").
///
/// Persistida em `PreferencesRepository` (Drift); write-through, mesmo
/// padrão do `DeletionModeNotifier` — `build()` retorna `null` de
/// imediato e o valor salvo chega assíncrono, sem bloquear o primeiro
/// frame.
final lastUsedAlbumProvider =
    NotifierProvider<LastUsedAlbumNotifier, String?>(
  LastUsedAlbumNotifier.new,
);

class LastUsedAlbumNotifier extends Notifier<String?> {
  late final _repository = ref.read(preferencesRepositoryProvider);

  @override
  String? build() {
    _load();
    return null;
  }

  Future<void> _load() async {
    final saved = await _repository.lastUsedAlbumId();
    if (ref.mounted && saved != null) state = saved;
  }

  void set(String albumId) {
    state = albumId;
    _persist(albumId);
  }

  /// 2.6.3 — se o álbum referenciado for excluído (6.5.5), a chave é
  /// limpa e o atalho de swipe para cima fica inerte até a próxima
  /// classificação. Sem chamador ainda: depende da tela de gestão de
  /// álbuns (6.5.2 / P-08), que não existe.
  void clearIfMatches(String albumId) {
    if (state != albumId) return;
    state = null;
    _persist(null);
  }

  void _persist(String? albumId) {
    unawaited(
      _repository
          .setLastUsedAlbumId(albumId)
          .catchError((Object e, StackTrace st) {
        debugPrint('PreferencesRepository.setLastUsedAlbumId falhou: $e');
      }),
    );
  }
}
