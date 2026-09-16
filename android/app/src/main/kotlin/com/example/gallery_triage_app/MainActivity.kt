package com.example.gallery_triage_app

import android.content.ContentResolver
import android.os.Bundle
import android.provider.MediaStore
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * 2.1.5 — canal nativo só para o que `photo_manager` não expõe: quais
 * itens estão na lixeira do sistema agora (`IS_TRASHED`), inclusive os
 * retidos por fora deste app (outro app, Fotos do sistema). Sem isso o
 * `SyncService` só conseguia reconhecer o que o próprio app trashava
 * (`moveToSystemTrash`) e não distinguia retido de órfão de verdade
 * (5.5.2/5.5.4). `minSdk` já é 30 (4.1.1): `QUERY_ARG_MATCH_TRASHED` e
 * `IS_TRASHED` estão sempre disponíveis, sem checagem de versão.
 */
class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method == "getTrashedMediaStoreIds") {
                    result.success(trashedMediaStoreIds())
                } else {
                    result.notImplemented()
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

    private companion object {
        const val CHANNEL = "gallery_triage_app/media_trash"
    }
}
