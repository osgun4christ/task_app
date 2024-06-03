import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database_helper.dart';
import '../models/task.dart';

class TaskHistoryScreen extends StatefulWidget {
  const TaskHistoryScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _TaskHistoryScreenState createState() => _TaskHistoryScreenState();
}

class _TaskHistoryScreenState extends State<TaskHistoryScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Task History'),
      ),
      body: FutureBuilder<List<AppTask>>(
        future: _dbHelper .getCompletedTasks(),
        builder: (BuildContext context, AsyncSnapshot<List<AppTask>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No completed tasks.'));
          } else {
            final groupedTasks = _groupTasksByDay(snapshot.data!);
            return ListView.builder(
              itemCount: groupedTasks.length,
              itemBuilder: (BuildContext context, int index) {
                final date = groupedTasks.keys.elementAt(index);
                final tasks = groupedTasks[date]!;
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                  child: ExpansionTile(
                    title: Text(DateFormat('yyyy-MM-dd').format(date)),
                    children: tasks.map((task) {
                      return ListTile(
                        title: Text(task.title),
                        subtitle: Text('Completed on: ${DateFormat('MMM d, y h:mm a').format(task.deadline)}'),
                      );
                    }).toList(),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }

  Map<DateTime, List<AppTask>> _groupTasksByDay(List<AppTask> tasks) {
    final Map<DateTime, List<AppTask>> groupedTasks = {};
    for (final task in tasks) {
      final DateTime taskDate = DateTime(task.deadline.year, task.deadline.month, task.deadline.day);
      if (groupedTasks[taskDate] == null) {
        groupedTasks[taskDate] = [];
      }
      groupedTasks[taskDate]!.add(task);
    }

    return groupedTasks;
  }
}
