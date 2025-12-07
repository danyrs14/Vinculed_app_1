import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static String _fallbackName(String uid) {
    if (uid.isEmpty) return 'Usuario';
    return 'Usuario';
  }

  static Future<ChatUserSelection?> pickUserByName({
    required BuildContext context,
  }) async {
    final controller = TextEditingController();

    final input = await showDialog<String>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Nuevo chat'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Nombre del usuario',
              hintText: 'Escribe el nombre del usuario',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                final value = controller.text.trim();
                Navigator.of(ctx).pop(value.isEmpty ? null : value);
              },
              child: const Text('Iniciar'),
            ),
          ],
        );
      },
    );

    if (input == null || input.trim().isEmpty) {
      return null;
    }

    final nameOrId = input.trim();

    String peerUid = '';
    String displayName = _fallbackName('');

    try {
      DocumentSnapshot<Map<String, dynamic>>? userDoc;

      final qFull = await _db
          .collection('users')
          .where('fullName', isEqualTo: nameOrId)
          .limit(1)
          .get();

      if (qFull.docs.isNotEmpty) {
        userDoc = qFull.docs.first;
      } else {
        final qDisplay = await _db
            .collection('users')
            .where('displayName', isEqualTo: nameOrId)
            .limit(1)
            .get();

        if (qDisplay.docs.isNotEmpty) {
          userDoc = qDisplay.docs.first;
        }
      }

      if (userDoc == null) {
        final docById =
        await _db.collection('users').doc(nameOrId).get();
        if (docById.exists) {
          userDoc = docById;
        }
      }

      if (userDoc == null || !userDoc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
            Text('No se encontró un usuario con ese nombre/UID'),
          ),
        );
        return null;
      }

      peerUid = userDoc.id;
      final data = userDoc.data() ?? {};
      displayName = (data['fullName'] ??
          data['displayName'] ??
          data['name'] ??
          _fallbackName(peerUid))
          .toString();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al buscar usuario: $e'),
        ),
      );
      return null;
    }

    if (peerUid.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo determinar el usuario destino'),
        ),
      );
      return null;
    }

    return ChatUserSelection(
      peerUid: peerUid,
      displayName: displayName,
    );
  }
}
