import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'models/task.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._instance();
  static Database? _db;

  DatabaseHelper._instance();

  String taskTable = 'task_table';
  String colId = 'id';
  String colTitle = 'title';
  String colDeadline = 'deadline';
  String colIsCompleted = 'isCompleted';

  Future<Database> get db async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'task.db');

    return await openDatabase(path, version: 1, onCreate: _createDb);
  }

  void _createDb(Database db, int version) async {
    await db.execute(
      'CREATE TABLE $taskTable($colId INTEGER PRIMARY KEY AUTOINCREMENT, $colTitle TEXT, $colDeadline TEXT, $colIsCompleted INTEGER)',
    );
  }

  Future<List<Map<String, dynamic>>> getTaskMapList() async {
    Database db = await this.db;
    final List<Map<String, dynamic>> result = await db.query(taskTable);
    return result;
  }

  Future<List<Task>> getTaskList() async {
    final List<Map<String, dynamic>> taskMapList = await getTaskMapList();
    final List<Task> taskList = [];
    for (var taskMap in taskMapList) {
      taskList.add(Task.fromMap(taskMap));
    }
    return taskList;
  }

  Future<int> insertTask(Task task) async {
    Database db = await this.db;
    final int result = await db.insert(taskTable, task.toMap());
    return result;
  }

  Future<int> updateTask(Task task) async {
    Database db = await this.db;
    final int result = await db.update(
      taskTable,
      task.toMap(),
      where: '$colId = ?',
      whereArgs: [task.id],
    );
    return result;
  }

  Future<int> deleteTask(int id) async {
    Database db = await this.db;
    final int result = await db.delete(
      taskTable,
      where: '$colId = ?',
      whereArgs: [id],
    );
    return result;
  }

  Future<List<Task>> getCompletedTasks() async {
    Database db = await this.db;
    final List<Map<String, dynamic>> result = await db.query(
      taskTable,
      where: '$colIsCompleted = ?',
      whereArgs: [1],
    );
    final List<Task> taskList = [];
    for (var taskMap in result) {
      taskList.add(Task.fromMap(taskMap));
    }
    return taskList;
  }

  Future<List<Task>> getIncompleteTasks() async {
    Database db = await this.db;
    final List<Map<String, dynamic>> result = await db.query(
      taskTable,
      where: '$colIsCompleted = ?',
      whereArgs: [0],
    );
    final List<Task> taskList = [];
    for (var taskMap in result) {
      taskList.add(Task.fromMap(taskMap));
    }
    return taskList;
  }

  Future<List<Task>> getTasksForDate(DateTime date) async {
    Database db = await this.db;
    final String formattedDate = date.toIso8601String().substring(0, 10); // YYYY-MM-DD
    final List<Map<String, dynamic>> result = await db.query(
      taskTable,
      where: '$colDeadline LIKE ?',
      whereArgs: ['$formattedDate%'],
    );
    final List<Task> taskList = [];
    for (var taskMap in result) {
      taskList.add(Task.fromMap(taskMap));
    }
    return taskList;
  }
}
