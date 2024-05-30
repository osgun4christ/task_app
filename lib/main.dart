import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'screens/task_list_screen.dart';
import 'screens/user_name_screen.dart';

void main() {
  tz.initializeTimeZones();
  runApp(TaskApp());
}

class TaskApp extends StatelessWidget {
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  TaskApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Task App',
      theme: ThemeData(
        primarySwatch: Colors.purple,
      ),
      home: FutureBuilder<bool>(
        future: _isUserNameSet(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else {
            if (snapshot.data == true) {
              return TaskListScreen(
                notificationsPlugin: _flutterLocalNotificationsPlugin,
                initialDate: DateTime.now(),
              );
            } else {
              return UserNameScreen(
                notificationsPlugin: _flutterLocalNotificationsPlugin,
              );
            }
          }
        },
      ),
    );
  }

  Future<bool> _isUserNameSet() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('userName') != null;
  }
}
