package com.saadhjawwadh.notebook

import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.Context
import android.app.KeyguardManager
import android.os.PowerManager
import android.os.Build
import android.content.Intent
import android.content.IntentFilter
import android.content.BroadcastReceiver
import android.os.Bundle
import android.net.Uri
import java.io.File
import java.io.FileOutputStream
import java.io.InputStream
import android.appwidget.AppWidgetManager
import android.content.ComponentName

class MainActivity: FlutterFragmentActivity() {
    private val CHANNEL = "com.saadhjawwadh.notebook/device_lock"
    private val WIDGET_CHANNEL = "com.saadhjawwadh.notebook/widget"
    private var screenOffLock = false
    private var receiver: BroadcastReceiver? = null
    private var pendingWidgetAction: String? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        handleIntent(intent)
        val filter = IntentFilter(Intent.ACTION_SCREEN_OFF)
        receiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context?, intent: Intent?) {
                screenOffLock = true
            }
        }
        registerReceiver(receiver, filter)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleIntent(intent)
    }

    private fun handleIntent(intent: Intent?) {
        if (intent?.action == "com.saadhjawwadh.notebook.ADD_TRANSACTION") {
            pendingWidgetAction = "add_transaction"
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        receiver?.let {
            try {
                unregisterReceiver(it)
            } catch (e: Exception) {
                // Ignore
            }
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "isDeviceLocked") {
                val isLocked = checkIsDeviceLocked() || screenOffLock
                result.success(isLocked)
            } else if (call.method == "resetLockFlag") {
                screenOffLock = false
                result.success(true)
            } else if (call.method == "copyContentUriToTempFile") {
                val uriString = call.argument<String>("uri")
                if (uriString != null) {
                    val tempFilePath = copyContentUriToTempFile(this, uriString)
                    result.success(tempFilePath)
                } else {
                    result.error("INVALID_ARGUMENT", "URI is null", null)
                }
            } else {
                result.notImplemented()
            }
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, WIDGET_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "updateWidget" -> {
                    val context = this@MainActivity
                    val intent = Intent(context, FinanceWidgetProvider::class.java).apply {
                        action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
                    }
                    val ids = AppWidgetManager.getInstance(context).getAppWidgetIds(
                        ComponentName(context, FinanceWidgetProvider::class.java)
                    )
                    intent.putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, ids)
                    context.sendBroadcast(intent)
                    result.success(true)
                }
                "getPendingAction" -> {
                    result.success(pendingWidgetAction)
                    pendingWidgetAction = null
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun checkIsDeviceLocked(): Boolean {
        val keyguardManager = getSystemService(Context.KEYGUARD_SERVICE) as KeyguardManager
        val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
        
        val isInteractive = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT_WATCH) {
            powerManager.isInteractive
        } else {
            @Suppress("DEPRECATION")
            powerManager.isScreenOn
        }
 
        if (!isInteractive) {
            return true
        }

        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP_MR1) {
            keyguardManager.isDeviceLocked
        } else {
            keyguardManager.isKeyguardLocked
        }
    }

    private fun copyContentUriToTempFile(context: Context, uriString: String): String? {
        try {
            val uri = Uri.parse(uriString)
            val inputStream: InputStream? = context.contentResolver.openInputStream(uri)
            if (inputStream != null) {
                val fileName = getFileName(context, uri) ?: "shared_file_${System.currentTimeMillis()}"
                val tempFile = File(context.cacheDir, fileName)
                val outputStream = FileOutputStream(tempFile)
                val buffer = ByteArray(4 * 1024)
                var bytesRead: Int
                while (inputStream.read(buffer).also { bytesRead = it } != -1) {
                    outputStream.write(buffer, 0, bytesRead)
                }
                outputStream.close()
                inputStream.close()
                return tempFile.absolutePath
            }
        } catch (e: Exception) {
            android.util.Log.e("MainActivity", "Error copying content URI to temp file", e)
        }
        return null
    }

    private fun getFileName(context: Context, uri: Uri): String? {
        var result: String? = null
        if (uri.scheme == "content") {
            val cursor = context.contentResolver.query(uri, null, null, null, null)
            cursor?.use {
                if (it.moveToFirst()) {
                    val displayNameIndex = it.getColumnIndex(android.provider.OpenableColumns.DISPLAY_NAME)
                    if (displayNameIndex != -1) {
                        result = it.getString(displayNameIndex)
                    }
                }
            }
        }
        if (result == null) {
            result = uri.path
            val cut = result?.lastIndexOf('/') ?: -1
            if (cut != -1) {
                result = result?.substring(cut + 1)
            }
        }
        return result
    }
}
