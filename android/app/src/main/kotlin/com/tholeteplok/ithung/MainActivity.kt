package com.tholeteplok.ithung

import android.app.DownloadManager
import android.content.ContentValues
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileInputStream
import java.security.MessageDigest

class MainActivity : FlutterActivity() {
    private companion object {
        const val INSTALLER_CHANNEL = "com.tholeteplok.ithung/installer"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            INSTALLER_CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "installApk" -> {
                    val filePath = call.argument<String>("filePath")
                    if (filePath != null) {
                        installApk(filePath, result)
                    } else {
                        result.error("INVALID_PATH", "File path cannot be null", null)
                    }
                }
                "checkSignatureMatch" -> {
                    val filePath = call.argument<String>("filePath")
                    if (filePath != null) {
                        checkSignatureMatch(filePath, result)
                    } else {
                        result.error("INVALID_PATH", "File path cannot be null", null)
                    }
                }
                "exportToPublicDownloads" -> {
                    val filePath = call.argument<String>("filePath")
                    val fileName = call.argument<String>("fileName") ?: "iTHUNG-update.apk"
                    if (filePath != null) {
                        exportToPublicDownloads(filePath, fileName, result)
                    } else {
                        result.error("INVALID_PATH", "File path cannot be null", null)
                    }
                }
                "promptUninstall" -> {
                    promptUninstall(result)
                }
                "openDownloadsFolder" -> {
                    openDownloadsFolder(result)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun installApk(filePath: String, result: MethodChannel.Result) {
        try {
            val file = File(filePath)
            if (!file.exists()) {
                result.error("FILE_NOT_FOUND", "APK file does not exist at $filePath", null)
                return
            }

            val apkUri = FileProvider.getUriForFile(
                applicationContext,
                "${applicationContext.packageName}.fileprovider",
                file
            )

            val intent = Intent(Intent.ACTION_VIEW).apply {
                setDataAndType(apkUri, "application/vnd.android.package-archive")
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }

            startActivity(intent)
            result.success(true)
        } catch (e: Exception) {
            result.error("INSTALL_ERROR", e.message, null)
        }
    }

    private fun checkSignatureMatch(filePath: String, result: MethodChannel.Result) {
        try {
            val file = File(filePath)
            if (!file.exists()) {
                result.error("FILE_NOT_FOUND", "File not found at $filePath", null)
                return
            }

            val currentSignatures = getCurrentAppSignatures()
            val archiveSignatures = getArchiveSignatures(filePath)

            if (currentSignatures.isEmpty() || archiveSignatures.isEmpty()) {
                // Jika tidak dapat membaca sertifikat secara aman, jangan memblokir update
                result.success(true)
                return
            }

            // Cek apakah ada setidaknya satu fingerprint sertifikat yang sama
            val isMatch = currentSignatures.any { cur ->
                archiveSignatures.any { arc -> cur.equals(arc, ignoreCase = true) }
            }

            result.success(isMatch)
        } catch (_: Exception) {
            // Fallback true jika terjadi error inspeksi
            result.success(true)
        }
    }

    private fun getCurrentAppSignatures(): List<String> {
        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                val packageInfo = packageManager.getPackageInfo(
                    packageName,
                    PackageManager.GET_SIGNING_CERTIFICATES
                )
                val signatures = packageInfo.signingInfo?.signingCertificateHistory
                    ?: packageInfo.signingInfo?.apkContentsSigners
                signatures?.map { sha256Hex(it.toByteArray()) } ?: emptyList()
            } else {
                @Suppress("DEPRECATION")
                val packageInfo = packageManager.getPackageInfo(
                    packageName,
                    PackageManager.GET_SIGNATURES
                )
                @Suppress("DEPRECATION")
                packageInfo.signatures?.map { sha256Hex(it.toByteArray()) } ?: emptyList()
            }
        } catch (_: Exception) {
            emptyList()
        }
    }

    private fun getArchiveSignatures(filePath: String): List<String> {
        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                val archiveInfo = packageManager.getPackageArchiveInfo(
                    filePath,
                    PackageManager.GET_SIGNING_CERTIFICATES
                )
                val signatures = archiveInfo?.signingInfo?.signingCertificateHistory
                    ?: archiveInfo?.signingInfo?.apkContentsSigners
                signatures?.map { sha256Hex(it.toByteArray()) } ?: emptyList()
            } else {
                @Suppress("DEPRECATION")
                val archiveInfo = packageManager.getPackageArchiveInfo(
                    filePath,
                    PackageManager.GET_SIGNATURES
                )
                @Suppress("DEPRECATION")
                archiveInfo?.signatures?.map { sha256Hex(it.toByteArray()) } ?: emptyList()
            }
        } catch (_: Exception) {
            emptyList()
        }
    }

    private fun sha256Hex(bytes: ByteArray): String {
        val md = MessageDigest.getInstance("SHA-256")
        val digest = md.digest(bytes)
        return digest.joinToString("") { "%02x".format(it) }
    }

    private fun exportToPublicDownloads(filePath: String, fileName: String, result: MethodChannel.Result) {
        try {
            val sourceFile = File(filePath)
            if (!sourceFile.exists()) {
                result.error("FILE_NOT_FOUND", "Source file not found at $filePath", null)
                return
            }

            var exportedPath: String? = null

            // 1. Simpan via MediaStore (Android 10 - 15+)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                val contentValues = ContentValues().apply {
                    put(MediaStore.Downloads.DISPLAY_NAME, fileName)
                    put(MediaStore.Downloads.MIME_TYPE, "application/vnd.android.package-archive")
                    put(MediaStore.Downloads.IS_PENDING, 1)
                }
                val resolver = applicationContext.contentResolver
                val uri = resolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, contentValues)
                if (uri != null) {
                    resolver.openOutputStream(uri)?.use { out ->
                        FileInputStream(sourceFile).use { input ->
                            input.copyTo(out)
                        }
                    }
                    contentValues.clear()
                    contentValues.put(MediaStore.Downloads.IS_PENDING, 0)
                    resolver.update(uri, contentValues, null, null)
                    exportedPath = "Download/$fileName"
                }
            }

            // 2. Fallback / Direct copy jika MediaStore tidak menghasilkan path
            if (exportedPath == null) {
                val downloadsDir = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS)
                if (!downloadsDir.exists()) {
                    downloadsDir.mkdirs()
                }
                val destFile = File(downloadsDir, fileName)
                sourceFile.copyTo(destFile, overwrite = true)
                exportedPath = destFile.absolutePath
            }

            result.success(exportedPath)
        } catch (e: Exception) {
            result.error("EXPORT_ERROR", e.message, null)
        }
    }

    private fun promptUninstall(result: MethodChannel.Result) {
        try {
            val intent = Intent(Intent.ACTION_DELETE).apply {
                data = Uri.parse("package:$packageName")
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            startActivity(intent)
            result.success(true)
        } catch (e: Exception) {
            result.error("UNINSTALL_ERROR", e.message, null)
        }
    }

    private fun openDownloadsFolder(result: MethodChannel.Result) {
        try {
            val intent = Intent(DownloadManager.ACTION_VIEW_DOWNLOADS).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            if (intent.resolveActivity(packageManager) != null) {
                startActivity(intent)
                result.success(true)
            } else {
                val fallbackIntent = Intent(Intent.ACTION_GET_CONTENT).apply {
                    type = "*/*"
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                }
                startActivity(fallbackIntent)
                result.success(true)
            }
        } catch (_: Exception) {
            result.success(false)
        }
    }
}
