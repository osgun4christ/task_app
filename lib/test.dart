// import 'package:flutter/material.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// //import 'package:intl/intl.dart';
// import 'package:task_app/database_helper.dart';
// import 'package:task_app/main.dart';
// import 'package:task_app/models/task.dart';
// import 'package:task_app/screens/task_list_screen.dart';

// void main() {
//   runApp(MyApp());
//   addTestData();
  
// }

// class MyApp extends StatelessWidget {
// final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

//   MyApp({super.key}){
//     _initializeNotifications();
//   }

//   Future<void> _initializeNotifications() async {
//     const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
//     const InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid);

//     await _notificationsPlugin.initialize(
//       initializationSettings,
//       onDidReceiveNotificationResponse: (NotificationResponse response) {
//         // Handle the notification response here (if app is in foreground)
//         print('Foreground notification received: ${response.payload}');
//       },
//       onDidReceiveBackgroundNotificationResponse: backgroundNotificationHandler, // Register the background handler
//     );
//   }
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       home: TaskListScreen(
//                 notificationsPlugin: _notificationsPlugin,
//                 initialDate: DateTime.now(),),
//     );
//   }

  
// }

// void addTestData() async {
//   final dbHelper = DatabaseHelper.instance;

//   // Add past tasks
//   await dbHelper.insertTask(AppTask(
//     title: 'Past Task 1',
//     deadline: DateTime.now().subtract(const Duration(days: 1)), // 1 day ago
//     isCompleted: false,
//   ));

//   await dbHelper.insertTask(AppTask(
//     title: 'Past Task 2',
//     deadline: DateTime.now().subtract(const Duration(days: 2)), // 2 days ago
//     isCompleted: true,
//   ));

//   // Add current tasks
//   await dbHelper.insertTask(AppTask(
//     title: 'Current Task 1',
//     deadline: DateTime.now(), // Today
//     isCompleted: false,
//   ));

//   await dbHelper.insertTask(AppTask(
//     title: 'Current Task 2',
//     deadline: DateTime.now(), // Today
//     isCompleted: true,
//   ));


// }
// void archiveOldCompletedTasks() async {
//   print('Archived old completed tasks');
// }