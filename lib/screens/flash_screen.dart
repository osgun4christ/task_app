// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'task_list_screen.dart';

class FlashScreen extends StatefulWidget {
  final FlutterLocalNotificationsPlugin notificationsPlugin;

  const FlashScreen({super.key, required this.notificationsPlugin});

  @override
  _FlashScreenState createState() => _FlashScreenState();
}

class _FlashScreenState extends State<FlashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToTaskListScreen();
  }

  Future<void> _navigateToTaskListScreen() async {
    await Future.delayed(const Duration(seconds: 3));
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => TaskListScreen(
          notificationsPlugin: widget.notificationsPlugin,
          initialDate: DateTime.now(),
        ),
      ),
    );
  }

@override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/taskapp.png',
              width: 100, // Adjust the width as needed
              height: 100, // Adjust the height as needed
            ),
            const SizedBox(height: 20), // Add spacing between the image and text
            const Text(
              'Welcome to Task App',
              style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
