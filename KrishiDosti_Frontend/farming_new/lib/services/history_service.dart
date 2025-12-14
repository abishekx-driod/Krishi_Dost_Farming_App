import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HistoryService {
  static Future<void> addHistory({
    required String title,
    required String details,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final ref = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('history');

    await ref.add({
      'title': title,
      'details': details,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }
}
