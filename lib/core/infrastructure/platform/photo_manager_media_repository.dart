import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:gallery_triage_app/core/domain/enums/triage_decision.dart';
import 'package:gallery_triage_app/core/domain/models/media_store_asset.dart';
import 'package:gallery_triage_app/core/domain/repositories/media_repository.dart';
import 'package:photo_manager/photo_manager.dart';

/// Implementação Android via `photo_manager` (2.1.4). O app não tem
/// suporte a iOS (1.2) — sem ramo de plataforma aqui.
class PhotoManagerMediaRepository implements MediaRepository {
  // 2.1.5 — o que `photo_manager` não expõe (itens na lixeira do
  // sistema, inclusive os retidos por fora deste app) sai pelo canal
  // nativo próprio, registrado em `MainActivity.kt`.
  static const _trashChannel = MethodChannel('gallery_triage_app/media_trash');
  @override
  Future<void> ensureReady() async {
    // Handshake com o plugin — a permissão real já foi concedida via
    // MediaPermissionRepository/permission_handler (seção 4) antes de
    // qualquer chamador chegar aqui. Como o SO já concedeu a mesma
    // permissão de runtime que o photo_manager verifica, esta chamada
    // resolve sozinha sem reabrir diálogo — é só o plugin sincronizar
    // seu próprio estado interno antes de aceitar outras chamadas.
    await PhotoManager.requestPermissionExtend();
  }

  @override
  Stream<List<MediaStoreAsset>> scanBatches({
    int batchSize = 500,
    int startPage = 0,
  }) async* {
    final path = await _allAssetsPath();
    if (path == null) return;

    final total = await path.assetCountAsync;
    var page = startPage;

    while (page * batchSize < total) {
      final assets = await path.getAssetListPaged(page: page, size: batchSize);
      if (assets.isEmpty) break;

      yield assets
          // RequestType.common já restringe a foto/vídeo, mas outros
          // tipos podem aparecer em dispositivos que ignoram o filtro
          // — descarta defensivamente em vez de deixar o mapeamento
          // falhar (§7).
          .where((a) => a.type == AssetType.image || a.type == AssetType.video)
          .map(_toStoreAsset)
          .toList();

      page++;
    }
  }

  /// A pseudo-pasta "tudo" do dispositivo (`onlyAll`) — o escopo de 5.1
  /// (DCIM + Pictures/Screenshots) é aplicado depois, por
  /// `relativePath`, porque photo_manager não expõe um filtro nativo
  /// por pasta relativa.
  Future<AssetPathEntity?> _allAssetsPath() async {
    final paths = await PhotoManager.getAssetPathList(
      hasAll: true,
      onlyAll: true,
      type: RequestType.common,
    );
    return paths.isEmpty ? null : paths.first;
  }

  MediaStoreAsset _toStoreAsset(AssetEntity asset) {
    final relativePath = asset.relativePath ?? '';
    final isVideo = asset.type == AssetType.video;

    return MediaStoreAsset(
      // Android: `AssetEntity.id` é o `_id` do MediaStore em string
      // (documentado no próprio pacote) — é seguro reconverter pra int.
      mediaStoreId: int.parse(asset.id),
      fileName: asset.title ?? asset.id,
      dateTaken: asset.createDateTime,
      mimeType: asset.mimeType ?? (isVideo ? 'video/mp4' : 'image/jpeg'),
      relativePath: relativePath,
      mediaType: isVideo ? MediaType.video : MediaType.image,
      // 6.1.9/5.1.2 — cobre tanto Pictures/Screenshots (escopo padrão)
      // quanto DCIM/Screenshots (alguns fabricantes).
      isScreenshot: relativePath.toLowerCase().contains('screenshot'),
      durationMs: isVideo ? asset.duration * 1000 : null,
    );
  }

  @override
  Future<int> readSizeBytes(int mediaStoreId) async {
    final asset = await AssetEntity.fromId(mediaStoreId.toString());
    if (asset == null) return 0;
    return asset.fileSize;
  }

  @override
  Future<Uint8List?> readThumbnail(int mediaStoreId, {required int size}) async {
    final asset = await AssetEntity.fromId(mediaStoreId.toString());
    if (asset == null) return null;
    try {
      return await asset.thumbnailDataWithSize(ThumbnailSize.square(size));
    } catch (_) {
      // §7 — "Falha de leitura de miniatura: Placeholder no carrossel;
      // item permanece triável." Nunca deixa a exceção subir pra UI.
      return null;
    }
  }

  @override
  Future<List<int>> moveToSystemTrash(List<int> mediaStoreIds) async {
    if (mediaStoreIds.isEmpty) return const [];
    // `moveToTrash` pede `AssetEntity`, não IDs crus — diferente de
    // `deleteWithIds` (abaixo). Itens que já sumiram do MediaStore
    // entre a leitura da fila e o toque em Excluir viram `null` e são
    // descartados sem quebrar o lote inteiro.
    final assets = await Future.wait(
      mediaStoreIds.map((id) => AssetEntity.fromId(id.toString())),
    );
    final valid = assets.whereType<AssetEntity>().toList();
    if (valid.isEmpty) return const [];

    final trashed = await PhotoManager.editor.moveToTrash(valid);
    return _parseIds(trashed);
  }

  @override
  Future<List<int>> deletePermanently(List<int> mediaStoreIds) async {
    if (mediaStoreIds.isEmpty) return const [];
    final deleted = await PhotoManager.editor.deleteWithIds(
      mediaStoreIds.map((id) => id.toString()).toList(),
    );
    return _parseIds(deleted);
  }

  List<int> _parseIds(List<String> ids) =>
      ids.map(int.tryParse).whereType<int>().toList();

  @override
  Future<Set<int>?> systemTrashedMediaStoreIds() async {
    try {
      final ids = await _trashChannel.invokeMethod<List<Object?>>(
        'getTrashedMediaStoreIds',
      );
      if (ids == null) return const {};
      return ids.whereType<int>().toSet();
    } on PlatformException catch (_) {
      // §7 — falha do canal nunca deve travar a sincronização, mas
      // `null` (não conjunto vazio) sinaliza "sem verdade agora" pro
      // `SyncService` — ver motivo no contrato do repositório.
      return null;
    } on MissingPluginException catch (_) {
      return null;
    }
  }

  @override
  Future<bool> moveAssetsToRelativePath(
    List<int> mediaStoreIds,
    String targetRelativePath,
  ) async {
    if (mediaStoreIds.isEmpty) return true;
    final assets = await Future.wait(
      mediaStoreIds.map((id) => AssetEntity.fromId(id.toString())),
    );
    final valid = assets.whereType<AssetEntity>().toList();
    if (valid.isEmpty) return false;

    try {
      return await PhotoManager.editor.android.moveAssetsToPath(
        entities: valid,
        targetPath: targetRelativePath,
      );
    } catch (_) {
      // §7 — cancelamento do diálogo do sistema ou qualquer outra
      // falha vira "não moveu nada" pro AlbumMoveService, nunca uma
      // exceção subindo até a UI. O lote continua `albumMovePending`.
      return false;
    }
  }
}
