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
import android.appwidget.AppWidgetManager
import android.content.ComponentName

class MainActivity: FlutterFragmentActivity() {
    private val CHANNEL = "com.saadhjawwadh.notebook/device_lock"
    private val WIDGET_CHANNEL = "com.saadhjawwadh.notebook/widget"
    private var screenOffLock = false
    private var receiver: BroadcastReceiver? = null
    private var pendingWidgetAction: String? = null
    private var pendingSharedText: String? = null

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
        when (intent?.action) {
            "com.saadhjawwadh.notebook.ADD_TRANSACTION" -> pendingWidgetAction = "add_transaction"
            "com.saadhjawwadh.notebook.VIEW_BUDGETS" -> pendingWidgetAction = "view_budgets"
            "com.saadhjawwadh.notebook.NEW_NOTE" -> pendingWidgetAction = "new_note"
            "com.saadhjawwadh.notebook.SEARCH" -> pendingWidgetAction = "search"
            Intent.ACTION_PROCESS_TEXT -> {
                val text = intent.getCharSequenceExtra(Intent.EXTRA_PROCESS_TEXT)?.toString()
                if (!text.isNullOrEmpty()) {
                    pendingSharedText = text
                    pendingWidgetAction = "process_text"
                }
            }
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
                "getPendingSharedText" -> {
                    result.success(pendingSharedText)
                    pendingSharedText = null
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

}
