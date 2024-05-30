import 'package:flutter/material.dart';
import '../../database_helper.dart';
import '../../models/task.dart';

class TaskHistoryScreen extends StatefulWidget {
  const TaskHistoryScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _TaskHistoryScreenState createState() => _TaskHistoryScreenState();
}

class _TaskHistoryScreenState extends State<TaskHistoryScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  List<Task> _completedTasks = [];

  @override
  void initState() {
    super.initState();
    _loadCompletedTasks();
  }

  void _loadCompletedTasks() {
    _dbHelper.getCompletedTasks().then((taskList) {
      setState(() {
        _completedTasks = taskList;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Completed Tasks'),
      ),
      body: ListView.builder(
        itemCount: _completedTasks.length,
        itemBuilder: (BuildContext context, int index) {
          final task = _completedTasks[index];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            child: ListTile(
              title: Text(task.title),
              subtitle: Text('Completed on: ${task.deadline}'),
            ),
          );
        },
      ),
    );
  }
}
