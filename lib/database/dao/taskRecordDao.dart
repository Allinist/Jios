import 'package:sqflite/sqflite.dart';
import '../taskRecord.dart';
import '../databaseHelper.dart';

class TaskRecordDao {

  /// 插入记录
  Future<int> insert(TaskRecord record) async {

    final db = await DatabaseHelper.instance.database;

    return await db.insert(
      'task_records',
      record.toMap(),
    );

  }

  /// 获取任务的所有记录
  Future<List<TaskRecord>> getByTaskId(int taskId) async {

    final db = await DatabaseHelper.instance.database;

    final result = await db.query(
      'task_records',
      where: 'task_id=?',
      whereArgs: [taskId],
      orderBy: 'date DESC',
    );

    return result.map((e) => TaskRecord.fromMap(e)).toList();

  }

  /// 获取某一天的记录
  Future<List<TaskRecord>> getByDate(int date) async {

    final db = await DatabaseHelper.instance.database;

    final result = await db.query(
      'task_records',
      where: 'date=?',
      whereArgs: [date],
    );

    return result.map((e) => TaskRecord.fromMap(e)).toList();

  }

  /// 删除记录
  Future<int> delete(int id) async {

    final db = await DatabaseHelper.instance.database;

    return await db.delete(
      'task_records',
      where: 'id=?',
      whereArgs: [id],
    );

  }

}