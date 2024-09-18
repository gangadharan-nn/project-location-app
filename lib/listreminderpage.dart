import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'firestore_service.dart';
import 'reminder_model.dart';
import 'add_reminder.dart';

class ListRemindersPage extends StatelessWidget {
  final FirestoreService _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    String userId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: Text('Your Reminders'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AddReminderPage()),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<List<Reminder>>(
        stream: _firestoreService.getReminders(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No reminders found.'));
          }

          final reminders = snapshot.data!;

          return ListView.builder(
            itemCount: reminders.length,
            itemBuilder: (context, index) {
              final reminder = reminders[index];

              return ListTile(
                title: Text(reminder.title),
                subtitle: Text(DateFormat.yMd().add_jm().format(reminder.reminderTime)),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddReminderPage(reminder: reminder),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
