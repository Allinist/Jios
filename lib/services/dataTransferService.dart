import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../database/databaseHelper.dart';
import 'widgetServices.dart';

class DataTransferService {
  static const int _schemaVersion = 2;

  static const List<String> _tables = [
    'task_books',
    'repeat_rules',
    'tasks',
    'task_records',
  ];

  static Future<String> exportAllAsJson() async {
    final db = await DatabaseHelper.instance.database;

    final Map<String, dynamic> tableData = {};

    for (final table in _tables) {
      tableData[table] = await db.query(table);
    }

    final widgetConfigs = <String, dynamic>{
      WidgetService.scopeConfigured: await WidgetService.loadWidgetConfig(
        scope: WidgetService.scopeConfigured,
      ),
      WidgetService.scopeBook: await WidgetService.loadWidgetConfig(
        scope: WidgetService.scopeBook,
      ),
      WidgetService.scopeSelected: await WidgetService.loadWidgetConfig(
        scope: WidgetService.scopeSelected,
      ),
      WidgetService.scopeLockSelected: await WidgetService.loadWidgetConfig(
        scope: WidgetService.scopeLockSelected,
      ),
    };

    final payload = {
      'schema_version': _schemaVersion,
      'exported_at': DateTime.now().millisecondsSinceEpoch,
      'tables': tableData,
      'widget_configs': widgetConfigs,
    };

    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  static Future<void> importAllFromJson(String jsonText) async {
    final decoded = jsonDecode(jsonText);

    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('JSON 顶层结构必须是对象');
    }

    final tablesRaw = decoded['tables'];

    if (tablesRaw is! Map) {
      throw const FormatException('缺少 tables 字段');
    }

    final db = await DatabaseHelper.instance.database;

    await db.transaction((txn) async {
      await txn.delete('task_records');
      await txn.delete('tasks');
      await txn.delete('repeat_rules');
      await txn.delete('task_books');

      for (final table in _tables) {
        final rows = tablesRaw[table];

        if (rows == null) {
          continue;
        }

        if (rows is! List) {
          throw FormatException('表 $table 的数据必须是数组');
        }

        for (final row in rows) {
          if (row is! Map) {
            throw FormatException('表 $table 的每一行必须是对象');
          }

          final map = Map<String, dynamic>.from(row);

          await txn.insert(
            table,
            map,
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      }
    });

    final widgetConfigsRaw = decoded['widget_configs'];
    if (widgetConfigsRaw is Map) {
      await _restoreWidgetConfig(
        scope: WidgetService.scopeConfigured,
        raw: widgetConfigsRaw[WidgetService.scopeConfigured],
        fallbackMode: 'today',
      );
      await _restoreWidgetConfig(
        scope: WidgetService.scopeBook,
        raw: widgetConfigsRaw[WidgetService.scopeBook],
        fallbackMode: 'book',
      );
      await _restoreWidgetConfig(
        scope: WidgetService.scopeSelected,
        raw: widgetConfigsRaw[WidgetService.scopeSelected],
        fallbackMode: 'selected',
      );
      await _restoreWidgetConfig(
        scope: WidgetService.scopeLockSelected,
        raw: widgetConfigsRaw[WidgetService.scopeLockSelected],
        fallbackMode: 'selected',
      );
    }
  }

  static Future<void> _restoreWidgetConfig({
    required String scope,
    required dynamic raw,
    required String fallbackMode,
  }) async {
    if (raw is! Map) {
      return;
    }

    final mode = (raw['mode'] as String?)?.trim().isNotEmpty == true
        ? raw['mode'] as String
        : fallbackMode;

    final taskBookId = _toIntOrNull(raw['task_book_id']);
    final taskIds = _toIntList(raw['task_ids']);

    await WidgetService.saveWidgetConfig(
      scope: scope,
      mode: mode,
      taskBookId: taskBookId,
      taskIds: taskIds,
    );
  }

  static int? _toIntOrNull(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static List<int> _toIntList(dynamic value) {
    if (value is! List) {
      return const [];
    }
    final result = <int>[];
    for (final item in value) {
      final parsed = _toIntOrNull(item);
      if (parsed != null) {
        result.add(parsed);
      }
    }
    return result;
  }
}
