/// 6.5.7 — resultado de um lote confirmado pelo `AlbumMoveService`.
class AlbumMoveResult {
  const AlbumMoveResult({required this.movedCount, required this.failedCount});

  final int movedCount;
  final int failedCount;

  bool get hasFailures => failedCount > 0;

  bool get isEmpty => movedCount == 0 && failedCount == 0;
}
