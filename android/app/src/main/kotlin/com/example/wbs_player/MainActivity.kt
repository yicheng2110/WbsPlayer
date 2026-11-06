package com.example.wbs_player

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private val installerChannel = "wbs_player/apk_installer"
    private var pendingInstallResult: MethodChannel.Result? = null
    private var pendingApkPath: String? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, installerChannel)
            .setMethodCallHandler { call, result ->
                if (call.method != "installApk") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                val path = call.argument<String>("path")
                if (path.isNullOrBlank() || !File(path).isFile) {
                    result.error("apk_not_found", "APK file does not exist", null)
                    return@setMethodCallHandler
                }
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O &&
                    !packageManager.canRequestPackageInstalls()
                ) {
                    pendingInstallResult = result
                    pendingApkPath = path
                    startActivity(
                        Intent(
                            Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES,
                            Uri.parse("package:$packageName"),
                        ),
                    )
                    return@setMethodCallHandler
                }
                openApkInstaller(path, result)
            }
    }

    override fun onResume() {
        super.onResume()
        val result = pendingInstallResult ?: return
        val path = pendingApkPath
        pendingInstallResult = null
        pendingApkPath = null
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O &&
            !packageManager.canRequestPackageInstalls()
        ) {
            result.success("permission_denied")
        } else if (path != null) {
            openApkInstaller(path, result)
        } else {
            result.error("apk_not_found", "APK file does not exist", null)
        }
    }

    private fun openApkInstaller(path: String, result: MethodChannel.Result) {
        try {
            val apk = File(path)
            val uri = FileProvider.getUriForFile(
                this,
                "$packageName.apkprovider",
                apk,
            )
            val intent = Intent(Intent.ACTION_VIEW).apply {
                setDataAndType(uri, "application/vnd.android.package-archive")
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            startActivity(intent)
            result.success("opened")
        } catch (error: Exception) {
            result.error("installer_failed", error.message, null)
        }
    }
}
