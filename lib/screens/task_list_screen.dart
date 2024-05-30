import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;
import '../database_helper.dart';
import '../models/task.dart';

class TaskListScreen extends StatefulWidget {
  //final FlutterLocalNotificationsPlugin notificationsPlugin;
  final FlutterLocalNotificationsPlugin notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  final DateTime initialDate;

  //TaskListScreen({super.key, required this.notificationsPlugin, required this.initialDate});
  TaskListScreen(
      {super.key,
      required this.initialDate,
      required FlutterLocalNotificationsPlugin notificationsPlugin});

  @override
  // ignore: library_private_types_in_public_api
  _TaskListScreenState createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  late List<Task> _taskList = [];
  final String _userName =
      "Samuel"; // Static for simplicity, you can make this dynamic
  late String _currentDate;

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    _updateTaskList();
    _currentDate = _getCurrentDate(widget.initialDate);
  }

  String _getCurrentDate(DateTime date) {
    return DateFormat('EEEE, MMM d').format(date);
  }

  Future<void> _initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    await widget.notificationsPlugin.initialize(initializationSettings);
  }

  Future<void> _scheduleNotification(Task task) async {
    await widget.notificationsPlugin.zonedSchedule(
      task.id!,
      'Task Reminder',
      task.title,
      tz.TZDateTime.from(task.deadline, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'task_reminders',
          'Task Reminders',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.wallClockTime,
    );
  }

  void _updateTaskList() {
    _dbHelper.getTaskList().then((taskList) {
      setState(() {
        _taskList = taskList;
      });
    });
  }

  void _addOrEditTask(Task? task) {
    final titleController = TextEditingController(text: task?.title);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Title'),
                ),
                const SizedBox(height: 20.0),
                ElevatedButton(
                  onPressed: () async {
                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: task?.deadline ?? DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime(DateTime.now().year + 5),
                    );
                    if (picked != null) {
                      final TimeOfDay? timePicked = await showTimePicker(
                        // ignore: use_build_context_synchronously
                        context: context,
                        initialTime: TimeOfDay.now(),
                      );
                      if (timePicked != null) {
                        setState(() {
                          task?.deadline = DateTime(picked.year, picked.month,
                              picked.day, timePicked.hour, timePicked.minute);
                        });
                      }
                    }
                  },
                  child: const Text('Select Deadline'),
                ),
                const SizedBox(height: 20.0),
                ElevatedButton(
                  onPressed: () {
                    final title = titleController.text;
                    final deadline = task?.deadline ?? DateTime.now();

                    if (task == null) {
                      final newTask = Task(title: title, deadline: deadline);
                      _dbHelper.insertTask(newTask).then((_) {
                        _scheduleNotification(newTask);
                        _updateTaskList();
                      });
                    } else {
                      final updatedTask = Task(
                          id: task.id,
                          title: title,
                          deadline: deadline,
                          isCompleted: task.isCompleted);
                      _dbHelper.updateTask(updatedTask).then((_) {
                        _scheduleNotification(updatedTask);
                        _updateTaskList();
                      });
                    }

                    Navigator.pop(context);
                  },
                  child: Text(task == null ? 'Add Task' : 'Edit Task'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _markAsCompleted(Task task) {
    final updatedTask = Task(
        id: task.id,
        title: task.title,
        deadline: task.deadline,
        isCompleted: !task.isCompleted);
    _dbHelper.updateTask(updatedTask).then((_) {
      _updateTaskList();
    });
  }

  void _deleteTask(Task task) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Task'),
          content: const Text('Are you sure you want to delete this task?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _dbHelper.deleteTask(task.id!).then((_) {
                  Navigator.pop(context);
                  _updateTaskList();
                });
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _showHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const HistoryScreen()),
    );
  }

  void _showCalendar() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CalendarScreen()),
    );
  }

  void _showAddTask() {
    _addOrEditTask(null);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Task App'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: _showHistory,
          ),
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: _showCalendar,
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Color.fromARGB(255, 159, 118, 210),
              ),
              child: Text('Menu'),
            ),
            ListTile(
              title: const Text('Add Task'),
              onTap: _showAddTask,
            ),
            ListTile(
              title: const Text('Task History'),
              onTap: _showHistory,
            ),
            ListTile(
              title: const Text('Calendar'),
              onTap: _showCalendar,
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text('Welcome, $_userName! Today is $_currentDate'),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _taskList.length,
              itemBuilder: (BuildContext context, int index) {
                final task = _taskList[index];
                return Card(
                  color: task.isCompleted
                      ? const Color.fromARGB(255, 212, 179, 242)
                      : null,
                  margin: const EdgeInsets.symmetric(
                      vertical: 8.0, horizontal: 16.0),
                  child: ListTile(
                    title: Text(task.title),
                    subtitle: Text('Deadline: ${task.deadline}'),
                    trailing: Wrap(
                      spacing: 12, // space between two icons
                      children: <Widget>[
                        Checkbox(
                          value: task.isCompleted,
                          onChanged: (bool? value) {
                            _markAsCompleted(task);
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => _deleteTask(task),
                        ),
                      ],
                    ),
                    onTap: () => _addOrEditTask(task),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => _addOrEditTask(null),
      ),
    );
  }
}

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Task History'),
      ),
      body: FutureBuilder<List<Task>>(
        future: DatabaseHelper.instance.getCompletedTasks(),
        builder: (BuildContext context, AsyncSnapshot<List<Task>> snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.data!.isEmpty) {
            return const Center(child: Text('No completed tasks.'));
          }
          return ListView(
            children: snapshot.data!.map((task) {
              return ListTile(
                title: Text(task.title),
                subtitle: Text('Completed on: ${task.deadline}'),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar'),
      ),
      body: FutureBuilder<List<Task>>(
        future: DatabaseHelper.instance.getTaskList(),
        builder: (BuildContext context, AsyncSnapshot<List<Task>> snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.data!.isEmpty) {
            return const Center(child: Text('No tasks found.'));
          }
          return ListView(
            children: snapshot.data!.map((task) {
              return ListTile(
                title: Text(task.title),
                subtitle: Text('Deadline: ${task.deadline}'),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
