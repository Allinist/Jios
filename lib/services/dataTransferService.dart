import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../database/databaseHelper.dart';

class DataTransferService {
  static const int _schemaVersion = 1;

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

    final payload = {
      'schema_version': _schemaVersion,
      'exported_at': DateTime.now().millisecondsSinceEpoch,
      'tables': tableData,
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
  }
}
