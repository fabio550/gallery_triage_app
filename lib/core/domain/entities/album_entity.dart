/// Album (2.2.2). Versão mínima: sem `externalRef` ainda, já que
/// estágios 2 e 3 (1.3.2/1.3.3) não existem nesta fase mockada.
class AlbumEntity {
  const AlbumEntity({
    required this.id,
    required this.name,
    required this.createdAt,
  });

  final String id;
  final String name;
  final DateTime createdAt;
}