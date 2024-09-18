import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart'; // Import for Google Maps
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';
import 'package:googleapis_auth/auth_io.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import 'firestore_service.dart';
import 'mapscreen.dart'; // Assuming you have a MapScreen to select the location
import 'reminder_model.dart';

class HostMeetingScreen extends StatefulWidget {
  @override
  _HostMeetingScreenState createState() => _HostMeetingScreenState();
}

class _HostMeetingScreenState extends State<HostMeetingScreen> {
  final List<String> selectedUsers = [];
  final TextEditingController titleController = TextEditingController();
  final TextEditingController dateController = TextEditingController();
  final TextEditingController timeController = TextEditingController();
  LatLng? selectedLocation; // Store the selected location
  final FirestoreService _firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
  }

  Future<void> _selectDate(BuildContext context) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        dateController.text = "${picked.toLocal()}".split(' ')[0];
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        timeController.text = picked.format(context);
      });
    }
  }

  Future<void> _selectLocation(BuildContext context) async {
    // Navigate to MapScreen to select the location
    final LatLng? location = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MapScreen(), // Your map screen to select location
      ),
    );
    if (location != null) {
      setState(() {
        selectedLocation = location; // Store the selected location
      });
    }
  }

  Future<void> _sendNotifications() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    final currentUserId = currentUser?.uid;
    // Add meeting details to Firestore (meetings collection)

    if (currentUserId != null && !selectedUsers.contains(currentUserId)) {
    selectedUsers.add(currentUserId);
  }
    await _addMeetingToFirestore(
      titleController.text,
      _parseDateTime(dateController.text, timeController.text),
      selectedLocation,
      selectedUsers,
    );

    if (currentUserId != null) {
      selectedUsers.remove(currentUserId);
    }
    // Send notifications to all selected users
    for (String userId in selectedUsers) {
      await _addReminderForUser(
        userId,
        titleController.text,
        _parseDateTime(dateController.text, timeController.text),
        selectedLocation, // Pass the selected location
      );
    }
  }

  // Function to create a meeting in Firestore
  Future<void> _addMeetingToFirestore(
    String title,
    DateTime dateTime,
    LatLng? location,
    List<String> participants,
  ) async {
    final meetingData = {
      'title': title,
      'date': DateFormat('yyyy-MM-dd').format(dateTime),
      'time': DateFormat('HH:mm').format(dateTime),
      'location': location != null
          ? {
              'latitude': location.latitude,
              'longitude': location.longitude,
            }
          : null,
      'participants': participants, // Array of user IDs
    };

    // Add a new document to the 'meetings' collection in Firestore
    await FirebaseFirestore.instance.collection('meetings').add(meetingData);
  }

  Future<void> _sendNotification(
      String fcmToken, String title, DateTime dateTime, LatLng? location) async {
    final serviceAccountJson = jsonDecode(dotenv.env['GOOGLE_CREDENTIALS']!);
    final credentials = ServiceAccountCredentials.fromJson(serviceAccountJson);
    final scopes = ['https://www.googleapis.com/auth/firebase.messaging'];
    final projectId = serviceAccountJson['project_id'];

    final client = await clientViaServiceAccount(credentials, scopes);

    final String url =
        'https://fcm.googleapis.com/v1/projects/$projectId/messages:send';
    final Map<String, dynamic> payload = {
      "message": {
        "token": fcmToken,
        "notification": {
          "title": "Meeting Reminder: $title",
          "body":
              "Meeting scheduled on ${DateFormat('yyyy-MM-dd – kk:mm').format(dateTime)}.",
        },
        "data": {
          "title": title,
          "body":
              "Meeting scheduled on ${DateFormat('yyyy-MM-dd – kk:mm').format(dateTime)}.",
          "scheduledTime": dateTime.toIso8601String(),
          "latitude": location?.latitude.toString(), // Include latitude
          "longitude": location?.longitude.toString(), // Include longitude
        },
      }
    };

    final http.Response response = await client.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(payload),
    );

    if (response.statusCode == 200) {
      print("Notification sent to token: $fcmToken");
    } else {
      print("Failed to send notification: ${response.body}");
    }
  }

  Future<void> _addReminderForUser(String userId, String title,
      DateTime dateTime, LatLng? location) async {
    final reminder = Reminder(
      id: const Uuid().v4(),
      userId: userId,
      title: title,
      reminderTime: dateTime,
      latitude: location?.latitude, // Include latitude if available
      longitude: location?.longitude, // Include longitude if available
    );

    await _firestoreService.addReminder(reminder);

    final userDoc =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();
    if (userDoc.exists) {
      final userData = userDoc.data() as Map<String, dynamic>;
      final fcmToken = userData['fcmToken'] as String?;
      if (fcmToken != null) {
        await _sendNotification(fcmToken, title, dateTime, location);
      } else {
        print("No FCM token found for user: $userId");
      }
    }
  }

  DateTime _parseDateTime(String date, String time) {
    final DateFormat dateFormat = DateFormat('yyyy-MM-dd');
    final DateFormat timeFormat = DateFormat('hh:mm a');
    final DateTime parsedDate = dateFormat.parse(date);
    final DateTime parsedTime = timeFormat.parse(time);
    return DateTime(
      parsedDate.year,
      parsedDate.month,
      parsedDate.day,
      parsedTime.hour,
      parsedTime.minute,
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final currentUserId = currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Host a Meeting'),
      ),
      body: Column(
        children: [
          TextField(
            controller: titleController,
            decoration: const InputDecoration(labelText: 'Title'),
          ),
          TextField(
            controller: dateController,
            decoration: const InputDecoration(
              labelText: 'Date',
              suffixIcon: Icon(Icons.calendar_today),
            ),
            readOnly: true,
            onTap: () => _selectDate(context),
          ),
          TextField(
            controller: timeController,
            decoration: const InputDecoration(
              labelText: 'Time',
              suffixIcon: Icon(Icons.access_time),
            ),
            readOnly: true,
            onTap: () => _selectTime(context),
          ),
          ElevatedButton(
            onPressed: () => _selectLocation(context), // Select Location button
            child: Text(
              selectedLocation == null
                  ? 'Select Meeting Location'
                  : 'Location Selected',
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('users').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const CircularProgressIndicator();
                return ListView(
                  children: snapshot.data!.docs.map((userDoc) {
                    final userId = userDoc.id;
                    return CheckboxListTile(
                      title: Text(userDoc['username']),
                      value: selectedUsers.contains(userId),
                      onChanged: currentUserId != userId
                          ? (bool? value) {
                              setState(() {
                                if (value == true) {
                                  selectedUsers.add(userId);
                                } else {
                                  selectedUsers.remove(userId);
                                }
                              });
                            }
                          : null,
                    );
                  }).toList(),
                );
              },
            ),
          ),
          Row(
            children: [
              ElevatedButton(
                onPressed: _sendNotifications,
                child: const Text('Send Notifications'),
              )
            ],
          ),
        ],
      ),
    );
  }
}
