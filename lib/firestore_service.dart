import 'package:cloud_firestore/cloud_firestore.dart';
import 'reminder_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> addReminder(Reminder reminder) {
    return _db
        .collection('reminders')
        .doc(reminder.userId)
        .collection('userReminders')
        .doc(reminder.id)
        .set(reminder.toMap());
  }

  Future<void> deleteReminder(String userId, String reminderId) {
    return _db
        .collection('reminders')
        .doc(userId)
        .collection('userReminders')
        .doc(reminderId)
        .delete();
  }

  Stream<List<Reminder>> getReminders(String userId) {
    return _db
        .collection('reminders')
        .doc(userId)
        .collection('userReminders')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Reminder.fromMap(doc.data())).toList());
  }
}
