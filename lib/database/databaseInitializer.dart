import 'package:sqflite/sqflite.dart';

class DatabaseInitializer {
  static Future createTables(Database db, int version) async {
    await db.execute('''
CREATE TABLE task_books (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    description TEXT,
    color TEXT,
    created_at INTEGER
);
''');

    await db.execute('''
CREATE TABLE tasks (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    title TEXT NOT NULL,
    description TEXT,
    task_book_id INTEGER,
    task_type TEXT,
    priority INTEGER,
    status TEXT,
    start_date INTEGER,
    end_date INTEGER,
    expected_duration INTEGER,
    repeat_rule_id INTEGER,
    created_at INTEGER,
    updated_at INTEGER,
    color INTEGER,
    timeline_display_mask INTEGER,
    timeline_granularity TEXT,
    notify_at_start INTEGER,
    notify_before_start_minutes INTEGER,
    notify_at_end INTEGER,
    notify_before_end_minutes INTEGER,
    widget_display_scopes TEXT
);
''');

    await db.execute('''
CREATE TABLE repeat_rules (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    repeat_type TEXT,
    interval INTEGER,
    week_days TEXT,
    month_days TEXT,
    month_week TEXT,
    year_days TEXT,
    work_days INTEGER,
    time_ranges TEXT
);
''');

    await db.execute('''
CREATE TABLE task_records (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    task_id INTEGER,
    date INTEGER,
    duration INTEGER,
    status TEXT,
    created_at INTEGER
);
''');

    await db.execute('''
CREATE TABLE app_settings (
    key TEXT PRIMARY KEY,
    value TEXT
);
''');

    await db.execute('''
CREATE TABLE widget_cache (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    data TEXT,
    updated_at INTEGER
);
''');
  }

  static Future upgradeTables(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _addColumnIfNotExists(
        db: db,
        table: 'tasks',
        column: 'color',
        definition: 'INTEGER',
      );
    }

    if (oldVersion < 3) {
      await _addColumnIfNotExists(
        db: db,
        table: 'tasks',
        column: 'timeline_display_mask',
        definition: 'INTEGER',
      );

      await _addColumnIfNotExists(
        db: db,
        table: 'tasks',
        column: 'timeline_granularity',
        definition: 'TEXT',
      );
    }

    if (oldVersion < 4) {
      await _addColumnIfNotExists(
        db: db,
        table: 'tasks',
        column: 'notify_at_start',
        definition: 'INTEGER',
      );

      await _addColumnIfNotExists(
        db: db,
        table: 'tasks',
        column: 'notify_before_start_minutes',
        definition: 'INTEGER',
      );

      await _addColumnIfNotExists(
        db: db,
        table: 'tasks',
        column: 'notify_at_end',
        definition: 'INTEGER',
      );

      await _addColumnIfNotExists(
        db: db,
        table: 'tasks',
        column: 'notify_before_end_minutes',
        definition: 'INTEGER',
      );
    }

    if (oldVersion < 5) {
      await _addColumnIfNotExists(
        db: db,
        table: 'tasks',
        column: 'widget_display_scopes',
        definition: 'TEXT',
      );
    }
  }

  static Future<void> _addColumnIfNotExists({
    required Database db,
    required String table,
    required String column,
    required String definition,
  }) async {
    final result = await db.rawQuery('PRAGMA table_info($table)');

    final exists = result.any((row) => row['name'] == column);

    if (exists) return;

    await db.execute(
      'ALTER TABLE $table ADD COLUMN $column $definition',
    );
  }
}
