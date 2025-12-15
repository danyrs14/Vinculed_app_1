import 'package:cloud_firestore/cloud_firestore.dart';

class ChatThread {
  final String id;
  final List<String> participants;
  final String lastMessage;
  final String lastSenderUid;
  final DateTime? lastMessageAt;
  final int unreadCount;

  final Map<String, dynamic>? participantsDisplayNames;

  ChatThread({
    required this.id,
    required this.participants,
    required this.lastMessage,
    required this.lastSenderUid,
    required this.lastMessageAt,
    required this.unreadCount,
    this.participantsDisplayNames,
  });

  Map<String, dynamic> toMap() {
    return {
      'participants': participants,
      'lastMessage': lastMessage,
      'lastSenderUid': lastSenderUid,
      'lastMessageAt':
      lastMessageAt != null ? Timestamp.fromDate(lastMessageAt!) : null,
      'unreadCount': unreadCount,
      if (participantsDisplayNames != null)
        'participantsDisplayNames': participantsDisplayNames,
    };
  }

  factory ChatThread.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    // lastMessageAt
    final ts = data['lastMessageAt'];
    DateTime? lastAt;
    if (ts is Timestamp) {
      lastAt = ts.toDate();
    } else if (ts is DateTime) {
      lastAt = ts;
    } else {
      lastAt = null;
    }

    // participants
    final rawParticipants = data['participants'];
    final List<String> participants = rawParticipants is List
        ? rawParticipants.map((e) => e.toString()).toList()
        : <String>[];

    // unreadCount seguro como int
    int unread = 0;
    final unreadRaw = data['unreadCount'];
    if (unreadRaw is int) {
      unread = unreadRaw;
    } else if (unreadRaw is num) {
      unread = unreadRaw.toInt();
    }

    // participantsDisplayNames
    Map<String, dynamic>? namesMap;
    final rawNames = data['participantsDisplayNames'];
    if (rawNames is Map) {
      namesMap = rawNames.map(
            (key, value) => MapEntry(key.toString(), value),
      );
    }

    return ChatThread(
      id: doc.id,
      participants: participants,
      lastMessage: (data['lastMessage'] ?? '') as String,
      lastSenderUid: (data['lastSenderUid'] ?? '') as String,
      lastMessageAt: lastAt,
      unreadCount: unread,
      participantsDisplayNames: namesMap,
    );
  }

  ChatThread copyWith({
    String? id,
    List<String>? participants,
    String? lastMessage,
    String? lastSenderUid,
    DateTime? lastMessageAt,
    int? unreadCount,
    Map<String, dynamic>? participantsDisplayNames,
  }) {
    return ChatThread(
      id: id ?? this.id,
      participants: participants ?? this.participants,
      lastMessage: lastMessage ?? this.lastMessage,
      lastSenderUid: lastSenderUid ?? this.lastSenderUid,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      unreadCount: unreadCount ?? this.unreadCount,
      participantsDisplayNames:
      participantsDisplayNames ?? this.participantsDisplayNames,
    );
  }
}
