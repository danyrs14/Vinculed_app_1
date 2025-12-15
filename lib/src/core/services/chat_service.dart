import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/chat_model.dart';
import '../models/chat_thread.dart';

class ChatService {
  ChatService._internal();

  static final ChatService instance = ChatService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const String chatsCollection = 'chats';

  String buildChatId(String uid1, String uid2) {
    final list = [uid1, uid2]..sort();
    return '${list[0]}_${list[1]}';
  }

  Stream<List<ChatMessage>> streamMessages(String chatId) {
    return _db
        .collection(chatsCollection)
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt')
        .snapshots()
        .map((snap) {
      return snap.docs
          .map((doc) => ChatMessage.fromDoc(doc, chatId))
          .toList();
    });
  }

  Stream<List<ChatThread>> streamUserChats(String uid) {
    return _db
        .collection(chatsCollection)
        .where('participants', arrayContains: uid)
        .snapshots()
        .map((snap) {
      final threads = snap.docs.map(ChatThread.fromDoc).toList();

      threads.sort((a, b) {
        final aDate =
            a.lastMessageAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDate =
            b.lastMessageAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bDate.compareTo(aDate);
      });

      return threads;
    });
  }

  Future<void> sendMessage({
    required String senderUid,
    required String receiverUid,
    required String text,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final chatId = buildChatId(senderUid, receiverUid);

    final chatRef = _db.collection(chatsCollection).doc(chatId);
    final msgRef = chatRef.collection('messages').doc();

    final message = ChatMessage.newMessage(
      chatId: chatId,
      senderUid: senderUid,
      receiverUid: receiverUid,
      text: trimmed,
    );

    // Nombres legibles para cada uid
    final String senderName = await _getDisplayNameForUid(senderUid);
    final String receiverName = await _getDisplayNameForUid(receiverUid);

    await _db.runTransaction((tx) async {
      // 1) LEER primero el documento del chat (regla de Firestore: todos los reads antes que los writes)
      final chatSnap = await tx.get(chatRef);

      Map<String, dynamic> participantsDisplayNames = {};

      final existingData = chatSnap.data() as Map<String, dynamic>?;
      if (existingData != null &&
          existingData['participantsDisplayNames'] is Map) {
        final raw = existingData['participantsDisplayNames'] as Map;
        participantsDisplayNames = raw.map(
              (key, value) => MapEntry(key.toString(), value.toString()),
        );
      }

      // 2) Solo actualizamos el nombre de un uid si no es "Usuario"
      if (senderName != 'Usuario') {
        participantsDisplayNames[senderUid] = senderName;
      }
      if (receiverName != 'Usuario') {
        participantsDisplayNames[receiverUid] = receiverName;
      }

      // 3) Ahora sí, hacer los WRITES
      tx.set(msgRef, message.toMap());

      tx.set(
        chatRef,
        {
          // Seguimos usando UID para las queries (no cambia nada)
          'participants': [senderUid, receiverUid],

          // Mapa de nombres legibles
          'participantsDisplayNames': participantsDisplayNames,

          'lastMessage': trimmed,
          'lastMessageAt': FieldValue.serverTimestamp(),
          'lastSenderUid': senderUid,
          'unreadCount': FieldValue.increment(1),
        },
        SetOptions(merge: true),
      );
    });
  }

  Future<void> markChatAsRead({
    required String chatId,
    required String userUid,
  }) async {
    final messagesQuery = await _db
        .collection(chatsCollection)
        .doc(chatId)
        .collection('messages')
        .where('receiverUid', isEqualTo: userUid)
        .where('isRead', isEqualTo: false)
        .get();

    final batch = _db.batch();

    for (final doc in messagesQuery.docs) {
      batch.update(doc.reference, {'isRead': true});
    }

    final chatRef = _db.collection(chatsCollection).doc(chatId);
    batch.update(chatRef, {'unreadCount': 0});

    await batch.commit();
  }

  Future<void> deleteMessage({
    required String chatId,
    required String messageId,
  }) async {
    final msgRef = _db
        .collection(chatsCollection)
        .doc(chatId)
        .collection('messages')
        .doc(messageId);

    await msgRef.delete();
  }

  Future<String> _getDisplayNameForUid(String uid) async {
    try {
      final current = _auth.currentUser;
      if (current != null && current.uid == uid) {
        final dn = current.displayName;
        if (dn != null && dn.trim().isNotEmpty) {
          return dn.trim();
        }
      }

      final userDoc = await _db.collection('users').doc(uid).get();
      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>? ?? {};
        final fromFs = (data['fullName'] ??
            data['displayName'] ??
            data['name'])
            ?.toString()
            .trim();
        if (fromFs != null && fromFs.isNotEmpty) {
          return fromFs;
        }
      }
    } catch (e) {
      print('Error obteniendo displayName para $uid: $e');
    }

    return 'Usuario';
  }
}
