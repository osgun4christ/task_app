import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'database_helper.dart';
import 'models/task.dart';

void main() {
  tz.initializeTimeZones();
  runApp(const TaskApp());
}

class TaskApp extends StatelessWidget {
  const TaskApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Task App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const TaskListScreen(),
    );
  }
}

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _TaskListScreenState createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  List<Task> _taskList = [];

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    _updateTaskList();
  }

  Future<void> _initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
    await _flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> _scheduleNotification(Task task) async {
    await _flutterLocalNotificationsPlugin.zonedSchedule(
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
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.wallClockTime,
    );
    print('Notification scheduled for task: ${task.title} at ${task.deadline}');
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
    DateTime? selectedDeadline = task?.deadline;

    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
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
                    initialDate: selectedDeadline ?? DateTime.now(),
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
                        selectedDeadline = DateTime(picked.year, picked.month, picked.day, timePicked.hour, timePicked.minute);
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
                  final deadline = selectedDeadline ?? DateTime.now();

                  if (task == null) {
                    final newTask = Task(title: title, deadline: deadline);
                    _dbHelper.insertTask(newTask).then((_) {
                      _scheduleNotification(newTask);
                      _updateTaskList();
                    });
                  } else {
                    final updatedTask = Task(id: task.id, title: title, deadline: deadline, isCompleted: task.isCompleted);
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
        );
      },
    );
  }

  void _markAsCompleted(Task task) {
    final updatedTask = Task(id: task.id, title: task.title, deadline: task.deadline, isCompleted: true);
    _dbHelper.updateTask(updatedTask).then((_) {
      _updateTaskList();
    });
  }

  void _deleteTask(Task task) {
    _dbHelper.deleteTask(task.id!).then((_) {
      _updateTaskList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Task App'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              // Navigate to history screen (to be implemented)
            },
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: _taskList.length,
        itemBuilder: (BuildContext context, int index) {
          final task = _taskList[index];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            child: ListTile(
              title: Text(task.title),
              subtitle: Text('Deadline: ${task.deadline.toLocal()}'.split(' ')[0]), // Format the deadline
              trailing: Checkbox(
                value: task.isCompleted,
                onChanged: (bool? value) {
                  _markAsCompleted(task);
                },
              ),
              onTap: () => _addOrEditTask(task),
              onLongPress: () => _deleteTask(task),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => _addOrEditTask(null),
      ),
    );
  }
}
