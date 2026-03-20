package com.example.jios.notification

import android.Manifest
import android.app.AlarmManager
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.os.Build
import androidx.core.app.ActivityCompat
import androidx.core.app.NotificationManagerCompat
import org.json.JSONObject

object TaskNotificationScheduler {
    private const val PREFS_NAME = "task_notifications"
    private const val ENTRY_PREFIX = "entry_"
    private const val CHANNEL_ID = "task_reminder_channel"

    private const val TYPE_START_AT = "start_at"
    private const val TYPE_START_BEFORE = "start_before"
    private const val TYPE_END_AT = "end_at"
    private const val TYPE_END_BEFORE = "end_before"

    fun requestPermission(activity: android.app.Activity) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            ActivityCompat.requestPermissions(
                activity,
                arrayOf(Manifest.permission.POST_NOTIFICATIONS),
                3001,
            )
        }
    }

    fun syncTaskNotifications(context: Context, args: Map<*, *>) {
        val taskId = (args["task_id"] as? Number)?.toInt() ?: return
        cancelTaskNotifications(context, taskId)

        val status = (args["status"] as? String) ?: "active"
        if (status == "completed") {
            clearStoredTask(context, taskId)
            return
        }

        storeTaskArgs(context, taskId, args)

        val title = (args["title"] as? String)?.ifBlank { "任务提醒" } ?: "任务提醒"
        val startMillis = (args["start_date"] as? Number)?.toLong()
        val endMillis = (args["end_date"] as? Number)?.toLong()
        val notifyAtStart = (args["notify_at_start"] as? Boolean) ?: false
        val notifyAtEnd = (args["notify_at_end"] as? Boolean) ?: false
        val notifyBeforeStartMinutes = (args["notify_before_start_minutes"] as? Number)?.toLong()
        val notifyBeforeEndMinutes = (args["notify_before_end_minutes"] as? Number)?.toLong()

        if (notifyAtStart && startMillis != null) {
            schedule(
                context = context,
                taskId = taskId,
                type = TYPE_START_AT,
                title = "任务开始提醒",
                body = title,
                triggerAt = startMillis,
            )
        }

        if (startMillis != null && notifyBeforeStartMinutes != null && notifyBeforeStartMinutes > 0) {
            val triggerAt = startMillis - notifyBeforeStartMinutes * 60_000L
            schedule(
                context = context,
                taskId = taskId,
                type = TYPE_START_BEFORE,
                title = "任务即将开始",
                body = "$title（${notifyBeforeStartMinutes}分钟前）",
                triggerAt = triggerAt,
            )
        }

        if (notifyAtEnd && endMillis != null) {
            schedule(
                context = context,
                taskId = taskId,
                type = TYPE_END_AT,
                title = "任务结束提醒",
                body = title,
                triggerAt = endMillis,
            )
        }

        if (endMillis != null && notifyBeforeEndMinutes != null && notifyBeforeEndMinutes > 0) {
            val triggerAt = endMillis - notifyBeforeEndMinutes * 60_000L
            schedule(
                context = context,
                taskId = taskId,
                type = TYPE_END_BEFORE,
                title = "任务即将结束",
                body = "$title（${notifyBeforeEndMinutes}分钟前）",
                triggerAt = triggerAt,
            )
        }
    }

    fun cancelTaskNotifications(context: Context, taskId: Int) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val types = listOf(TYPE_START_AT, TYPE_START_BEFORE, TYPE_END_AT, TYPE_END_BEFORE)
        for (type in types) {
            val pending = buildPendingIntent(
                context = context,
                taskId = taskId,
                type = type,
                title = "",
                body = "",
                flags = PendingIntent.FLAG_NO_CREATE or PendingIntent.FLAG_IMMUTABLE,
            )
            if (pending != null) {
                alarmManager.cancel(pending)
                pending.cancel()
            }
        }
        clearStoredTask(context, taskId)
    }

    fun restoreAll(context: Context) {
        val prefs = prefs(context)
        val entries = prefs.all
            .filterKeys { it.startsWith(ENTRY_PREFIX) }
            .values
            .mapNotNull { it as? String }

        for (text in entries) {
            try {
                val obj = JSONObject(text)
                val args = mutableMapOf<String, Any?>()
                val names = obj.keys()
                while (names.hasNext()) {
                    val key = names.next()
                    args[key] = obj.get(key)
                }
                syncTaskNotifications(context, args)
            } catch (_: Throwable) {
            }
        }
    }

    private fun schedule(
        context: Context,
        taskId: Int,
        type: String,
        title: String,
        body: String,
        triggerAt: Long,
    ) {
        if (triggerAt <= System.currentTimeMillis()) {
            return
        }

        ensureChannel(context)

        val intent = Intent(context, TaskNotificationReceiver::class.java).apply {
            putExtra("task_id", taskId)
            putExtra("type", type)
            putExtra("title", title)
            putExtra("body", body)
        }

        val pendingIntent = PendingIntent.getBroadcast(
            context,
            requestCode(taskId, type),
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        alarmManager.set(AlarmManager.RTC_WAKEUP, triggerAt, pendingIntent)
    }

    fun buildPendingIntent(
        context: Context,
        taskId: Int,
        type: String,
        title: String,
        body: String,
        flags: Int,
    ): PendingIntent? {
        val intent = Intent(context, TaskNotificationReceiver::class.java).apply {
            putExtra("task_id", taskId)
            putExtra("type", type)
            putExtra("title", title)
            putExtra("body", body)
        }
        return PendingIntent.getBroadcast(context, requestCode(taskId, type), intent, flags)
    }

    private fun requestCode(taskId: Int, type: String): Int {
        return taskId * 10_000 + (kotlin.math.abs(type.hashCode()) % 10_000)
    }

    private fun ensureChannel(context: Context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            return
        }

        val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        val existing = manager.getNotificationChannel(CHANNEL_ID)
        if (existing != null) {
            return
        }

        val channel = NotificationChannel(
            CHANNEL_ID,
            "任务提醒",
            NotificationManager.IMPORTANCE_DEFAULT,
        ).apply {
            description = "任务开始/结束提醒"
        }
        manager.createNotificationChannel(channel)
    }

    fun canPostNotification(context: Context): Boolean {
        return NotificationManagerCompat.from(context).areNotificationsEnabled()
    }

    fun channelId(): String = CHANNEL_ID

    private fun prefs(context: Context): SharedPreferences {
        return context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
    }

    private fun storeTaskArgs(context: Context, taskId: Int, args: Map<*, *>) {
        val obj = JSONObject()
        args.forEach { (k, v) ->
            if (k is String) {
                obj.put(k, v)
            }
        }
        prefs(context).edit().putString("$ENTRY_PREFIX$taskId", obj.toString()).apply()
    }

    private fun clearStoredTask(context: Context, taskId: Int) {
        prefs(context).edit().remove("$ENTRY_PREFIX$taskId").apply()
    }
}
