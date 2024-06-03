import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:task_app/database_helper.dart';
import 'package:task_app/models/task.dart';
import 'task_list_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  MyApp({super.key}) {
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
    
    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle the notification response here (if app is in foreground)
      },
      onDidReceiveBackgroundNotificationResponse: backgroundNotificationHandler, // Register the background handler
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Task App',
      theme: ThemeData(
        primarySwatch: Colors.purple,
      ),
      home: CalendarScreen(notificationsPlugin: _notificationsPlugin),
    );
  }
}

// backgroundNotificationHandler function defined above
void backgroundNotificationHandler(NotificationResponse notificationResponse) {
  // Handle background notification here
}


class CalendarScreen extends StatefulWidget {
  final FlutterLocalNotificationsPlugin notificationsPlugin;

  const CalendarScreen({super.key, required this.notificationsPlugin});

  @override
  // ignore: library_private_types_in_public_api
  _CalendarScreenState createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar'),
      ),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2010, 10, 16),
            lastDay: DateTime.utc(2030, 3, 14),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            selectedDayPredicate: (day) {
              return isSameDay(_selectedDay, day);
            },
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay; // update `_focusedDay` here as well
              });
            },
            onFormatChanged: (format) {
              if (_calendarFormat != format) {
                setState(() {
                  _calendarFormat = format;
                });
              }
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
            },
          ),
          const SizedBox(height: 20),
ElevatedButton(
  onPressed: () {
    _addTask(context);
  },
  child: Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16.0),
    child: Text(
      'Add Task to ${DateFormat.yMMMd().format(_selectedDay.toLocal())}',
      textAlign: TextAlign.center,
    ),
  ),
),

        ],
      ),
    );
  }

  void _addTask(BuildContext context) {
    final titleController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Task Title'),
                ),
                const SizedBox(height: 20.0),
                ElevatedButton(
                  onPressed: () {
                    final title = titleController.text;
                    if (title.isNotEmpty) {
                      final newTask = AppTask(title: title, deadline: _selectedDay);
                      DatabaseHelper.instance.insertTask(newTask).then((_) {
                        Navigator.pop(context);
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TaskListScreen(
                              notificationsPlugin: widget.notificationsPlugin,
                              initialDate: _selectedDay,
                            ),
                          ),
                        );
                      });
                    }
                  },
                  child: const Text('Add Task'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
