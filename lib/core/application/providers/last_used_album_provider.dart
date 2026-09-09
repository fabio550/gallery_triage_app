import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 2.6 — preferência global, fora do índice de mídia. Sobrevive entre
/// categorias e sessões (2.6.2: "não é por categoria. Quem tria Agosto
/// e depois Julho tende a usar os mesmos álbuns").
///
/// Em memória por enquanto — 2.6 documenta isto como
/// `shared_preferences`/Drift, que ainda não existem no projeto. Igual
/// ao resto do estado mockado, perde-se ao fechar o app; isso é uma
/// perda aceitável de ergonomia (2.6.1), não de triagem.
final lastUsedAlbumProvider =
    NotifierProvider<LastUsedAlbumNotifier, String?>(
  LastUsedAlbumNotifier.new,
);

class LastUsedAlbumNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void set(String albumId) => state = albumId;

  /// 2.6.3 — se o álbum referenciado for excluído (6.5.5), a chave é
  /// limpa e o atalho de swipe para cima fica inerte até a próxima
  /// classificação. Sem chamador ainda: depende da tela de gestão de
  /// álbuns (6.5.2 / P-08), que não existe.
  void clearIfMatches(String albumId) {
    if (state == albumId) state = null;
  }
}