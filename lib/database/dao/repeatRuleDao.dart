import 'package:sqflite/sqflite.dart';

import '../../models/repeatRule.dart';
import '../databaseHelper.dart';

class RepeatRuleDao {

  /// 插入规则
  Future<int> insert(RepeatRule rule) async {

    final db = await DatabaseHelper.instance.database;

    return await db.insert(
      'repeat_rules',
      rule.toMap(),
    );

  }

  /// 查询所有规则
  Future<List<RepeatRule>> getAll() async {

    final db = await DatabaseHelper.instance.database;

    final result = await db.query('repeat_rules');

    return result
        .map((e) => RepeatRule.fromMap(e))
        .toList();

  }

  /// 根据ID查询
  Future<RepeatRule?> getById(int id) async {

    final db = await DatabaseHelper.instance.database;

    final result = await db.query(
      'repeat_rules',
      where: 'id=?',
      whereArgs: [id],
    );

    if (result.isEmpty) return null;

    return RepeatRule.fromMap(result.first);

  }

  /// 更新规则
  Future<int> update(RepeatRule rule) async {

    final db = await DatabaseHelper.instance.database;

    return await db.update(
      'repeat_rules',
      rule.toMap(),
      where: 'id=?',
      whereArgs: [rule.id],
    );

  }

  /// 删除规则
  Future<int> delete(int id) async {

    final db = await DatabaseHelper.instance.database;

    return await db.delete(
      'repeat_rules',
      where: 'id=?',
      whereArgs: [id],
    );

  }

}