package com.bizflow.bizflow_mobile

import android.content.ContentValues
import android.media.MediaScannerConnection
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import android.provider.MediaStore.MediaColumns
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
	companion object {
		private const val AUDIO_STORAGE_CHANNEL = "bizflow/audio_storage"
	}

	override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
		super.configureFlutterEngine(flutterEngine)

		MethodChannel(flutterEngine.dartExecutor.binaryMessenger, AUDIO_STORAGE_CHANNEL)
			.setMethodCallHandler { call, result ->
				if (call.method != "saveAudioToPublicRecordings") {
					result.notImplemented()
					return@setMethodCallHandler
				}

				handleSaveAudio(call, result)
			}
	}

	private fun handleSaveAudio(call: MethodCall, result: MethodChannel.Result) {
		val sourcePath = call.argument<String>("sourcePath")
		if (sourcePath.isNullOrBlank()) {
			result.error("invalid_args", "sourcePath is required", null)
			return
		}

		val displayName = call.argument<String>("displayName")

		try {
			val savedPath = saveAudioToPublicRecordings(sourcePath, displayName)
			if (savedPath == null) {
				result.error("save_failed", "Could not save audio to public recordings", null)
				return
			}

			result.success(savedPath)
		} catch (e: Exception) {
			result.error("save_exception", e.message, null)
		}
	}

	private fun saveAudioToPublicRecordings(sourcePath: String, displayNameArg: String?): String? {
		val sourceFile = File(sourcePath)
		if (!sourceFile.exists()) return null

		val extension = sourceFile.extension.lowercase()
		val mimeType = when (extension) {
			"m4a" -> "audio/mp4"
			"mp3" -> "audio/mpeg"
			"wav" -> "audio/wav"
			"aac" -> "audio/aac"
			"ogg" -> "audio/ogg"
			else -> "audio/*"
		}

		val displayName = if (displayNameArg.isNullOrBlank()) sourceFile.name else displayNameArg
		val recordingsRoot = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
			Environment.DIRECTORY_RECORDINGS
		} else {
			"Recordings"
		}
		val relativePath =
			"$recordingsRoot${File.separator}BizFlow${File.separator}"

		return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
			val resolver = applicationContext.contentResolver
			val values = ContentValues().apply {
				put(MediaStore.Audio.Media.DISPLAY_NAME, displayName)
				put(MediaStore.Audio.Media.MIME_TYPE, mimeType)
				put(MediaColumns.RELATIVE_PATH, relativePath)
				put(MediaStore.Audio.Media.IS_PENDING, 1)
			}

			val uri = resolver.insert(MediaStore.Audio.Media.EXTERNAL_CONTENT_URI, values)
				?: return null

			resolver.openOutputStream(uri)?.use { output ->
				sourceFile.inputStream().use { input ->
					input.copyTo(output)
				}
			} ?: return null

			values.clear()
			values.put(MediaStore.Audio.Media.IS_PENDING, 0)
			resolver.update(uri, values, null, null)

			val projection = arrayOf(MediaColumns.RELATIVE_PATH, MediaColumns.DISPLAY_NAME)
			resolver.query(uri, projection, null, null, null)?.use { cursor ->
				if (cursor.moveToFirst()) {
					val relPath = cursor.getString(0) ?: relativePath
					val name = cursor.getString(1) ?: displayName
					return "$relPath$name"
				}
			}

			"$relativePath$displayName"
		} else {
			val recordingsDir = File(
				Environment.getExternalStoragePublicDirectory(recordingsRoot),
				"BizFlow"
			)
			if (!recordingsDir.exists()) {
				recordingsDir.mkdirs()
			}

			val targetFile = File(recordingsDir, displayName)
			sourceFile.copyTo(targetFile, overwrite = true)

			MediaScannerConnection.scanFile(
				this,
				arrayOf(targetFile.absolutePath),
				arrayOf(mimeType),
				null,
			)

			targetFile.absolutePath
		}
	}
}
