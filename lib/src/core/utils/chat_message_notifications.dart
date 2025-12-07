import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vinculed_app_1/src/core/services/local_push_service.dart';


class ChatMessageNotifications {
  ChatMessageNotifications._();
  static final ChatMessageNotifications instance =
  ChatMessageNotifications._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;
  final Map<String, String> _nameCache = {};

  Future<void> start(String currentUid) async {
    await LocalPushService.instance.init();

    await _sub?.cancel();

    _sub = _db
        .collectionGroup('messages')
        .where('receiverUid', isEqualTo: currentUid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snapshot) async {
      for (final change in snapshot.docChanges) {
        if (change.type != DocumentChangeType.added) continue;

        final data = change.doc.data();
        if (data == null) continue;

        final senderUid = (data['senderUid'] ?? '').toString();
        final text = (data['text'] ?? '').toString();

        final senderName = await _getSenderName(senderUid);
        final body = text.isEmpty ? 'Te ha enviado un mensaje.' : text;

        await LocalPushService.instance.showSimple(
          title: senderName,
          body: body,
        );
      }
    });
  }

  Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;
  }

  Future<String> _getSenderName(String uid) async {
    if (uid.isEmpty) return 'Nuevo mensaje';

    if (_nameCache.containsKey(uid)) {
      return _nameCache[uid]!;
    }

    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>? ?? {};
        final name = (data['fullName'] ??
            data['displayName'] ??
            data['name'] ??
            'Nuevo mensaje')
            .toString();
        _nameCache[uid] = name;
        return name;
      }
    } catch (_) {
    }

    return 'Nuevo mensaje';
  }
}
