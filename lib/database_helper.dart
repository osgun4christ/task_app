import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'models/task.dart';

class DatabaseHelper {
  static const _databaseName = "TaskDatabase.db";
  static const _databaseVersion = 1;

  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  _initDatabase() async {
    String path = join(await getDatabasesPath(), _databaseName);
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
    );
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
          CREATE TABLE tasks (
            id INTEGER PRIMARY KEY,
            title TEXT NOT NULL,
            deadline TEXT NOT NULL,
            isCompleted INTEGER NOT NULL
          )
          ''');
  }

  Future<int> insertTask(Task task) async {
    Database db = await instance.database;
    return await db.insert('tasks', task.toMap());
  }

  Future<List<Task>> getTaskList() async {
    Database db = await instance.database;
    var tasks = await db.query('tasks', orderBy: "isCompleted ASC, deadline ASC");
    List<Task> taskList = tasks.isNotEmpty
        ? tasks.map((task) => Task.fromMap(task)).toList()
        : [];
    return taskList;
  }

  Future<List<Task>> getCompletedTasks() async {
    Database db = await instance.database;
    var tasks = await db.query('tasks', where: "isCompleted = ?", whereArgs: [1], orderBy: "deadline DESC");
    List<Task> taskList = tasks.isNotEmpty
        ? tasks.map((task) => Task.fromMap(task)).toList()
        : [];
    return taskList;
  }

  Future<List<Task>> getTasksByDate(DateTime date) async {
    Database db = await instance.database;
    var tasks = await db.query(
      'tasks',
      where: "deadline = ?",
      whereArgs: [date.toIso8601String()],
    );
    List<Task> taskList = tasks.isNotEmpty
        ? tasks.map((task) => Task.fromMap(task)).toList()
        : [];
    return taskList;
  }

  Future<int> updateTask(Task task) async {
    Database db = await instance.database;
    return await db.update(
      'tasks',
      task.toMap(),
      where: "id = ?",
      whereArgs: [task.id],
    );
  }

  Future<int> deleteTask(int id) async {
    Database db = await instance.database;
    return await db.delete(
      'tasks',
      where: "id = ?",
      whereArgs: [id],
    );
  }
}
