import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MeetingScreen extends StatefulWidget {
  final String userId;
  final String meetingId;

  const MeetingScreen({required this.userId, required this.meetingId, Key? key})
      : super(key: key);

  @override
  _MeetingScreenState createState() => _MeetingScreenState();
}

class _MeetingScreenState extends State<MeetingScreen> {
  Map<String, dynamic>? meetingDetails;
  List<String> participantUsernames = [];
  Set<Marker> markers = {};
  GoogleMapController? mapController;
  LatLng? meetingLocation;
  bool isMapLoading = true;
  

  @override
  void initState() {
    super.initState();
    _fetchMeetingDetails();
  }

  // Function to fetch meeting details and participants' usernames
  Future<void> _fetchMeetingDetails() async {
    try {
      // Retrieve the meeting document from Firestore using the meetingId
      DocumentSnapshot meetingSnapshot = await FirebaseFirestore.instance
          .collection('meetings')
          .doc(widget.meetingId)
          .get();

      if (meetingSnapshot.exists) {
        setState(() {
          meetingDetails = meetingSnapshot.data() as Map<String, dynamic>?;
        });

        if (meetingDetails != null) {
          // Set meeting location
          double? latitude = meetingDetails!['location']?['latitude'];
          double? longitude = meetingDetails!['location']?['longitude'];
          if (latitude != null && longitude != null) {
            meetingLocation = LatLng(latitude, longitude);
            markers.add(Marker(
              markerId: const MarkerId('meetingLocation'),
              position: meetingLocation!,
              infoWindow: const InfoWindow(title: 'Meeting Location'),
            ));
          }

          // Fetch the participants' usernames and locations
          if (meetingDetails!['participants'] != null) {
            List<dynamic> participantIds = meetingDetails!['participants'];
            await _fetchParticipantUsernamesAndLocations(participantIds);
          }
        }
        setState(() {
          isMapLoading = false;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Meeting not found')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching meeting details: $e')),
      );
    }
  }

  // Function to fetch the usernames and locations of participants
  Future<void> _fetchParticipantUsernamesAndLocations(
      List<dynamic> participantIds) async {
    List<String> usernames = [];
    try {
      for (String participantId in participantIds) {
        // Fetch username
        DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(participantId)
            .get();
            Map<String, dynamic>? userData =
              userSnapshot.data() as Map<String, dynamic>?;
        if (userSnapshot.exists) {
          if (userData != null && userData['username'] != null) {
            usernames.add(userData['username']);
          } else {
            usernames.add('Unknown');
          }
        }

        // Fetch location
        DocumentSnapshot locationSnapshot = await FirebaseFirestore.instance
            .collection('locations')
            .doc(participantId)
            .get();
        if (locationSnapshot.exists) {
          Map<String, dynamic>? locationData =
              locationSnapshot.data() as Map<String, dynamic>?;
          if (locationData != null) {
            double? lat = locationData['latitude'];
            double? lng = locationData['longitude'];
            if (lat != null && lng != null) {
              markers.add(Marker(
                markerId: MarkerId(participantId),
                position: LatLng(lat, lng),
                infoWindow: InfoWindow(title: userData?['username'] ?? 'Unknown'),
              ));
            }
          }
        }
      }

      setState(() {
        participantUsernames = usernames;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching participant data: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meeting Details'),
      ),
      body: meetingDetails == null
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Meeting Title: ${meetingDetails!['title'] ?? 'No title'}',
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Meeting Date: ${meetingDetails!['date'] ?? 'Not provided'}',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Meeting Time: ${meetingDetails!['time'] ?? 'Not provided'}',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Location: Latitude: ${meetingDetails!['location']?['latitude'] ?? 'Not provided'}, '
                    'Longitude: ${meetingDetails!['location']?['longitude'] ?? 'Not provided'}',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Participants: ${participantUsernames.isNotEmpty ? participantUsernames.join(', ') : 'None'}',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 20),
                  isMapLoading
                      ? const CircularProgressIndicator()
                      : SizedBox(
                          height: 300,
                          child: GoogleMap(
                            onMapCreated: (GoogleMapController controller) {
                              mapController = controller;
                            },
                            initialCameraPosition: CameraPosition(
                              target: meetingLocation ?? const LatLng(0, 0),
                              zoom: 14.0,
                            ),
                            markers: markers,
                          ),
                        ),
                ],
              ),
            ),
    );
  }
}
