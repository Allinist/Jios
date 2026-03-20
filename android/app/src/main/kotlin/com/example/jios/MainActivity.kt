package com.example.jios

import android.content.Context
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel
import com.example.jios.widget.BaseDayMasterWidgetProvider

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "widget_refresh")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "reload" -> {
                        BaseDayMasterWidgetProvider.refreshAll(this)
                        result.success(null)
                    }
                    "save_shared_string" -> {
                        val args = call.arguments as? Map<*, *>
                        val key = args?.get("key") as? String
                        val value = args?.get("value") as? String
                        if (key == null || value == null) {
                            result.error("invalid_arguments", "Expected key/value", null)
                        } else {
                            val suite = (args["suite"] as? String)?.takeIf { it.isNotBlank() }
                            val prefsName = if (suite == null) "FlutterSharedPreferences" else "FlutterSharedPreferences"
                            val prefs = getSharedPreferences(prefsName, Context.MODE_PRIVATE)
                            prefs.edit().putString("flutter.$key", value).apply()
                            result.success(null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
