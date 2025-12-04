import 'package:cloud_firestore/cloud_firestore.dart';

class ChatThread {
  final String id;
  final List<String> participants;
  final String lastMessage;
  final String lastSenderUid;
  final DateTime? lastMessageAt;
  final int unreadCount;

  ChatThread({
    required this.id,
    required this.participants,
    required this.lastMessage,
    required this.lastSenderUid,
    required this.lastMessageAt,
    required this.unreadCount,
  });

  Map<String, dynamic> toMap() {
    return {
      'participants': participants,
      'lastMessage': lastMessage,
      'lastSenderUid': lastSenderUid,
      'lastMessageAt': lastMessageAt != null
          ? Timestamp.fromDate(lastMessageAt!)
          : null,
      'unreadCount': unreadCount,
    };
  }

  factory ChatThread.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    final ts = data['lastMessageAt'];
    DateTime? lastAt;
    if (ts is Timestamp) {
      lastAt = ts.toDate();
    } else if (ts is DateTime) {
      lastAt = ts;
    } else {
      lastAt = null;
    }

    return ChatThread(
      id: doc.id,
      participants: List<String>.from(
        data['participants'] ?? const <String>[],
      ),
      lastMessage: (data['lastMessage'] ?? '') as String,
      lastSenderUid: (data['lastSenderUid'] ?? '') as String,
      lastMessageAt: lastAt,
      unreadCount: (data['unreadCount'] ?? 0) as int,
    );
  }

  ChatThread copyWith({
    String? id,
    List<String>? participants,
    String? lastMessage,
    String? lastSenderUid,
    DateTime? lastMessageAt,
    int? unreadCount,
  }) {
    return ChatThread(
      id: id ?? this.id,
      participants: participants ?? this.participants,
      lastMessage: lastMessage ?? this.lastMessage,
      lastSenderUid: lastSenderUid ?? this.lastSenderUid,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }
}
