import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessage {
  final String id;
  final String chatId;
  final String senderUid;
  final String receiverUid;
  final String text;
  final DateTime createdAt;
  final bool isRead;

  ChatMessage({
    required this.id,
    required this.chatId,
    required this.senderUid,
    required this.receiverUid,
    required this.text,
    required this.createdAt,
    required this.isRead,
  });

  factory ChatMessage.newMessage({
    required String chatId,
    required String senderUid,
    required String receiverUid,
    required String text,
  }) {
    return ChatMessage(
      id: '',
      chatId: chatId,
      senderUid: senderUid,
      receiverUid: receiverUid,
      text: text.trim(),
      createdAt: DateTime.now(),
      isRead: false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderUid': senderUid,
      'receiverUid': receiverUid,
      'text': text,
      'createdAt': Timestamp.fromDate(createdAt),
      'isRead': isRead,
    };
  }

  factory ChatMessage.fromDoc(DocumentSnapshot doc, String chatId) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    final ts = data['createdAt'];
    DateTime created;
    if (ts is Timestamp) {
      created = ts.toDate();
    } else if (ts is DateTime) {
      created = ts;
    } else {
      created = DateTime.now();
    }

    return ChatMessage(
      id: doc.id,
      chatId: chatId,
      senderUid: (data['senderUid'] ?? '') as String,
      receiverUid: (data['receiverUid'] ?? '') as String,
      text: (data['text'] ?? '') as String,
      createdAt: created,
      isRead: (data['isRead'] ?? false) as bool,
    );
  }

  ChatMessage copyWith({
    String? id,
    String? chatId,
    String? senderUid,
    String? receiverUid,
    String? text,
    DateTime? createdAt,
    bool? isRead,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      senderUid: senderUid ?? this.senderUid,
      receiverUid: receiverUid ?? this.receiverUid,
      text: text ?? this.text,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
    );
  }
}
