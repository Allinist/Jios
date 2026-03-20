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
  static const int _displayElapsed = 1;
  static const int _displayRemaining = 2;
  static const int _displayDuration = 4;
  static const int _displaySinceLast = 8;
  static const int _displayUntilNext = 16;

  static const platform = MethodChannel('widget_refresh');
  static const String _iosAppGroup = 'group.com.example.jios';

  static const String _tasksKey = 'widget_tasks';
  static const String _legacyConfigKey = 'widget_config';
  static const String _configPrefix = 'widget_config_';

  static const String scopeConfigured = 'configured';
  static const String scopeBook = 'book';
  static const String scopeSelected = 'selected';

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
      final timelineLines = _buildTimelineLines(task, rule, today);
      final scopes = _parseWidgetScopes(task.widgetDisplayScopes);

      return {
        'id': task.id,
        'title': task.title,
        'task_book_id': task.taskBookId,
        'status': task.status,
        'completed': task.status == 'completed',
        'is_today': isToday,
        'timeline_lines': timelineLines,
        'widget_scopes': scopes,
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

  static List<String> _buildTimelineLines(Task task, RepeatRule? rule, DateTime now) {
    final lines = <String>[];
    final mask = task.timelineDisplayMask ?? (_displayElapsed | _displayRemaining | _displayDuration);
    final granularity = _parseGranularity(task.timelineGranularity);

    if ((mask & _displayElapsed) != 0 && task.startDate != null) {
      final start = DateTime.fromMillisecondsSinceEpoch(task.startDate!);
      if (now.isAfter(start)) {
        lines.add('已开始${_formatDuration(now.difference(start), granularity)}');
      }
    }

    if ((mask & _displayRemaining) != 0 && task.endDate != null) {
      final end = DateTime.fromMillisecondsSinceEpoch(task.endDate!);
      if (end.isAfter(now)) {
        lines.add('剩余${_formatDuration(end.difference(now), granularity)}');
      }
    }

    if ((mask & _displayDuration) != 0 && task.expectedDuration != null && task.expectedDuration! > 0) {
      lines.add('持续${_formatHoursMinutes(task.expectedDuration!)}');
    }

    if ((mask & _displaySinceLast) != 0 && rule != null) {
      final previous = _findPreviousOccurrence(task, rule, now);
      if (previous != null) {
        lines.add('距上次${_formatDuration(now.difference(previous), granularity)}');
      }
    }

    if ((mask & _displayUntilNext) != 0 && rule != null) {
      final next = _findNextOccurrence(task, rule, now);
      if (next != null && next.isAfter(now)) {
        lines.add('距下次${_formatDuration(next.difference(now), granularity)}');
      }
    }

    return lines;
  }

  static List<String> _parseGranularity(String? text) {
    final defaults = ['day', 'hour'];
    if (text == null || text.trim().isEmpty) {
      return defaults;
    }

    final list = text
        .split(',')
        .map((e) => e.trim())
        .where((e) => ['year', 'month', 'day', 'hour', 'minute'].contains(e))
        .toList();

    return list.isEmpty ? defaults : list;
  }

  static String _formatDuration(Duration duration, List<String> granularity) {
    int minutes = duration.inMinutes;

    final units = <String>[];
    final definitions = [
      ('year', 60 * 24 * 365, '年'),
      ('month', 60 * 24 * 30, '月'),
      ('day', 60 * 24, '天'),
      ('hour', 60, '小时'),
      ('minute', 1, '分钟'),
    ];

    for (final (key, value, label) in definitions) {
      if (!granularity.contains(key)) {
        continue;
      }

      final count = minutes ~/ value;
      minutes = minutes % value;

      if (count > 0 || (key == 'minute' && units.isEmpty)) {
        units.add('$count$label');
      }
    }

    return units.isEmpty ? '0分钟' : units.join('');
  }

  static String _formatHoursMinutes(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return '$h小时 $m分钟';
  }

  static DateTime? _findPreviousOccurrence(Task task, RepeatRule rule, DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    for (int i = 1; i <= 1460; i++) {
      final day = today.subtract(Duration(days: i));
      if (TaskScheduler.shouldShowTask(task, rule, day)) {
        return day;
      }
    }
    return null;
  }

  static DateTime? _findNextOccurrence(Task task, RepeatRule rule, DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    for (int i = 1; i <= 1460; i++) {
      final day = today.add(Duration(days: i));
      if (TaskScheduler.shouldShowTask(task, rule, day)) {
        return day;
      }
    }
    return null;
  }

  static List<String> _parseWidgetScopes(String? raw) {
    const all = ['small', 'medium', 'large', 'lockscreen'];
    if (raw == null || raw.trim().isEmpty) {
      return all;
    }
    final list = raw
        .split(',')
        .map((e) => e.trim())
        .where((e) => all.contains(e))
        .toList();
    return list.isEmpty ? all : list;
  }

  static Future<void> saveWidgetConfig({
    required String scope,
    required String mode,
    int? taskBookId,
    List<int>? taskIds,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _configKey(scope);
    final payload = jsonEncode({
      'mode': mode,
      'task_book_id': taskBookId,
      'task_ids': taskIds ?? [],
    });

    await prefs.setString(key, payload);
    await _saveSharedStringForIOS(key: key, value: payload);

    if (scope == scopeConfigured) {
      await prefs.setString(_legacyConfigKey, payload);
      await _saveSharedStringForIOS(key: _legacyConfigKey, value: payload);
    }
  }

  static Future<Map<String, dynamic>> loadWidgetConfig({
    required String scope,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _configKey(scope);
    final text = prefs.getString(key) ??
        (scope == scopeConfigured ? prefs.getString(_legacyConfigKey) : null);

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

  static String _configKey(String scope) {
    return '$_configPrefix$scope';
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
