import 'package:flutter/material.dart';
import '../database_helper.dart'; // Import your database helper class
import '../models/task.dart'; // Import your Task model class

class HistoryScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Task History'),
      ),
      body: FutureBuilder<List<Task>>(
        future: DatabaseHelper.instance.getCompletedTasks(),
        builder: (BuildContext context, AsyncSnapshot<List<Task>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No completed tasks.'));
          } else {
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (BuildContext context, int index) {
                final task = snapshot.data![index];
                return ListTile(
                  title: Text(task.title),
                  subtitle: Text('Completed on: ${task.deadline}'),
                  // You can customize this ListTile as needed
                );
              },
            );
          }
        },
      ),
    );
  }
}
