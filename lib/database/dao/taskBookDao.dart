import 'package:sqflite/sqflite.dart';

import '../databaseHelper.dart';
import '../../models/taskBook.dart';

class TaskBookDao {
  Future<int> insert(TaskBook book) async {
    final db = await DatabaseHelper.instance.database;

    return await db.insert(
      'task_books',
      book.toMap(),
    );
  }

  Future<List<TaskBook>> getAll() async {
    final db = await DatabaseHelper.instance.database;

    final result = await db.query(
      'task_books',
      orderBy: 'created_at ASC',
    );

    return result.map((e) => TaskBook.fromMap(e)).toList();
  }

  Future<void> ensureDefaultBooks() async {
    final db = await DatabaseHelper.instance.database;
    final initRows = await db.query(
      'app_settings',
      where: 'key=?',
      whereArgs: ['default_books_initialized'],
      limit: 1,
    );

    if (initRows.isNotEmpty) {
      return;
    }

    await db.insert(
      'app_settings',
      {
        'key': 'default_books_initialized',
        'value': '1',
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> update(TaskBook book) async {
    final db = await DatabaseHelper.instance.database;

    return await db.update(
      'task_books',
      book.toMap(),
      where: 'id=?',
      whereArgs: [book.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await DatabaseHelper.instance.database;

    return await db.delete(
      'task_books',
      where: 'id=?',
      whereArgs: [id],
    );
  }
}
