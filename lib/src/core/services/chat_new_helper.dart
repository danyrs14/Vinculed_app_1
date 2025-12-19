import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:vinculed_app_1/src/core/controllers/theme_controller.dart';

class ChatUserSelection {
  final String peerUid;
  final String displayName;

  ChatUserSelection({
    required this.peerUid,
    required this.displayName,
  });
}

class ChatNewHelper {
  ChatNewHelper._();

  static final ChatNewHelper instance = ChatNewHelper._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String _fallbackName(String uid) {
    if (uid.isEmpty) return 'Usuario';
    return 'Usuario';
  }

  Future<ChatUserSelection?> pickUserByName({
    required BuildContext context,
  }) async {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes iniciar sesión para iniciar un chat')),
      );
      return null;
    }

    final selection = await Navigator.push<ChatUserSelection>(
      context,
      MaterialPageRoute(
        builder: (_) => _ChatUserListPage(
          currentUid: currentUid,
          db: _db,
          fallbackName: _fallbackName,
        ),
      ),
    );

    return selection;
  }
}

class _ChatUserListPage extends StatelessWidget {
  final String currentUid;
  final FirebaseFirestore db;
  final String Function(String uid) fallbackName;

  const _ChatUserListPage({
    super.key,
    required this.currentUid,
    required this.db,
    required this.fallbackName,
  });

  String _buildDisplayName(Map<String, dynamic> data, String uid) {
    final fullName = (data['fullName'] ?? '').toString().trim();
    final displayName = (data['displayName'] ?? '').toString().trim();
    final name = (data['name'] ?? '').toString().trim();

    if (fullName.isNotEmpty) return fullName;
    if (displayName.isNotEmpty) return displayName;
    if (name.isNotEmpty) return name;
    return fallbackName(uid);
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Selecciona un usuario'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: db
            .collection('users')
            .orderBy('displayName', descending: false)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text('Error al cargar usuarios'),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final docs = snapshot.data?.docs ?? [];

          final filtered = docs.where((doc) => doc.id != currentUid).toList();

          if (filtered.isEmpty) {
            return const Center(
              child: Text('No hay usuarios disponibles para chatear'),
            );
          }

          return ListView.separated(
            itemCount: filtered.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final doc = filtered[index];
              final data = doc.data();
              final uid = doc.id;

              final displayName = _buildDisplayName(data, uid);
              final email = (data['email'] ?? '').toString();

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: theme.secundario(),
                  child: Text(
                    displayName.isNotEmpty
                        ? displayName[0].toUpperCase()
                        : '?',
                    style: TextStyle(color: theme.primario()),
                  ),
                ),
                title: Text(
                  displayName,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: email.isNotEmpty
                    ? Text(
                  email,
                  style: TextStyle(
                    color: theme.secundario(),
                  ),
                )
                    : null,
                onTap: () {
                  Navigator.pop(
                    context,
                    ChatUserSelection(
                      peerUid: uid,
                      displayName: displayName,
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
