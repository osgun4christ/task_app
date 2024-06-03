import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/task.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();

  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDB('tasks.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    const taskTable = '''
    CREATE TABLE tasks (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      title TEXT NOT NULL,
      deadline TEXT NOT NULL,
      isCompleted INTEGER NOT NULL
    );
    ''';

    const archivedTaskTable = '''
    CREATE TABLE archived_tasks (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      title TEXT NOT NULL,
      deadline TEXT NOT NULL,
      isCompleted INTEGER NOT NULL
    );
    ''';

    await db.execute(taskTable);
    await db.execute(archivedTaskTable);
  }

  Future<void> moveToArchivedTasks(AppTask task) async {
    final db = await instance.database;

    await db.insert('archived_tasks', task.toJson());
    await db.delete('tasks', where: 'id = ?', whereArgs: [task.id]);
  }

  Future<AppTask> insertTask(AppTask task) async {
    final db = await instance.database;

    final id = await db.insert('tasks', task.toJson());
    return task.copyWith(id: id);
  }

  Future<List<AppTask>> getTaskList() async {
    final db = await instance.database;

    final result = await db.query('tasks');
    return result.map((json) => AppTask.fromJson(json)).toList();
  }

  Future<void> updateTask(AppTask task) async {
    final db = await instance.database;

    await db.update(
      'tasks',
      task.toJson(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  Future<void> deleteTask(int id) async {
    final db = await instance.database;

    await db.delete(
      'tasks',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

 Future<void> archiveOldCompletedTasks() async {
    final db = await instance.database;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Fetch all completed tasks
    final completedTasks = await db.query(
      'tasks',
      where: 'isCompleted = ?',
      whereArgs: [1],
    );

    // Move tasks with a deadline before today to the archived_tasks table
    for (var taskJson in completedTasks) {
      final task = AppTask.fromJson(taskJson);
      final taskDeadline = DateTime.parse(task.deadline as String);

      if (taskDeadline.isBefore(today)) {
        await moveToArchivedTasks(task);
      }
    }
  }

  Future<List<AppTask>> getCompletedTasks() async {
    final db = await instance.database;

    final result = await db.query(
      'archived_tasks',
      orderBy: 'deadline DESC',
    );
    print('Fetched completed tasks: $result'); // Logging for verification
    return result.map((json) => AppTask.fromJson(json)).toList();
  }

  Future close() async {
    final db = await instance.database;

    db.close();
  }
}
