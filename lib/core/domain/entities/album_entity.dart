/// Album (2.2.2). Versão mínima: sem `externalRef` ainda, já que
/// estágios 2 e 3 (1.3.2/1.3.3) não existem nesta fase mockada.
class AlbumEntity {
  const AlbumEntity({
    required this.id,
    required this.name,
    required this.createdAt,
    this.relativePath,
  });

  final String id;
  final String name;
  final DateTime createdAt;

  /// 6.5.8 — pasta real explícita (com barra no final), só presente em
  /// álbuns importados de uma pasta já existente no sistema (Câmera,
  /// WhatsApp Images etc.), cujo destino não segue a convenção padrão.
  /// `null` nos álbuns criados no app (6.5.7) — a pasta é derivada do
  /// nome via [effectiveRelativePath].
  final String? relativePath;

  /// Pasta física de verdade usada pelo `AlbumMoveService` (6.5.7):
  /// [relativePath] quando explícito (álbum importado), ou a convenção
  /// padrão `Pictures/<nome>/` para álbuns criados no app.
  String get effectiveRelativePath => relativePath ?? 'Pictures/$name/';
}