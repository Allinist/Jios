package com.example.jios.widget

import android.content.Context
import org.json.JSONArray
import org.json.JSONObject

enum class WidgetMode {
    CONFIGURED,
    TODAY,
    BOOK,
    SELECTED,
    ALL,
}

data class WidgetTask(
    val id: Int?,
    val title: String,
    val taskBookId: Int?,
    val status: String?,
    val completed: Boolean,
    val isToday: Boolean,
    val widgetInfo: String,
)

data class WidgetConfig(
    val mode: String,
    val taskBookId: Int?,
    val taskIds: Set<Int>,
)

object DayMasterWidgetHelper {
    private const val PREFS_NAME = "FlutterSharedPreferences"
    private const val TASKS_KEY = "flutter.widget_tasks"

    private fun configKey(mode: WidgetMode): String {
        return when (mode) {
            WidgetMode.BOOK -> "flutter.widget_config_book"
            WidgetMode.SELECTED -> "flutter.widget_config_selected"
            WidgetMode.CONFIGURED -> "flutter.widget_config_configured"
            else -> "flutter.widget_config_configured"
        }
    }

    fun loadTasks(context: Context, mode: WidgetMode): List<WidgetTask> {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val payload = prefs.getString(TASKS_KEY, null) ?: return emptyList()

        val tasks = parseTasks(payload)
        val config = loadConfig(prefs, mode)
        val effectiveMode = when (mode) {
            WidgetMode.CONFIGURED -> when (config.mode) {
                "book" -> WidgetMode.BOOK
                "selected" -> WidgetMode.SELECTED
                "all" -> WidgetMode.ALL
                else -> WidgetMode.TODAY
            }
            else -> mode
        }

        return when (effectiveMode) {
            WidgetMode.BOOK -> {
                if (config.taskBookId != null) {
                    tasks.filter { it.taskBookId == config.taskBookId && !isCompleted(it) }
                } else {
                    tasks.filter { it.isToday && !isCompleted(it) }
                }
            }
            WidgetMode.SELECTED -> {
                if (config.taskIds.isEmpty()) {
                    tasks.filter { it.isToday && !isCompleted(it) }
                } else {
                    tasks.filter { it.id != null && config.taskIds.contains(it.id) && !isCompleted(it) }
                }
            }
            WidgetMode.ALL -> tasks.filter { !isCompleted(it) }
            WidgetMode.TODAY, WidgetMode.CONFIGURED -> tasks.filter { it.isToday && !isCompleted(it) }
        }
    }

    private fun parseTasks(payload: String): List<WidgetTask> {
        return try {
            val root = JSONObject(payload)
            val array = root.optJSONArray("tasks") ?: JSONArray()
            buildList {
                for (i in 0 until array.length()) {
                    val obj = array.optJSONObject(i) ?: continue
                    add(
                        WidgetTask(
                            id = if (obj.has("id") && !obj.isNull("id")) obj.optInt("id") else null,
                            title = obj.optString("title", ""),
                            taskBookId = if (obj.has("task_book_id") && !obj.isNull("task_book_id")) obj.optInt("task_book_id") else null,
                            status = if (obj.has("status") && !obj.isNull("status")) obj.optString("status", null) else null,
                            completed = obj.optBoolean("completed", false),
                            isToday = obj.optBoolean("is_today", false),
                            widgetInfo = obj.optString("widget_info", ""),
                        )
                    )
                }
            }
        } catch (_: Throwable) {
            emptyList()
        }
    }

    private fun loadConfig(
        prefs: android.content.SharedPreferences,
        mode: WidgetMode,
    ): WidgetConfig {
        val key = configKey(mode)
        val text = prefs.getString(key, null)
            ?: prefs.getString("flutter.widget_config", null)
            ?: ""

        if (text.isEmpty()) {
            return WidgetConfig(mode = "today", taskBookId = null, taskIds = emptySet())
        }

        return try {
            val obj = JSONObject(text)
            val idsArray = obj.optJSONArray("task_ids") ?: JSONArray()
            val ids = mutableSetOf<Int>()
            for (i in 0 until idsArray.length()) {
                ids.add(idsArray.optInt(i))
            }
            WidgetConfig(
                mode = obj.optString("mode", "today"),
                taskBookId = if (obj.has("task_book_id") && !obj.isNull("task_book_id")) obj.optInt("task_book_id") else null,
                taskIds = ids,
            )
        } catch (_: Throwable) {
            WidgetConfig(mode = "today", taskBookId = null, taskIds = emptySet())
        }
    }

    private fun isCompleted(task: WidgetTask): Boolean {
        return task.completed || task.status == "completed"
    }
}
