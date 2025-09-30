package com.ansah.shots_studio

import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.provider.Settings
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private val CHANNEL = "update_installer"
    private val TASKER_CHANNEL = "tasker_integration"
    private val INSTALL_REQUEST_CODE = 1001

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "canRequestPackageInstalls" -> {
                    result.success(canRequestPackageInstalls())
                }
                "requestInstallPermission" -> {
                    requestInstallPermission()
                    result.success(true)
                }
                "installApk" -> {
                    val apkPath = call.argument<String>("apkPath")
                    if (apkPath != null) {
                        try {
                            installApk(apkPath)
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("INSTALL_ERROR", e.message, null)
                        }
                    } else {
                        result.error("INVALID_ARGUMENT", "APK path is required", null)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
        
        // Tasker integration channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, TASKER_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "broadcastScreenshotEvent" -> {
                    val eventType = call.argument<String>("eventType")
                    val eventData = call.argument<Map<String, Any?>>("eventData")
                    if (eventType != null && eventData != null) {
                        try {
                            broadcastTaskerEvent(eventType, eventData)
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("BROADCAST_ERROR", e.message, null)
                        }
                    } else {
                        result.error("INVALID_ARGUMENT", "Event type and data are required", null)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun canRequestPackageInstalls(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            packageManager.canRequestPackageInstalls()
        } else {
            true // On older versions, this permission is granted by default
        }
    }

    private fun requestInstallPermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            if (!packageManager.canRequestPackageInstalls()) {
                val intent = Intent(Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES).apply {
                    data = Uri.parse("package:$packageName")
                }
                startActivityForResult(intent, INSTALL_REQUEST_CODE)
            }
        }
    }

    private fun installApk(apkPath: String) {
        val apkFile = File(apkPath)
        if (!apkFile.exists()) {
            throw Exception("APK file not found: $apkPath")
        }

        val intent = Intent(Intent.ACTION_VIEW).apply {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                // Use FileProvider for Android N and above
                val apkUri = FileProvider.getUriForFile(
                    this@MainActivity,
                    "$packageName.fileprovider",
                    apkFile
                )
                setDataAndType(apkUri, "application/vnd.android.package-archive")
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            } else {
                // Direct file access for older versions
                setDataAndType(Uri.fromFile(apkFile), "application/vnd.android.package-archive")
            }
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }

        startActivity(intent)
    }
    
    private fun broadcastTaskerEvent(eventType: String, eventData: Map<String, Any?>) {
        val intent = Intent("com.shotsstudio.TASKER_EVENT").apply {
            `package` = "net.dinglisch.android.taskerm"
            putExtra("event_type", eventType)
            // Add all event data as extras
            eventData.forEach { (key, value) ->
                when (value) {
                    is String -> putExtra(key, value)
                    is Int -> putExtra(key, value)
                    is Long -> putExtra(key, value)
                    is Boolean -> putExtra(key, value)
                    is Double -> putExtra(key, value)
                    is Float -> putExtra(key, value)
                    // Add other types as needed
                }
            }
        }
        sendBroadcast(intent)
    }
}
