import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/chat_model.dart';
import '../models/chat_thread.dart';

class ChatService {
  ChatService._internal();

  static final ChatService instance = ChatService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

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
        .orderBy('lastMessageAt', descending: true)
        .snapshots()
        .map((snap) {
      return snap.docs.map(ChatThread.fromDoc).toList();
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

    await _db.runTransaction((tx) async {
      tx.set(msgRef, message.toMap());

      tx.set(
        chatRef,
        {
          'participants': [senderUid, receiverUid],
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
}
