package com.example.jios.notification

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import com.example.jios.R

class TaskNotificationReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (!TaskNotificationScheduler.canPostNotification(context)) {
            return
        }

        val taskId = intent.getIntExtra("task_id", -1)
        val type = intent.getStringExtra("type") ?: ""
        val title = intent.getStringExtra("title") ?: "任务提醒"
        val body = intent.getStringExtra("body") ?: ""

        val notification = NotificationCompat.Builder(context, TaskNotificationScheduler.channelId())
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(title)
            .setContentText(body)
            .setAutoCancel(true)
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
            .build()

        val notificationId = taskId * 10_000 + (kotlin.math.abs(type.hashCode()) % 10_000)
        NotificationManagerCompat.from(context).notify(notificationId, notification)
    }
}
