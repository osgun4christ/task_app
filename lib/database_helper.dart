import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/task.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('task.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const boolType = 'BOOLEAN NOT NULL';
    const dateType = 'TEXT NOT NULL';

    await db.execute('''
    CREATE TABLE tasks (
      id $idType,
      title $textType,
      deadline $dateType,
      isCompleted $boolType
    )
    ''');
  }

  Future<int> insertTask(AppTask task) async {
    final db = await instance.database;
    final id = await db.insert('tasks', task.toMap());
    return id;
  }

  Future<void> updateTask(AppTask task) async {
    final db = await instance.database;
    await db.update(
      'tasks',
      task.toMap(),
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

  Future<List<AppTask>> getTaskList() async {
    final db = await instance.database;
    final result = await db.query('tasks', orderBy: 'deadline');
    return result.map((json) => AppTask.fromMap(json)).toList();
  }

  Future<List<AppTask>> getCompletedTasks() async {
    final db = await instance.database;
    final today = DateTime.now();
    final todayString = today.toIso8601String().substring(0, 10);

    final result = await db.query(
      'tasks',
      where: 'isCompleted = ? AND deadline < ?',
      whereArgs: [1, todayString],
      orderBy: 'deadline DESC',
    );

    return result.map((json) => AppTask.fromMap(json)).toList();
  }
}
