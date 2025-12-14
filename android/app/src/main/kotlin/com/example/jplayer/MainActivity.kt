package com.example.jplayer

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.ContentResolver
import android.provider.MediaStore
import android.database.Cursor
import android.os.Build
import androidx.annotation.NonNull

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.mediamanager/scanner"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "scanVideos" -> {
                    val videos = scanVideos()
                    result.success(videos)
                }
                "scanAudio" -> {
                    val audio = scanAudio()
                    result.success(audio)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun scanVideos(): List<Map<String, Any?>> {
        val videos = mutableListOf<Map<String, Any?>>()
        val contentResolver: ContentResolver = contentResolver
        
        val projection = arrayOf(
            MediaStore.Video.Media._ID,
            MediaStore.Video.Media.DISPLAY_NAME,
            MediaStore.Video.Media.DATA,
            MediaStore.Video.Media.DURATION,
            MediaStore.Video.Media.SIZE,
            MediaStore.Video.Media.DATE_ADDED
        )
        
        val sortOrder = "${MediaStore.Video.Media.DATE_ADDED} DESC"
        
        val cursor: Cursor? = contentResolver.query(
            MediaStore.Video.Media.EXTERNAL_CONTENT_URI,
            projection,
            null,
            null,
            sortOrder
        )
        
        cursor?.use {
            val idColumn = it.getColumnIndexOrThrow(MediaStore.Video.Media._ID)
            val nameColumn = it.getColumnIndexOrThrow(MediaStore.Video.Media.DISPLAY_NAME)
            val dataColumn = it.getColumnIndexOrThrow(MediaStore.Video.Media.DATA)
            val durationColumn = it.getColumnIndexOrThrow(MediaStore.Video.Media.DURATION)
            val sizeColumn = it.getColumnIndexOrThrow(MediaStore.Video.Media.SIZE)
            val dateColumn = it.getColumnIndexOrThrow(MediaStore.Video.Media.DATE_ADDED)
            
            while (it.moveToNext()) {
                val id = it.getLong(idColumn)
                val name = it.getString(nameColumn)
                val path = it.getString(dataColumn)
                val duration = it.getLong(durationColumn) / 1000 // Convert to seconds
                val size = it.getLong(sizeColumn)
                val dateAdded = it.getLong(dateColumn)
                
                videos.add(mapOf(
                    "id" to id,
                    "title" to name,
                    "path" to path,
                    "duration" to duration,
                    "size" to size,
                    "dateAdded" to dateAdded,
                    "thumbnail" to null
                ))
            }
        }
        
        return videos
    }

    private fun scanAudio(): List<Map<String, Any?>> {
        val audioFiles = mutableListOf<Map<String, Any?>>()
        val contentResolver: ContentResolver = contentResolver
        
        val projection = arrayOf(
            MediaStore.Audio.Media._ID,
            MediaStore.Audio.Media.DISPLAY_NAME,
            MediaStore.Audio.Media.DATA,
            MediaStore.Audio.Media.DURATION,
            MediaStore.Audio.Media.SIZE,
            MediaStore.Audio.Media.ARTIST,
            MediaStore.Audio.Media.ALBUM,
            MediaStore.Audio.Media.DATE_ADDED
        )
        
        val selection = "${MediaStore.Audio.Media.IS_MUSIC} != 0"
        val sortOrder = "${MediaStore.Audio.Media.DATE_ADDED} DESC"
        
        val cursor: Cursor? = contentResolver.query(
            MediaStore.Audio.Media.EXTERNAL_CONTENT_URI,
            projection,
            selection,
            null,
            sortOrder
        )
        
        cursor?.use {
            val idColumn = it.getColumnIndexOrThrow(MediaStore.Audio.Media._ID)
            val nameColumn = it.getColumnIndexOrThrow(MediaStore.Audio.Media.DISPLAY_NAME)
            val dataColumn = it.getColumnIndexOrThrow(MediaStore.Audio.Media.DATA)
            val durationColumn = it.getColumnIndexOrThrow(MediaStore.Audio.Media.DURATION)
            val sizeColumn = it.getColumnIndexOrThrow(MediaStore.Audio.Media.SIZE)
            val artistColumn = it.getColumnIndexOrThrow(MediaStore.Audio.Media.ARTIST)
            val albumColumn = it.getColumnIndexOrThrow(MediaStore.Audio.Media.ALBUM)
            val dateColumn = it.getColumnIndexOrThrow(MediaStore.Audio.Media.DATE_ADDED)
            
            while (it.moveToNext()) {
                val id = it.getLong(idColumn)
                val name = it.getString(nameColumn)
                val path = it.getString(dataColumn)
                val duration = it.getLong(durationColumn) / 1000 // Convert to seconds
                val size = it.getLong(sizeColumn)
                val artist = it.getString(artistColumn)
                val album = it.getString(albumColumn)
                val dateAdded = it.getLong(dateColumn)
                
                audioFiles.add(mapOf(
                    "id" to id,
                    "title" to name,
                    "path" to path,
                    "duration" to duration,
                    "size" to size,
                    "artist" to artist,
                    "album" to album,
                    "dateAdded" to dateAdded
                ))
            }
        }
        
        return audioFiles
    }
}
