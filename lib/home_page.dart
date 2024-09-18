import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:project/listreminderpage.dart';
import 'package:project/login-signup/login_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'hostmeetinscreen.dart';
import 'location/location_tracker.dart';
import 'meeting_details_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? userId;
  String? meetingId; // To store the dynamic meeting ID
  bool isLoading = true; // To show a loading indicator when fetching data

  @override
  void initState() {
    super.initState();
    _getCurrentUser(); // Fetch the current user and meeting details
  }

  // Function to get the current user
  Future<void> _getCurrentUser() async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      setState(() {
        userId = currentUser.uid; // Save the user ID
      });
      await _fetchUserMeeting(currentUser.uid); // Fetch the meeting for the current user
    } else {
      setState(() {
        isLoading = false; // Stop loading if no user is signed in
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No user is currently signed in.')),
      );
    }
  }

  Future<void> _logout() async {
    // Clear SharedPreferences
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);

    // Log out from Firebase
    await FirebaseAuth.instance.signOut();

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    }
  }

  // Function to fetch the user's meeting from Firestore
  Future<void> _fetchUserMeeting(String userId) async {
    try {
      // Query Firestore to get meetings where the current user is a participant
      final meetingsQuery = await FirebaseFirestore.instance
          .collection('meetings')
          .where('participants', arrayContains: userId)
          .get();

      if (meetingsQuery.docs.isNotEmpty) {
        // Get the first meeting found
        final meeting = meetingsQuery.docs.first;
        setState(() {
          meetingId = meeting.id; // Save the meeting ID
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No meetings found for the current user.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching meetings: $e')),
      );
    } finally {
      setState(() {
        isLoading = false; // Stop loading after fetching data
      });
    }
  }

  // Function to refresh the page (simulates fetching data again)
  Future<void> _refreshPage() async {
    setState(() {
      isLoading = true; // Show the loading indicator while refreshing
    });
    await _getCurrentUser(); // Re-fetch user data
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Page'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          )
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshPage, // Triggered when pulled down
        child: isLoading
            ? const Center(child: CircularProgressIndicator()) // Show a loading indicator while fetching
            : ListView(
                padding: const EdgeInsets.all(20.0), // Wrap with ListView to make it scrollable
                children: [
                  // ElevatedButton(
                  //   onPressed: () {
                  //     Navigator.push(
                  //       context,
                  //       MaterialPageRoute(
                  //           builder: (context) => const LocationTracker()),
                  //     );
                  //   },
                  //   child: const Text('Go to Location Tracker'),
                  // ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => ListRemindersPage()),
                      );
                    },
                    child: const Text('Set Reminder'),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => HostMeetingScreen()),
                      );
                    },
                    child: const Text("Act as a Host"),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () async {
                      LocationService locationService = LocationService();
                      await locationService.getCurrentLocation();
                      if (meetingId == null) {
                        // Show a message if no meeting is scheduled for the user
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('No meeting scheduled'),
                          ),
                        );
                      } else {
                        // Navigate to MeetingDetailsScreen with the dynamic meetingId
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MeetingScreen(
                              userId: userId ?? 'Unknown User',
                              meetingId: meetingId!, // Pass the dynamic meetingId
                            ),
                          ),
                        );
                      }
                    },
                    child: const Text("View Meeting Location"),
                  ),
                ],
              ),
      ),
    );
  }
}
