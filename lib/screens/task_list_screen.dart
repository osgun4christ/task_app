import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:task_app/screens/calendar_screen.dart';
import 'package:task_app/screens/history_screen.dart';
//import 'package:task_app/screens/history_screen.dart';
import 'package:timezone/timezone.dart' as tz;
import '../database_helper.dart';
import '../models/task.dart';

class TaskListScreen extends StatefulWidget {
  final FlutterLocalNotificationsPlugin notificationsPlugin;
  final DateTime initialDate;

  const TaskListScreen(
      {super.key,
      required this.initialDate,
      required this.notificationsPlugin});

  @override
  // ignore: library_private_types_in_public_api
  _TaskListScreenState createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  late List<AppTask> _taskList = [];
  final String _userName =
      "Samuel"; // Static for simplicity, you can make this dynamic
  late String _currentDate;

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    _archiveOldCompletedTasks();
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
    await widget.notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // handle the notification response
      },
      onDidReceiveBackgroundNotificationResponse:
          (NotificationResponse response) {
        // handle the background notification response
      },
    );
  }

  Future<void> _scheduleNotification(AppTask task) async {
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

  Future<void> _archiveOldCompletedTasks() async {
    await _dbHelper.archiveOldCompletedTasks();
  }

  void _updateTaskList() {
    _dbHelper.getTaskList().then((taskList) {
      setState(() {
        _taskList = taskList.where((task) {
          return !task.isCompleted || _isToday(task.deadline);
        }).toList();
        _taskList.sort((a, b) {
          if (a.isCompleted != b.isCompleted) {
            return a.isCompleted ? 1 : -1;
          } else if (a.deadline != b.deadline) {
            return a.deadline.isBefore(b.deadline) ? -1 : 1;
          } else {
            return 0;
          }
        });
      });
    });
  }

  bool _isToday(DateTime deadline) {
    final now = DateTime.now();
    return deadline.year == now.year &&
        deadline.month == now.month &&
        deadline.day == now.day;
  }

  void _addOrEditTask(AppTask? task) {
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
                    final title = titleController.text;
                    DateTime deadline = task?.deadline ?? DateTime.now();

                    final DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: deadline,
                      firstDate: DateTime.now(),
                      lastDate: DateTime(DateTime.now().year + 5),
                    );

                    if (pickedDate != null) {
                      deadline = DateTime(
                          pickedDate.year, pickedDate.month, pickedDate.day);
                    }

                    if (task == null) {
                      final newTask = AppTask(title: title, deadline: deadline);
                      _dbHelper.insertTask(newTask).then((_) {
                        _scheduleNotification(newTask);
                        _updateTaskList();
                      });
                    } else {
                      final updatedTask = AppTask(
                        id: task.id,
                        title: title,
                        deadline: deadline,
                        isCompleted: task.isCompleted,
                      );
                      _dbHelper.updateTask(updatedTask).then((_) {
                        _scheduleNotification(updatedTask);
                        _updateTaskList();
                      });
                    }

                    // ignore: use_build_context_synchronously
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

  void _markAsCompleted(AppTask task) {
    final updatedTask = AppTask(
      id: task.id,
      title: task.title,
      deadline: task.deadline,
      isCompleted: !task.isCompleted,
    );
    _dbHelper.updateTask(updatedTask).then((_) {
      _updateTaskList();
    });
  }

  void _deleteTask(AppTask task) {
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
      MaterialPageRoute(builder: (context) => const TaskHistoryScreen()),
    );
  }

  void _showCalendar() {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => CalendarScreen(
                notificationsPlugin: widget.notificationsPlugin,
              )),
    );
  }

  void _showAddTask() {
    _addOrEditTask(null);
  }

  bool _isExpired(DateTime deadline) {
    final now = DateTime.now();
    final deadlineDate = DateTime(deadline.year, deadline.month, deadline.day);
    final todayDate = DateTime(now.year, now.month, now.day);
    return deadlineDate.isBefore(todayDate);
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
        width: MediaQuery.of(context).size.width * 0.65, // Adjust the width as needed
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                color: Color.fromARGB(255, 159, 118, 210),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0), // Add padding as needed
                child: SizedBox(
                  width: 5,
                  height: 5,
                  child: Image.asset(
                    'assets/taskapp.png',
                    fit: BoxFit.contain,
                  ), // Adjust the width as needed
                ),
              ),
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
                      : _isExpired(task.deadline)
                          ? const Color.fromARGB(
                              255, 255, 173, 173) // Expired task color
                          : null,
                  margin: const EdgeInsets.symmetric(
                      vertical: 8.0, horizontal: 16.0),
                  child: ListTile(
                    title: Text(task.title),
                    subtitle: Text(
                        'Deadline: ${DateFormat('yyyy-MM-dd').format(task.deadline)}'),
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

// class HistoryScreen extends StatelessWidget {
//   const HistoryScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Task History'),
//       ),
//       body: FutureBuilder<List<AppTask>>(
//         future: DatabaseHelper.instance.getCompletedTasks(),
//         builder: (BuildContext context, AsyncSnapshot<List<AppTask>> snapshot) {
//           if (!snapshot.hasData) {
//             return const Center(child: CircularProgressIndicator());
//           }
//           if (snapshot.data!.isEmpty) {
//             return const Center(child: Text('No completed tasks.'));
//           }
//           return ListView(
//             children: snapshot.data!.map((task) {
//               return ListTile(
//                 title: Text(task.title),
//                 subtitle: Text('Completed on: ${DateFormat('yyyy-MM-dd').format(task.deadline)}'),
//               );
//             }).toList(),
//           );
//         },
//       ),
//     );
//   }
// }

// class CalendarScreen extends StatelessWidget {
//   const CalendarScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Calendar'),
//       ),
//       body: FutureBuilder<List<AppTask>>(
//         future: DatabaseHelper.instance.getTaskList(),
//         builder: (BuildContext context, AsyncSnapshot<List<AppTask>> snapshot) {
//           if (!snapshot.hasData) {
//             return const Center(child: CircularProgressIndicator());
//           }
//           if (snapshot.data!.isEmpty) {
//             return const Center(child: Text('No tasks found.'));
//           }
//           return ListView(
//             children: snapshot.data!.map((task) {
//               return ListTile(
//                 title: Text(task.title),
//                 subtitle: Text('Deadline: ${DateFormat('yyyy-MM-dd').format(task.deadline)}'),
//               );
//             }).toList(),
//           );
//         },
//       ),
//     );
//   }
// }
