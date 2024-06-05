// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:task_app/screens/calendar_screen.dart';
import 'package:task_app/screens/history_screen.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:timezone/timezone.dart' as tz;
import '../database_helper.dart';
import '../models/task.dart';

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {
  print('notification(${notificationResponse.id}) action tapped: '
      '${notificationResponse.actionId} with payload: ${notificationResponse.payload}');
  if (notificationResponse.input?.isNotEmpty ?? false) {
    print('notification tapped with input: ${notificationResponse.input}');
  }
}

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
  late String _userName = '';
  late String _currentDate;
  late String _appVersion;

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    _updateTaskList();
    _currentDate = _getCurrentDate(widget.initialDate);
    _fetchAppVersion(); // Fetch the app version
    _fetchUserName(); // Fetch the user name
  }

  String _getCurrentDate(DateTime date) {
    return DateFormat('EEEE, MMM d').format(date);
  }

  //Testing
//   Future<void> _showTestNotification() async {
//   const AndroidNotificationDetails androidPlatformChannelSpecifics =
//       AndroidNotificationDetails(
//     'test_channel', // ID
//     'Test Channel', // Name
//     channelDescription: 'This is a test channel',
//     importance: Importance.max,
//     priority: Priority.high,
//   );
//   const NotificationDetails platformChannelSpecifics =
//       NotificationDetails(android: androidPlatformChannelSpecifics);
//   await widget.notificationsPlugin.show(
//     0, // Notification ID
//     'Test Notification', // Title
//     'This is a test notification', // Body
//     platformChannelSpecifics,
//     payload: 'Test Payload',
//   );
// }

  Future<void> _initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
    );

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'task_reminders', // ID
      'Task Reminders', // Name
      description: 'Kindly be reminded of your pending task.', // Description
      importance: Importance.max,
    );

    await widget.notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    await widget.notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // handle the notification response
        print('Foreground notification received: ${response.payload}');
      },
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );
    // Request notification permissions if not already granted
  }

  Future<void> _fetchAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        _appVersion = packageInfo.version;
      });
    } catch (e) {
      // Handle the error, if any
      // print('Failed to get app version: $e');
    }
  }

  Future<void> _fetchUserName() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('username') ?? 'User';
    });
  }

  Future<void> _saveUserName(String userName) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', userName);
    setState(() {
      _userName = userName;
    });
  }

  Future<void> _promptForUserName() async {
    final TextEditingController nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Enter your name'),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(hintText: 'Your Name'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final String userName = nameController.text;
                if (userName.isNotEmpty) {
                  _saveUserName(userName);
                }
                Navigator.of(context).pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _scheduleNotification(AppTask task) async {
    final notificationTimes = _calculateNotificationTimes(task.deadline);

    for (final scheduledTime in notificationTimes) {
      print(
          'Scheduling notification for task "${task.title}" at $scheduledTime');
      await widget.notificationsPlugin.zonedSchedule(
        task.id!, // Use a unique ID for each notification
        'Task App Reminder', // Notification title
        task.title, // Notification body
        scheduledTime, // Scheduled time
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'task_reminders',
            'Task Reminders',
            importance: Importance.max,
            priority: Priority.high,
            sound: RawResourceAndroidNotificationSound('notification_sound'),
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exact,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.wallClockTime,
      );
    }
  }

  List<tz.TZDateTime> _calculateNotificationTimes(DateTime deadline) {
    final List<tz.TZDateTime> notificationTimes = [];
    final now = tz.TZDateTime.now(tz.local);

    for (int hoursBefore = 3; hoursBefore <= 24; hoursBefore += 3) {
      final scheduledTime = tz.TZDateTime.from(deadline, tz.local)
          .subtract(Duration(hours: hoursBefore));
      if (scheduledTime.isAfter(now)) {
        notificationTimes.add(scheduledTime);
      }
    }
    // ignore: avoid_function_literals_in_foreach_calls
    notificationTimes
        .forEach((time) => print('Calculated notification time: $time'));
    return notificationTimes;
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
                        pickedDate.year,
                        pickedDate.month,
                        pickedDate.day,
                        deadline.hour,
                        deadline.minute,
                      );
                    }

                    //New addition to add time start here
                    // onPressed: () async {
                    //   final title = titleController.text;
                    //   DateTime deadline = task?.deadline ?? DateTime.now();

                    //   final DateTime? picked = await showDatePicker(
                    //     context: context,
                    //     initialDate: task?.deadline ?? DateTime.now(),
                    //     firstDate: DateTime.now(),
                    //     lastDate: DateTime(DateTime.now().year + 5),
                    //   );
                    //   if (picked != null) {
                    //     final TimeOfDay? timePicked = await showTimePicker(
                    //       // ignore: use_build_context_synchronously
                    //       context: context,
                    //       initialTime: TimeOfDay.now(),
                    //     );
                    //     if (timePicked != null) {
                    //       setState(() {
                    //         task?.deadline = DateTime(picked.year, picked.month,
                    //             picked.day, timePicked.hour, timePicked.minute);
                    //       });
                    //     }

                    // }
                    //New addition to add time ends here

                    if (task == null) {
                      final newTask = AppTask(title: title, deadline: deadline);
                      await _dbHelper.insertTask(newTask);
                      _scheduleNotification(newTask);
                    } else {
                      final updatedTask = AppTask(
                        id: task.id,
                        title: title,
                        deadline: deadline,
                        isCompleted: task.isCompleted,
                      );
                      await _dbHelper.updateTask(updatedTask);
                      _scheduleNotification(updatedTask);
                    }
                    _updateTaskList();

                    // ignore: use_build_context_synchronously
                    Navigator.pop(context);
                  },
                  child: Text(task == null ? 'Add Task' : 'Edit Task'),
                ),

                // ElevatedButton(

                //   },
                //   child: const Text('Select Deadline'),
                // ),
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
      MaterialPageRoute(builder: (context) => const HistoryScreen()),
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

  void _showAboutAppDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('About Task App'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text(
                'Task App helps you manage your daily tasks efficiently and reminds you about them with notifications. You can add, edit, and delete tasks, and view your task history and calendar.',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              Text(
                'Version: $_appVersion',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              const Text(
                'Developed by: Osgun4christ',
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
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
          //testing
          //   IconButton(
          //   icon: const Icon(Icons.notification_important),
          //   onPressed: _showTestNotification, // Trigger test notification
          // ),
        ],
      ),
      drawer: Drawer(
        width: MediaQuery.of(context).size.width *
            0.65, // Adjust the width as needed
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
              leading: const Icon(Icons.add_circle),
              title: const Text('Add Task'),
              onTap: _showAddTask,
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('Task History'),
              onTap: _showHistory,
            ),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('Calendar'),
              onTap: _showCalendar,
            ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit User Name'),
              onTap: _promptForUserName,
            ),
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text('About'),
              onTap: _showAboutAppDialog,
            ),
          ],
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Text(
                  'Welcome, $_userName!',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 92, 42, 139),
                  ),
                ),
                Text(
                  'Today is $_currentDate',
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color.fromARGB(255, 92, 42, 139),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _taskList.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(25.0),
                    child: Center(
                      child: Text(
                        'No tasks for today? Add one to keep your day organized!',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    ),
                  )
                : ListView.builder(
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

