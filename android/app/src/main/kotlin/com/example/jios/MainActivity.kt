package com.example.jios

import android.content.ComponentName
import android.content.Context
import android.content.pm.PackageManager
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel
import com.example.jios.widget.BaseDayMasterWidgetProvider
import com.example.jios.notification.TaskNotificationScheduler

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

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "app_icon")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "set_app_icon" -> {
                        val args = call.arguments as? Map<*, *>
                        val variant = args?.get("variant") as? String ?: "PinkLogo"
                        setLauncherAlias(variant)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "task_notification")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "request_permission" -> {
                        TaskNotificationScheduler.requestPermission(this)
                        result.success(null)
                    }
                    "cancel_task_notifications" -> {
                        val args = call.arguments as? Map<*, *>
                        val taskId = (args?.get("task_id") as? Number)?.toInt()
                        if (taskId != null) {
                            TaskNotificationScheduler.cancelTaskNotifications(this, taskId)
                        }
                        result.success(null)
                    }
                    "sync_task_notifications" -> {
                        val args = call.arguments as? Map<*, *> ?: emptyMap<String, Any?>()
                        TaskNotificationScheduler.syncTaskNotifications(this, args)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun setLauncherAlias(variant: String) {
        val pinkAlias = ComponentName(this, "com.example.jios.PinkLauncherAlias")
        val blueAlias = ComponentName(this, "com.example.jios.BlueLauncherAlias")

        val pinkState = if (variant == "BlueLogo") {
            PackageManager.COMPONENT_ENABLED_STATE_DISABLED
        } else {
            PackageManager.COMPONENT_ENABLED_STATE_ENABLED
        }

        val blueState = if (variant == "BlueLogo") {
            PackageManager.COMPONENT_ENABLED_STATE_ENABLED
        } else {
            PackageManager.COMPONENT_ENABLED_STATE_DISABLED
        }

        packageManager.setComponentEnabledSetting(
            pinkAlias,
            pinkState,
            PackageManager.DONT_KILL_APP,
        )
        packageManager.setComponentEnabledSetting(
            blueAlias,
            blueState,
            PackageManager.DONT_KILL_APP,
        )
    }
}
