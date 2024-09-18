import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:project/ReminderNotificationService.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firestore_service.dart';
import 'reminder_model.dart';

class AddReminderPage extends StatefulWidget {
  final Reminder? reminder;

  AddReminderPage({this.reminder});

  @override
  _AddReminderPageState createState() => _AddReminderPageState();
}

class _AddReminderPageState extends State<AddReminderPage> {
  final _formKey = GlobalKey<FormState>();
  String _title = '';
  DateTime _reminderTime = DateTime.now();
  final FirestoreService _firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    if (widget.reminder != null) {
      _title = widget.reminder!.title;
      _reminderTime = widget.reminder!.reminderTime;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.reminder == null ? 'Add Reminder' : 'Edit Reminder'),
        actions: [
          if (widget.reminder != null)
            IconButton(
              icon: Icon(Icons.delete),
              onPressed: () async {
                String userId = FirebaseAuth.instance.currentUser!.uid;
                await _firestoreService.deleteReminder(userId, widget.reminder!.id);
                Navigator.pop(context);
              },
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                initialValue: _title,
                decoration: InputDecoration(labelText: 'Title'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
                onSaved: (value) => _title = value!,
              ),
              SizedBox(height: 20),
              InkWell(
                onTap: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: _reminderTime,
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2101),
                  );
                  if (picked != null && picked != _reminderTime) {
                    final TimeOfDay? pickedTime = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.fromDateTime(_reminderTime),
                    );
                    if (pickedTime != null) {
                      setState(() {
                        _reminderTime = DateTime(
                          picked.year,
                          picked.month,
                          picked.day,
                          pickedTime.hour,
                          pickedTime.minute,
                        );
                      });
                    }
                  }
                },
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Reminder Time',
                    border: OutlineInputBorder(),
                  ),
                  child: Text(
                    '${DateFormat.yMd().add_jm().format(_reminderTime)}',
                    style: TextStyle(fontSize: 18.0),
                  ),
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();

                    // Ensure userId is obtained from FirebaseAuth
                    String userId = FirebaseAuth.instance.currentUser!.uid;

                    final reminder = Reminder(
                      id: widget.reminder?.id ?? Uuid().v4(),
                      userId: userId,
                      title: _title,
                      reminderTime: _reminderTime,
                    );

                    await _firestoreService.addReminder(reminder);

                    // Initialize and call ReminderNotificationService
                    final reminderNotificationService = ReminderNotificationService(userId: userId);
                    reminderNotificationService.initNotifications();
                    reminderNotificationService.createNotification(
                      reminder.id,
                      reminder.title,
                      reminder.reminderTime.toIso8601String(),
                    );

                    Navigator.pop(context);
                  }
                },
                child: Text(widget.reminder == null ? 'Add Reminder' : 'Update Reminder'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
