package com.uniyi.uni_yi

import android.app.Activity
import android.content.ActivityNotFoundException
import android.content.ContentValues
import android.content.Intent
import android.net.Uri
import android.media.MediaScannerConnection
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import android.provider.Settings
import android.webkit.MimeTypeMap
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream
import java.io.IOException

class MainActivity : FlutterActivity() {
    companion object {
        private const val SAVE_WITH_PICKER_REQUEST_CODE = 41027
    }

    private var pendingPickerResult: MethodChannel.Result? = null
    private var pendingPickerBytes: ByteArray? = null
    private var pendingPickerFileName: String? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        configureDownloadsChannel(flutterEngine)
        configureInstallerChannel(flutterEngine)
    }

    @Deprecated("Deprecated in Java")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != SAVE_WITH_PICKER_REQUEST_CODE) {
            return
        }

        val result = pendingPickerResult
        val bytes = pendingPickerBytes
        val fileName = pendingPickerFileName
        clearPendingPickerState()

        if (result == null) {
            return
        }

        if (resultCode != Activity.RESULT_OK) {
            result.error("cancelled", "User cancelled save", null)
            return
        }

        val uri = data?.data
        if (uri == null || bytes == null || fileName.isNullOrBlank()) {
            result.error("invalid_state", "Missing picker result data", null)
            return
        }

        try {
            val grantFlags =
                data.flags and
                    (Intent.FLAG_GRANT_READ_URI_PERMISSION or
                        Intent.FLAG_GRANT_WRITE_URI_PERMISSION)
            if (grantFlags != 0) {
                contentResolver.takePersistableUriPermission(uri, grantFlags)
            }

            applicationContext.contentResolver.openOutputStream(uri)?.use { stream ->
                stream.write(bytes)
                stream.flush()
            } ?: throw IOException("Unable to open output stream.")

            result.success(
                mapOf(
                    "fileName" to fileName,
                    "locationLabel" to "所选位置/$fileName",
                    "uri" to uri.toString(),
                ),
            )
        } catch (error: Exception) {
            result.error("save_failed", error.message, null)
        }
    }

    private fun configureDownloadsChannel(flutterEngine: FlutterEngine) {
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "uni_yi/downloads",
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "saveToPublicDownloads" -> {
                    val fileName = call.argument<String>("fileName")
                    val bytes = call.argument<ByteArray>("bytes")
                    val subdirectory = call.argument<String>("subdirectory") ?: ""

                    if (fileName.isNullOrBlank() || bytes == null) {
                        result.error("invalid_args", "Missing fileName or bytes", null)
                        return@setMethodCallHandler
                    }

                    try {
                        result.success(saveToPublicDownloads(fileName, bytes, subdirectory))
                    } catch (error: Exception) {
                        result.error("save_failed", error.message, null)
                    }
                }

                "saveWithPicker" -> {
                    val fileName = call.argument<String>("fileName")
                    val bytes = call.argument<ByteArray>("bytes")

                    if (fileName.isNullOrBlank() || bytes == null) {
                        result.error("invalid_args", "Missing fileName or bytes", null)
                        return@setMethodCallHandler
                    }

                    if (pendingPickerResult != null) {
                        result.error("busy", "Another save request is already in progress", null)
                        return@setMethodCallHandler
                    }

                    pendingPickerResult = result
                    pendingPickerBytes = bytes
                    pendingPickerFileName = fileName

                    try {
                        launchSaveWithPicker(fileName)
                    } catch (error: Exception) {
                        clearPendingPickerState()
                        result.error("picker_failed", error.message, null)
                    }
                }

                else -> result.notImplemented()
            }
        }
    }

    private fun configureInstallerChannel(flutterEngine: FlutterEngine) {
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "uni_yi/app_installer",
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "installApk" -> {
                    val fileName = call.argument<String>("fileName")
                    val path = call.argument<String>("path")
                    val uri = call.argument<String>("uri")

                    if (fileName.isNullOrBlank()) {
                        result.error("invalid_args", "Missing fileName", null)
                        return@setMethodCallHandler
                    }

                    try {
                        result.success(installApk(fileName, path, uri))
                    } catch (error: Exception) {
                        result.error("install_failed", error.message, null)
                    }
                }

                else -> result.notImplemented()
            }
        }
    }

    private fun saveToPublicDownloads(
        fileName: String,
        bytes: ByteArray,
        subdirectory: String,
    ): Map<String, String?> {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            saveWithMediaStore(fileName, bytes, subdirectory)
        } else {
            saveWithFileApi(fileName, bytes, subdirectory)
        }
    }

    private fun saveWithMediaStore(
        fileName: String,
        bytes: ByteArray,
        subdirectory: String,
    ): Map<String, String?> {
        val resolver = applicationContext.contentResolver
        val normalizedSubdirectory = normalizeSubdirectory(subdirectory)
        val relativePath =
            if (normalizedSubdirectory.isBlank()) {
                "${Environment.DIRECTORY_DOWNLOADS}/"
            } else {
                "${Environment.DIRECTORY_DOWNLOADS}/$normalizedSubdirectory/"
            }
        val finalName = buildUniqueName(fileName) { candidate ->
            resolver.query(
                MediaStore.Downloads.EXTERNAL_CONTENT_URI,
                arrayOf(MediaStore.Downloads._ID),
                "${MediaStore.Downloads.DISPLAY_NAME} = ? AND ${MediaStore.Downloads.RELATIVE_PATH} = ?",
                arrayOf(candidate, relativePath),
                null,
            )?.use { it.count > 0 } ?: false
        }

        val values = ContentValues().apply {
            put(MediaStore.Downloads.DISPLAY_NAME, finalName)
            put(MediaStore.Downloads.MIME_TYPE, guessMimeType(finalName))
            put(MediaStore.Downloads.RELATIVE_PATH, relativePath)
            put(MediaStore.Downloads.IS_PENDING, 1)
        }

        val uri = resolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, values)
            ?: throw IOException("Unable to create download item.")

        resolver.openOutputStream(uri)?.use { stream ->
            stream.write(bytes)
            stream.flush()
        } ?: throw IOException("Unable to open output stream.")

        val ready = ContentValues().apply {
            put(MediaStore.Downloads.IS_PENDING, 0)
        }
        resolver.update(uri, ready, null, null)

        return mapOf(
            "fileName" to finalName,
            "locationLabel" to buildLocationLabel(finalName, normalizedSubdirectory),
            "uri" to uri.toString(),
        )
    }

    private fun saveWithFileApi(
        fileName: String,
        bytes: ByteArray,
        subdirectory: String,
    ): Map<String, String?> {
        val normalizedSubdirectory = normalizeSubdirectory(subdirectory)
        val downloadsDir =
            Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS)
        val targetDir =
            if (normalizedSubdirectory.isBlank()) {
                downloadsDir
            } else {
                File(downloadsDir, normalizedSubdirectory)
            }
        if (!targetDir.exists()) {
            targetDir.mkdirs()
        }

        val finalName = buildUniqueName(fileName) { candidate ->
            File(targetDir, candidate).exists()
        }
        val file = File(targetDir, finalName)
        FileOutputStream(file).use { stream ->
            stream.write(bytes)
            stream.flush()
        }

        MediaScannerConnection.scanFile(
            applicationContext,
            arrayOf(file.absolutePath),
            arrayOf(guessMimeType(finalName)),
            null,
        )

        return mapOf(
            "fileName" to finalName,
            "locationLabel" to file.absolutePath,
            "uri" to file.toURI().toString(),
        )
    }

    private fun launchSaveWithPicker(fileName: String) {
        val intent =
            Intent(Intent.ACTION_CREATE_DOCUMENT).apply {
                addCategory(Intent.CATEGORY_OPENABLE)
                type = guessMimeType(fileName)
                putExtra(Intent.EXTRA_TITLE, fileName)
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                addFlags(Intent.FLAG_GRANT_WRITE_URI_PERMISSION)
                addFlags(Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION)
            }
        @Suppress("DEPRECATION")
        startActivityForResult(intent, SAVE_WITH_PICKER_REQUEST_CODE)
    }

    private fun installApk(
        fileName: String,
        path: String?,
        uriString: String?,
    ): Map<String, String?> {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O &&
            !packageManager.canRequestPackageInstalls()
        ) {
            val intent =
                Intent(
                    Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES,
                    Uri.parse("package:$packageName"),
                ).apply {
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                }
            startActivity(intent)
            return mapOf(
                "status" to "permission_required",
                "message" to "请先允许安装未知来源应用，然后再点一次安装。",
            )
        }

        val apkUri = resolveInstallUri(path, uriString)
        val intent =
            Intent(Intent.ACTION_VIEW).apply {
                setDataAndType(apkUri, "application/vnd.android.package-archive")
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            }

        try {
            startActivity(intent)
        } catch (_: ActivityNotFoundException) {
            throw IOException("系统未找到可用的安装器。")
        }

        return mapOf(
            "status" to "started",
            "message" to "$fileName 已交给系统安装器处理。",
        )
    }

    private fun resolveInstallUri(path: String?, uriString: String?): Uri {
        if (!uriString.isNullOrBlank() && uriString.startsWith("content://")) {
            return Uri.parse(uriString)
        }

        if (path.isNullOrBlank()) {
            if (!uriString.isNullOrBlank()) {
                return Uri.parse(uriString)
            }
            throw IOException("Missing install target path.")
        }

        val file = File(path)
        if (!file.exists()) {
            throw IOException("Install file does not exist.")
        }

        return FileProvider.getUriForFile(
            applicationContext,
            "${applicationContext.packageName}.fileprovider",
            file,
        )
    }

    private fun buildUniqueName(original: String, exists: (String) -> Boolean): String {
        val dotIndex = original.lastIndexOf('.')
        val base = if (dotIndex <= 0) original else original.substring(0, dotIndex)
        val extension = if (dotIndex <= 0) "" else original.substring(dotIndex)

        var candidate = original
        var suffix = 1
        while (exists(candidate)) {
            candidate = "${base}_$suffix$extension"
            suffix += 1
        }
        return candidate
    }

    private fun normalizeSubdirectory(raw: String): String {
        val normalized = raw
            .replace('\\', '/')
            .split('/')
            .map { it.trim() }
            .filter { it.isNotEmpty() }
            .joinToString("/")
        return normalized
    }

    private fun buildLocationLabel(fileName: String, normalizedSubdirectory: String): String {
        return if (normalizedSubdirectory.isBlank()) {
            "下载/$fileName"
        } else {
            "下载/$normalizedSubdirectory/$fileName"
        }
    }

    private fun clearPendingPickerState() {
        pendingPickerResult = null
        pendingPickerBytes = null
        pendingPickerFileName = null
    }

    private fun guessMimeType(fileName: String): String {
        val extension = fileName.substringAfterLast('.', "").lowercase()
        if (extension.isEmpty()) {
            return "application/octet-stream"
        }

        return MimeTypeMap.getSingleton().getMimeTypeFromExtension(extension)
            ?: "application/octet-stream"
    }
}
