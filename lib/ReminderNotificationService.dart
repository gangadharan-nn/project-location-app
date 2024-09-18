import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:awesome_notifications/awesome_notifications.dart';

class ReminderNotificationService {
  final String userId;
  late final StreamSubscription _subscription;

  ReminderNotificationService({required this.userId}) {
    initNotifications();
    _listenToReminders();
    
  }

  void initNotifications() {
    AwesomeNotifications().initialize(
      'resource://drawable/app_icon',
      [
        NotificationChannel(
          channelKey: 'basic_channel',
          channelName: 'Basic Notifications',
          channelDescription: 'Notification channel for basic tests',
          defaultColor: Color(0xFF9D50DD),
          ledColor: Colors.white,
          importance: NotificationImportance.High,
        ),
      ],
    );
  }

  void _listenToReminders() {
    _subscription = FirebaseFirestore.instance
        .collection('reminders')
        .doc(userId)
        .collection('userReminders')
        .snapshots()
        .listen((snapshot) {
      print("Snapshot received: ${snapshot.docs.length} documents");
      for (var docChange in snapshot.docChanges) {
        print("Document change type: ${docChange.type}");
        if (docChange.type == DocumentChangeType.added) {
          createNotification(docChange.doc.id, docChange.doc['title'], docChange.doc['reminderTime']);
        }
      }
    });
  }

  void createNotification(String id, String title, String reminderTime) {
    DateTime scheduledDateTime = DateTime.parse(reminderTime);

    AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: id.hashCode,
        channelKey: 'basic_channel',
        title: title,
        body: 'Reminder scheduled for ${scheduledDateTime.toLocal()}',
        notificationLayout: NotificationLayout.Default,
      ),
      schedule: NotificationCalendar.fromDate(date: scheduledDateTime),
    );
  }

  void dispose() {
    _subscription.cancel();
  }
}
