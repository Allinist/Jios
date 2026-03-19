import '../../models/task.dart';
import '../databaseHelper.dart';

class TaskDao {
  Future<int> insert(Task task) async {
    final db = await DatabaseHelper.instance.database;

    return await db.insert(
      'tasks',
      task.toMap(),
    );
  }

  Future<List<Task>> getAll() async {
    final db = await DatabaseHelper.instance.database;

    final result = await db.query('tasks');

    return result.map((e) => Task.fromMap(e)).toList();
  }

  Future<int> update(Task task) async {
    final db = await DatabaseHelper.instance.database;

    return await db.update(
      'tasks',
      task.toMap(),
      where: 'id=?',
      whereArgs: [task.id],
    );
  }

  Future<int> clearTaskBookId(int taskBookId) async {
    final db = await DatabaseHelper.instance.database;

    return await db.update(
      'tasks',
      {
        'task_book_id': null,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'task_book_id=?',
      whereArgs: [taskBookId],
    );
  }

  Future<int> delete(int id) async {
    final db = await DatabaseHelper.instance.database;

    return await db.delete(
      'tasks',
      where: 'id=?',
      whereArgs: [id],
    );
  }
}
