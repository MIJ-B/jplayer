package com.example.jplayer

import android.Manifest
import android.content.ContentUris
import android.content.pm.PackageManager
import android.database.Cursor
import android.net.Uri
import android.os.Build
import android.provider.MediaStore
import androidx.annotation.NonNull
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.mediamanager/scanner"
    private val PERMISSION_REQUEST_CODE = 123

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "scanVideos" -> {
                    if (checkPermissions()) {
                        val videos = scanVideos()
                        result.success(videos)
                    } else {
                        requestPermissions()
                        result.error("PERMISSION_DENIED", "Storage permission required", null)
                    }
                }
                "scanAudio" -> {
                    if (checkPermissions()) {
                        val audio = scanAudio()
                        result.success(audio)
                    } else {
                        requestPermissions()
                        result.error("PERMISSION_DENIED", "Storage permission required", null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun checkPermissions(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            ContextCompat.checkSelfPermission(this, Manifest.permission.READ_MEDIA_VIDEO) == PackageManager.PERMISSION_GRANTED &&
            ContextCompat.checkSelfPermission(this, Manifest.permission.READ_MEDIA_AUDIO) == PackageManager.PERMISSION_GRANTED
        } else {
            ContextCompat.checkSelfPermission(this, Manifest.permission.READ_EXTERNAL_STORAGE) == PackageManager.PERMISSION_GRANTED
        }
    }

    private fun requestPermissions() {
        val permissions = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            arrayOf(
                Manifest.permission.READ_MEDIA_VIDEO,
                Manifest.permission.READ_MEDIA_AUDIO
            )
        } else {
            arrayOf(Manifest.permission.READ_EXTERNAL_STORAGE)
        }
        ActivityCompat.requestPermissions(this, permissions, PERMISSION_REQUEST_CODE)
    }

    private fun scanVideos(): List<Map<String, Any?>> {
        val videoList = mutableListOf<Map<String, Any?>>()
        
        val projection = arrayOf(
            MediaStore.Video.Media._ID,
            MediaStore.Video.Media.DISPLAY_NAME,
            MediaStore.Video.Media.DURATION,
            MediaStore.Video.Media.SIZE,
            MediaStore.Video.Media.DATA,
            MediaStore.Video.Media.DATE_ADDED,
            MediaStore.Video.Media.RESOLUTION
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
            val durationColumn = it.getColumnIndexOrThrow(MediaStore.Video.Media.DURATION)
            val sizeColumn = it.getColumnIndexOrThrow(MediaStore.Video.Media.SIZE)
            val dataColumn = it.getColumnIndexOrThrow(MediaStore.Video.Media.DATA)
            val dateColumn = it.getColumnIndexOrThrow(MediaStore.Video.Media.DATE_ADDED)

            while (it.moveToNext()) {
                val id = it.getLong(idColumn)
                val name = it.getString(nameColumn)
                val duration = it.getLong(durationColumn) / 1000 // Convert to seconds
                val size = it.getLong(sizeColumn)
                val path = it.getString(dataColumn)
                val dateAdded = it.getLong(dateColumn)

                // Get thumbnail
                val contentUri = ContentUris.withAppendedId(
                    MediaStore.Video.Media.EXTERNAL_CONTENT_URI,
                    id
                )

                val thumbnailPath = try {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                        val thumbnail = contentResolver.loadThumbnail(
                            contentUri,
                            android.util.Size(640, 480),
                            null
                        )
                        // Save thumbnail and return path
                        saveThumbnail(thumbnail, id)
                    } else {
                        MediaStore.Video.Thumbnails.getThumbnail(
                            contentResolver,
                            id,
                            MediaStore.Video.Thumbnails.MINI_KIND,
                            null
                        )?.let { bitmap ->
                            saveThumbnail(bitmap, id)
                        }
                    }
                } catch (e: Exception) {
                    null
                }

                val videoMap = mapOf(
                    "id" to id,
                    "title" to name,
                    "duration" to duration,
                    "size" to size,
                    "path" to path,
                    "dateAdded" to dateAdded,
                    "thumbnail" to thumbnailPath
                )
                
                videoList.add(videoMap)
            }
        }

        return videoList
    }

    private fun scanAudio(): List<Map<String, Any?>> {
        val audioList = mutableListOf<Map<String, Any?>>()
        
        val projection = arrayOf(
            MediaStore.Audio.Media._ID,
            MediaStore.Audio.Media.TITLE,
            MediaStore.Audio.Media.ARTIST,
            MediaStore.Audio.Media.ALBUM,
            MediaStore.Audio.Media.DURATION,
            MediaStore.Audio.Media.SIZE,
            MediaStore.Audio.Media.DATA,
            MediaStore.Audio.Media.DATE_ADDED
        )

        val selection = "${MediaStore.Audio.Media.IS_MUSIC} != 0"
        val sortOrder = "${MediaStore.Audio.Media.TITLE} ASC"
        
        val cursor: Cursor? = contentResolver.query(
            MediaStore.Audio.Media.EXTERNAL_CONTENT_URI,
            projection,
            selection,
            null,
            sortOrder
        )

        cursor?.use {
            val idColumn = it.getColumnIndexOrThrow(MediaStore.Audio.Media._ID)
            val titleColumn = it.getColumnIndexOrThrow(MediaStore.Audio.Media.TITLE)
            val artistColumn = it.getColumnIndexOrThrow(MediaStore.Audio.Media.ARTIST)
            val albumColumn = it.getColumnIndexOrThrow(MediaStore.Audio.Media.ALBUM)
            val durationColumn = it.getColumnIndexOrThrow(MediaStore.Audio.Media.DURATION)
            val sizeColumn = it.getColumnIndexOrThrow(MediaStore.Audio.Media.SIZE)
            val dataColumn = it.getColumnIndexOrThrow(MediaStore.Audio.Media.DATA)
            val dateColumn = it.getColumnIndexOrThrow(MediaStore.Audio.Media.DATE_ADDED)

            while (it.moveToNext()) {
                val id = it.getLong(idColumn)
                val title = it.getString(titleColumn)
                val artist = it.getString(artistColumn)
                val album = it.getString(albumColumn)
                val duration = it.getLong(durationColumn) / 1000 // Convert to seconds
                val size = it.getLong(sizeColumn)
                val path = it.getString(dataColumn)
                val dateAdded = it.getLong(dateColumn)

                val audioMap = mapOf(
                    "id" to id,
                    "title" to title,
                    "artist" to artist,
                    "album" to album,
                    "duration" to duration,
                    "size" to size,
                    "path" to path,
                    "dateAdded" to dateAdded
                )
                
                audioList.add(audioMap)
            }
        }

        return audioList
    }

    private fun saveThumbnail(bitmap: android.graphics.Bitmap, id: Long): String? {
        return try {
            val file = java.io.File(cacheDir, "thumb_$id.jpg")
            java.io.FileOutputStream(file).use { out ->
                bitmap.compress(android.graphics.Bitmap.CompressFormat.JPEG, 80, out)
            }
            file.absolutePath
        } catch (e: Exception) {
            null
        }
    }
}
