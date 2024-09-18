import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

void setupFirebaseMessaging() {
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    if (message.data.isNotEmpty) {
      String title = message.data['title'] ?? 'Reminder';
      String body = message.data['body'] ?? '';
      DateTime scheduledTime = DateTime.parse(message.data['scheduledTime']);

      // Schedule the local notification
      AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
          channelKey: 'basic_channel',
          title: title,
          body: body,
        ),
        schedule: NotificationCalendar.fromDate(date: scheduledTime),
      );
    }
  });

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Schedule the notification in background when receiving the FCM message
  if (message.data.isNotEmpty) {
    String title = message.data['title'] ?? 'Reminder';
    String body = message.data['body'] ?? '';
    DateTime scheduledTime = DateTime.parse(message.data['scheduledTime']);

    // Schedule local notification
    AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
        channelKey: 'basic_channel',
        title: title,
        body: body,
      ),
      schedule: NotificationCalendar.fromDate(date: scheduledTime),
    );
  }
}
