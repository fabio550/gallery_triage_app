package com.example.gallery_triage_app

import android.content.ContentResolver
import android.content.ContentUris
import android.content.ContentValues
import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.provider.MediaStore
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Canal nativo só para o que `photo_manager` não expõe (ou expõe de
 * um jeito que não serve aqui):
 *
 * - 2.1.5 — quais itens estão na lixeira do sistema agora
 *   (`IS_TRASHED`), inclusive os retidos por fora deste app (outro
 *   app, Fotos do sistema). Sem isso o `SyncService` só reconhecia o
 *   que o próprio app trashava (`moveToSystemTrash`) e não distinguia
 *   retido de órfão de verdade (5.5.2/5.5.4).
 * - 6.5.7 — mover um lote heterogêneo (cada item com seu próprio
 *   destino) num único diálogo do sistema. `photo_manager.editor
 *   .android.moveAssetsToPath` só aceita um destino por chamada — um
 *   lote com vários álbuns viraria um diálogo por álbum. Implementado
 *   aqui do mesmo jeito que o próprio `photo_manager` faz por baixo
 *   dos panos (`createWriteRequest` + `startIntentSenderForResult`),
 *   só que pedindo a concessão pra todos os URIs de uma vez, não
 *   importa quantos destinos diferentes eles têm.
 * - 6.5.8 — pastas reais já existentes com mídia (Câmera, WhatsApp
 *   Images etc.), pra oferecer como álbum importável. `photo_manager`
 *   agrupa por `bucket_id`, não expõe o `RELATIVE_PATH` cru usado pela
 *   convenção de pasta de álbum deste app (6.5.7).
 *
 * `minSdk` já é 30 (4.1.1): `QUERY_ARG_MATCH_TRASHED`, `IS_TRASHED` e
 * `createWriteRequest` estão sempre disponíveis, sem checagem de
 * versão em runtime.
 */
class MainActivity : FlutterActivity() {
    private var pendingMoveResult: MethodChannel.Result? = null
    private var pendingMoveTargets: Map<Uri, String>? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getTrashedMediaStoreIds" -> result.success(trashedMediaStoreIds())
                    "moveAssetsToPaths" -> handleMoveAssetsToPaths(call, result)
                    "listMediaFolders" -> result.success(mediaFolders())
                    else -> result.notImplemented()
                }
            }
    }

    /**
     * Uma única consulta pela tabela `Files` (não `Images`/`Video`
     * separadas): a lixeira mistura os dois tipos e compartilha o
     * mesmo espaço de `_ID` que `photo_manager`/`AssetEntity.id` usa
     * do lado Dart (`mediaStoreId`).
     */
    private fun trashedMediaStoreIds(): List<Long> {
        val uri = MediaStore.Files.getContentUri(MediaStore.VOLUME_EXTERNAL)
        val projection = arrayOf(MediaStore.Files.FileColumns._ID)
        val selection =
            "${MediaStore.Files.FileColumns.MEDIA_TYPE} = ? OR " +
                "${MediaStore.Files.FileColumns.MEDIA_TYPE} = ?"
        val selectionArgs = arrayOf(
            MediaStore.Files.FileColumns.MEDIA_TYPE_IMAGE.toString(),
            MediaStore.Files.FileColumns.MEDIA_TYPE_VIDEO.toString(),
        )
        val queryArgs = Bundle().apply {
            putString(ContentResolver.QUERY_ARG_SQL_SELECTION, selection)
            putStringArray(ContentResolver.QUERY_ARG_SQL_SELECTION_ARGS, selectionArgs)
            putInt(MediaStore.QUERY_ARG_MATCH_TRASHED, MediaStore.MATCH_ONLY)
        }

        val ids = mutableListOf<Long>()
        contentResolver.query(uri, projection, queryArgs, null)?.use { cursor ->
            val idColumn = cursor.getColumnIndexOrThrow(MediaStore.Files.FileColumns._ID)
            while (cursor.moveToNext()) {
                ids.add(cursor.getLong(idColumn))
            }
        }
        return ids
    }

    /**
     * 6.5.8 — todo `RELATIVE_PATH` distinto com pelo menos um item de
     * mídia agora (Câmera, WhatsApp Images, pastas de outro app etc.).
     * Sem `DISTINCT` na consulta em si (a API de `ContentResolver` não
     * garante suporte a isso entre versões) — dedupe em memória com um
     * `Set`, custo aceitável mesmo com dezenas de milhares de linhas
     * porque só a coluna de caminho é projetada.
     */
    private fun mediaFolders(): List<String> {
        val uri = MediaStore.Files.getContentUri(MediaStore.VOLUME_EXTERNAL)
        val projection = arrayOf(MediaStore.Files.FileColumns.RELATIVE_PATH)
        val selection =
            "${MediaStore.Files.FileColumns.MEDIA_TYPE} = ? OR " +
                "${MediaStore.Files.FileColumns.MEDIA_TYPE} = ?"
        val selectionArgs = arrayOf(
            MediaStore.Files.FileColumns.MEDIA_TYPE_IMAGE.toString(),
            MediaStore.Files.FileColumns.MEDIA_TYPE_VIDEO.toString(),
        )

        val paths = sortedSetOf<String>()
        contentResolver.query(uri, projection, selection, selectionArgs, null)?.use { cursor ->
            val pathColumn =
                cursor.getColumnIndexOrThrow(MediaStore.Files.FileColumns.RELATIVE_PATH)
            while (cursor.moveToNext()) {
                val path = cursor.getString(pathColumn)
                if (!path.isNullOrBlank()) paths.add(path)
            }
        }
        return paths.toList()
    }

    @Suppress("UNCHECKED_CAST")
    private fun handleMoveAssetsToPaths(call: MethodCall, result: MethodChannel.Result) {
        val moves = call.argument<List<Map<String, Any>>>("moves")
        if (moves == null) {
            result.error("invalid_args", "\"moves\" ausente", null)
            return
        }
        if (moves.isEmpty()) {
            result.success(emptyList<Long>())
            return
        }

        // `createWriteRequest` rejeita URIs da coleção genérica `Files`
        // ("All requested items must be Media items") — exige a coleção
        // específica (`Images`/`Video`), mesmo apontando pra mesma linha
        // que a consulta de lixeira (acima) lê via `Files` sem problema.
        val imagesUri = MediaStore.Images.Media.getContentUri(MediaStore.VOLUME_EXTERNAL)
        val videoUri = MediaStore.Video.Media.getContentUri(MediaStore.VOLUME_EXTERNAL)
        val targets = moves.associate { move ->
            val id = (move["mediaStoreId"] as Number).toLong()
            val path = move["targetRelativePath"] as String
            val isVideo = move["isVideo"] as? Boolean ?: false
            val collectionUri = if (isVideo) videoUri else imagesUri
            ContentUris.withAppendedId(collectionUri, id) to path
        }

        // Só um diálogo por lote, não importa quantos destinos
        // diferentes existam nele (6.5.7) — a concessão cobre todos os
        // URIs pedidos de uma vez; cada `ContentResolver.update` já
        // aplicado depois (`onActivityResult`) não pede confirmação de
        // novo.
        pendingMoveResult = result
        pendingMoveTargets = targets

        try {
            val pendingIntent = MediaStore.createWriteRequest(contentResolver, targets.keys.toList())
            startIntentSenderForResult(
                pendingIntent.intentSender,
                MOVE_REQUEST_CODE,
                null,
                0,
                0,
                0,
            )
        } catch (e: Exception) {
            Log.e(TAG, "createWriteRequest falhou pro lote de movimento de álbum", e)
            pendingMoveResult = null
            pendingMoveTargets = null
            result.success(emptyList<Long>())
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (requestCode == MOVE_REQUEST_CODE) {
            val targets = pendingMoveTargets
            val callback = pendingMoveResult
            pendingMoveTargets = null
            pendingMoveResult = null

            // RESULT_CANCELED (usuário recusou o diálogo) — nenhum
            // arquivo é tocado, lista vazia; os itens continuam
            // `albumMovePending` do lado Dart, tentam de novo depois.
            if (resultCode == RESULT_OK && targets != null) {
                callback?.success(applyMoves(targets))
            } else {
                Log.w(TAG, "Diálogo de movimento de álbum não aprovado (resultCode=$resultCode)")
                callback?.success(emptyList<Long>())
            }
            return
        }
        // Qualquer outro código é de outro plugin (photo_manager,
        // permission_handler) — o embedding do Flutter distribui isso
        // pros `ActivityResultListener` registrados por eles.
        super.onActivityResult(requestCode, resultCode, data)
    }

    /**
     * Já com a concessão de escrita obtida (§7 — cada arquivo ainda
     * pode falhar individualmente, ex.: removido nesse meio-tempo).
     * Retorna só os `mediaStoreId` efetivamente movidos.
     */
    private fun applyMoves(targets: Map<Uri, String>): List<Long> {
        val moved = mutableListOf<Long>()
        val values = ContentValues()
        for ((uri, path) in targets) {
            values.clear()
            values.put(MediaStore.MediaColumns.RELATIVE_PATH, path)
            val rows = try {
                contentResolver.update(uri, values, null, null)
            } catch (e: Exception) {
                Log.e(TAG, "update falhou pra $uri -> \"$path\"", e)
                0
            }
            if (rows > 0) {
                moved.add(ContentUris.parseId(uri))
            } else {
                // Sem exceção, mas 0 linhas afetadas: RELATIVE_PATH mal
                // formado (sem barra no final, ex.) faz o MediaStore
                // ignorar o pedido silenciosamente em vez de lançar.
                Log.w(TAG, "update não moveu $uri -> \"$path\" (0 linhas afetadas)")
            }
        }
        return moved
    }

    private companion object {
        const val TAG = "GalleryTriageMediaNative"
        const val CHANNEL = "gallery_triage_app/media_native"
        const val MOVE_REQUEST_CODE = 40987
    }
}
