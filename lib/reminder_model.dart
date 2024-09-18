class Reminder {
  final String id;
  final String userId;
  final String title;
  final DateTime reminderTime;
  final double? latitude; // Nullable, as the location might not always be set
  final double? longitude;

  Reminder({
    required this.id,
    required this.userId,
    required this.title,
    required this.reminderTime,
    this.latitude, // Optional location data
    this.longitude,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'reminderTime': reminderTime.toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  static Reminder fromMap(Map<String, dynamic> map) {
    return Reminder(
      id: map['id'],
      userId: map['userId'],
      title: map['title'],
      reminderTime: DateTime.parse(map['reminderTime']),
      latitude: map['latitude'] != null ? map['latitude'] as double : null,
      longitude: map['longitude'] != null ? map['longitude'] as double : null,
    );
  }
}
