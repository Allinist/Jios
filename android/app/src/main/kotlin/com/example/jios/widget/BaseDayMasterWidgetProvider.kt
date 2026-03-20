package com.example.jios.widget

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.widget.RemoteViews
import com.example.jios.MainActivity
import com.example.jios.R

abstract class BaseDayMasterWidgetProvider : AppWidgetProvider() {
    protected abstract val mode: WidgetMode
    protected abstract val title: String

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        appWidgetIds.forEach { appWidgetId ->
            updateSingleWidget(context, appWidgetManager, appWidgetId)
        }
    }

    override fun onAppWidgetOptionsChanged(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: Bundle,
    ) {
        super.onAppWidgetOptionsChanged(context, appWidgetManager, appWidgetId, newOptions)
        updateSingleWidget(context, appWidgetManager, appWidgetId)
    }

    protected fun updateSingleWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
    ) {
        val tasks = DayMasterWidgetHelper.loadTasks(context, mode)
        val views = RemoteViews(context.packageName, R.layout.daymaster_widget)
        views.setTextViewText(R.id.widgetTitle, title)

        val maxLines = lineCountBySize(appWidgetManager, appWidgetId)
        bindLines(views, tasks, maxLines)
        bindOpenAppIntent(context, views)

        appWidgetManager.updateAppWidget(appWidgetId, views)
    }

    private fun bindLines(views: RemoteViews, tasks: List<WidgetTask>, maxLines: Int) {
        val lineIds = intArrayOf(
            R.id.widgetLine1,
            R.id.widgetLine2,
            R.id.widgetLine3,
            R.id.widgetLine4,
            R.id.widgetLine5,
            R.id.widgetLine6,
            R.id.widgetLine7,
            R.id.widgetLine8,
            R.id.widgetLine9,
            R.id.widgetLine10,
            R.id.widgetLine11,
            R.id.widgetLine12,
            R.id.widgetLine13,
            R.id.widgetLine14,
        )

        lineIds.forEachIndexed { index, viewId ->
            if (index < maxLines && index < tasks.size) {
                val task = tasks[index]
                val lineText = if (task.widgetInfo.isBlank()) {
                    task.title
                } else {
                    "${task.title}  ${task.widgetInfo}"
                }
                views.setTextViewText(viewId, lineText)
                views.setViewVisibility(viewId, android.view.View.VISIBLE)
            } else {
                views.setViewVisibility(viewId, android.view.View.GONE)
            }
        }

        if (tasks.isEmpty()) {
            views.setViewVisibility(R.id.widgetEmpty, android.view.View.VISIBLE)
            views.setTextViewText(R.id.widgetEmpty, "无任务")
        } else {
            views.setViewVisibility(R.id.widgetEmpty, android.view.View.GONE)
        }
    }

    private fun bindOpenAppIntent(context: Context, views: RemoteViews) {
        val intent = Intent(context, MainActivity::class.java)
        val pendingIntent = PendingIntent.getActivity(
            context,
            0,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        views.setOnClickPendingIntent(R.id.widgetRoot, pendingIntent)
    }

    private fun lineCountBySize(appWidgetManager: AppWidgetManager, appWidgetId: Int): Int {
        val options = appWidgetManager.getAppWidgetOptions(appWidgetId)
        val minHeightDp = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT)
        return when {
            minHeightDp >= 250 -> 14
            minHeightDp >= 180 -> 10
            minHeightDp >= 120 -> 6
            else -> 4
        }
    }

    companion object {
        fun refreshAll(context: Context) {
            val appWidgetManager = AppWidgetManager.getInstance(context)
            val providers = listOf(
                DayMasterConfiguredWidgetProvider::class.java,
                DayMasterTodayWidgetProvider::class.java,
                DayMasterTaskBookWidgetProvider::class.java,
                DayMasterSelectedWidgetProvider::class.java,
                DayMasterAllWidgetProvider::class.java,
            )

            providers.forEach { clazz ->
                val component = ComponentName(context, clazz)
                val ids = appWidgetManager.getAppWidgetIds(component)
                if (ids.isEmpty()) return@forEach
                val provider = clazz.getDeclaredConstructor().newInstance()
                provider.onUpdate(context, appWidgetManager, ids)
            }
        }
    }
}
