import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'screens/task_list_screen.dart';
import 'screens/flash_screen.dart';

Future<void> main() async{  
  // Ensure WidgetsFlutterBinding is initialized
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();
  runApp(TaskApp());
  WidgetsFlutterBinding.ensureInitialized();
}

// Define the background notification handler as a top-level function
void backgroundNotificationHandler(NotificationResponse notificationResponse) {
  // Handle the background notification response here
  print('Background notification received: ${notificationResponse.payload}');
}
class TaskApp extends StatelessWidget {
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  TaskApp({super.key}){
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid);

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle the notification response here (if app is in foreground)
        print('Foreground notification received: ${response.payload}');
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
      debugShowCheckedModeBanner: false,
      home: FutureBuilder<bool>(
        future: _isUserNameSet(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else {
            if (snapshot.data == true) {
              return TaskListScreen(
                notificationsPlugin: _notificationsPlugin,
                initialDate: DateTime.now(),
              );
            } else {
              return FlashScreen(
                notificationsPlugin: _notificationsPlugin,
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
