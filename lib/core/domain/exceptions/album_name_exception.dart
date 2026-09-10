/// Nome de álbum inválido ou duplicado (7 — "erro inline no campo, sem
/// fechar o diálogo"). Regras de 6.5.3.
class AlbumNameException implements Exception {
  const AlbumNameException(this.message);
  final String message;
}