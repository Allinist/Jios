import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/taskScheduler.dart';
import '../database/dao/repeatRuleDao.dart';
import '../database/dao/taskBookDao.dart';
import '../database/dao/taskDao.dart';
import '../models/repeatRule.dart';
import '../models/task.dart';

class WidgetService {
  static const platform = MethodChannel('widget_refresh');
  static const String _iosAppGroup = 'group.com.example.jios';

  static const String _tasksKey = 'widget_tasks';
  static const String _configKey = 'widget_config';

  static Future<void> syncWidgetData() async {
    final prefs = await SharedPreferences.getInstance();
    final taskDao = TaskDao();
    final taskBookDao = TaskBookDao();
    final ruleDao = RepeatRuleDao();

    final tasks = await taskDao.getAll();
    final books = await taskBookDao.getAll();

    final Map<int, RepeatRule?> ruleMap = {};
    for (final task in tasks) {
      final id = task.repeatRuleId;
      if (id == null || ruleMap.containsKey(id)) continue;
      ruleMap[id] = await ruleDao.getById(id);
    }

    final today = DateTime.now();

    final data = tasks.map((task) {
      final rule = task.repeatRuleId == null ? null : ruleMap[task.repeatRuleId!];
      final isToday = TaskScheduler.shouldShowTask(task, rule, today);

      return {
        'id': task.id,
        'title': task.title,
        'task_book_id': task.taskBookId,
        'status': task.status,
        'completed': task.status == 'completed',
        'is_today': isToday,
        'time': _buildTime(task),
      };
    }).toList();

    final bookData = books
        .map(
          (book) => {
            'id': book.id,
            'name': book.name,
          },
        )
        .toList();

    final payload = jsonEncode({
      'tasks': data,
      'task_books': bookData,
      'updated_at': DateTime.now().millisecondsSinceEpoch,
    });

    await prefs.setString(_tasksKey, payload);
    await _saveSharedStringForIOS(key: _tasksKey, value: payload);
  }

  static String _buildTime(Task task) {
    if (task.endDate != null) {
      final end = DateTime.fromMillisecondsSinceEpoch(task.endDate!);
      final y = end.year;
      final m = end.month.toString().padLeft(2, '0');
      final d = end.day.toString().padLeft(2, '0');
      final hh = end.hour.toString().padLeft(2, '0');
      final mm = end.minute.toString().padLeft(2, '0');
      return '$y-$m-$d $hh:$mm 截止';
    }

    if (task.startDate != null) {
      final start = DateTime.fromMillisecondsSinceEpoch(task.startDate!);
      final y = start.year;
      final m = start.month.toString().padLeft(2, '0');
      final d = start.day.toString().padLeft(2, '0');
      final hh = start.hour.toString().padLeft(2, '0');
      final mm = start.minute.toString().padLeft(2, '0');
      return '$y-$m-$d $hh:$mm 开始';
    }

    return '';
  }

  static Future<void> saveWidgetConfig({
    required String mode,
    int? taskBookId,
    List<int>? taskIds,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final payload = jsonEncode({
      'mode': mode,
      'task_book_id': taskBookId,
      'task_ids': taskIds ?? [],
    });

    await prefs.setString(_configKey, payload);
    await _saveSharedStringForIOS(key: _configKey, value: payload);
  }

  static Future<Map<String, dynamic>> loadWidgetConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final text = prefs.getString(_configKey);

    if (text == null || text.isEmpty) {
      return {
        'mode': 'today',
        'task_book_id': null,
        'task_ids': <int>[],
      };
    }

    try {
      final decoded = jsonDecode(text);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('invalid config');
      }

      return {
        'mode': decoded['mode'] ?? 'today',
        'task_book_id': decoded['task_book_id'],
        'task_ids': (decoded['task_ids'] as List? ?? []).whereType<int>().toList(),
      };
    } catch (_) {
      return {
        'mode': 'today',
        'task_book_id': null,
        'task_ids': <int>[],
      };
    }
  }

  static Future<void> refreshWidget() async {
    try {
      await platform.invokeMethod('reload');
    } catch (_) {}
  }

  static Future<void> _saveSharedStringForIOS({
    required String key,
    required String value,
  }) async {
    try {
      await platform.invokeMethod('save_shared_string', {
        'suite': _iosAppGroup,
        'key': key,
        'value': value,
      });
    } catch (_) {}
  }
}
