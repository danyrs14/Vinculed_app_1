import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationLogService {
  NotificationLogService._();
  static final NotificationLogService instance = NotificationLogService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> saveForCurrentUser({
    required String title,
    required String body,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _db
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .add({
        'title': title,
        'body': body,
        'createdAt': FieldValue.serverTimestamp(),
        'read': false,
      });
    } catch (e) {
      print('Error al guardar notificación: $e');
    }
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamForCurrentUser() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream<QuerySnapshot<Map<String, dynamic>>>.empty();
    }

    return _db
        .collection('users')
        .doc(user.uid)
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> markAllAsReadForCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final snap = await _db
        .collection('users')
        .doc(user.uid)
        .collection('notifications')
        .where('read', isEqualTo: false)
        .get();

    if (snap.docs.isEmpty) return;

    final batch = _db.batch();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {'read': true});
    }
    await batch.commit();
  }
}
