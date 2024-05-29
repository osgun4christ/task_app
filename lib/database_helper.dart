import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'models/task.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._instance();
  static Database? _db;

  DatabaseHelper._instance();

  String tasksTable = 'task_table';
  String colId = 'id';
  String colTitle = 'title';
  String colDeadline = 'deadline';
  String colIsCompleted = 'isCompleted';

  Future<Database?> get db async {
    _db ??= await _initDb();
    return _db;
  }

  Future<Database> _initDb() async {
    String path = join(await getDatabasesPath(), 'tasks.db');
    final tasksDb = await openDatabase(path, version: 1, onCreate: _createDb);
    return tasksDb;
  }

  void _createDb(Database db, int version) async {
    await db.execute(
      'CREATE TABLE $tasksTable($colId INTEGER PRIMARY KEY AUTOINCREMENT, $colTitle TEXT, $colDeadline TEXT, $colIsCompleted INTEGER)',
    );
  }

  Future<List<Map<String, dynamic>>> getTaskMapList() async {
    Database? db = await this.db;
    final List<Map<String, dynamic>> result = await db!.query(tasksTable);
    return result;
  }

  Future<int> insertTask(Task task) async {
    Database? db = await this.db;
    final int result = await db!.insert(tasksTable, task.toMap());
    return result;
  }

  Future<int> updateTask(Task task) async {
    Database? db = await this.db;
    final int result = await db!.update(tasksTable, task.toMap(), where: '$colId = ?', whereArgs: [task.id]);
    return result;
  }

  Future<int> deleteTask(int id) async {
    Database? db = await this.db;
    final int result = await db!.delete(tasksTable, where: '$colId = ?', whereArgs: [id]);
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
}
