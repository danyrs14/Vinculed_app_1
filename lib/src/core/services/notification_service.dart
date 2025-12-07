import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:vinculed_app_1/src/core/services/local_push_service.dart';

class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();

  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _messagesSub;

  Future<void> initPush() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print(
            'initPush(): No hay usuario autenticado, no se puede registrar FCM.');
        return;
      }

      print('Usuario autenticado: ${user.uid}');

      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      print('Permisos FCM: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        print('Usuario denegó permisos de notificación');
        return;
      }

      final token = await FirebaseMessaging.instance.getToken();

      print('Token FCM obtenido: $token');

      if (token == null) {
        print('No se pudo obtener token FCM');
        return;
      }

      await _db.collection('users').doc(user.uid).set(
        {
          'fcmToken': token,
          'displayName': user.displayName ?? 'Usuario',
        },
        SetOptions(merge: true),
      );

      print('Token FCM guardado correctamente en users/${user.uid}');

      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
        print('Token FCM actualizado: $newToken');

        await _db.collection('users').doc(user.uid).set(
          {
            'fcmToken': newToken,
            'displayName': user.displayName ?? 'Usuario',
          },
          SetOptions(merge: true),
        );

        print('Token FCM actualizado en Firestore.');
      });
    } catch (e, st) {
      print('ERROR en initPush(): $e');
      print('STACK TRACE: $st');
    }
  }

  Future<void> addNotification({
    required String userId,
    required String title,
    required String body,
    String? type,
    Map<String, dynamic>? extraData,
  }) async {
    try {
      final docRef = _db
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .doc(); // id auto

      await docRef.set({
        'title': title,
        'body': body,
        'type': type ?? 'general',
        'extra': extraData,
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      print(
          'Notificación guardada en users/$userId/notifications/${docRef.id}');

      await LocalPushService.instance.showSimple(
        title: title,
        body: body,
      );
    } catch (e, st) {
      print('ERROR al guardar notificación: $e');
      print('STACK: $st');
    }
  }

  Future<void> startListeningToIncomingMessages() async {
    final user = _auth.currentUser;
    if (user == null) {
      print(
          'startListeningToIncomingMessages(): no hay usuario logueado, no se puede escuchar mensajes.');
      return;
    }

    final uid = user.uid;
    await _messagesSub?.cancel();

    // 👇 Para evitar que el primer snapshot (histórico) dispare notificaciones
    bool firstSnapshot = true;

    _messagesSub = _db
        .collectionGroup('messages')
        .where('receiverUid', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snapshot) async {
      if (firstSnapshot) {
        firstSnapshot = false;
        print(
            'startListeningToIncomingMessages(): primer snapshot ignorado (histórico).');
        return;
      }

      for (final change in snapshot.docChanges) {
        // Solo reaccionamos a mensajes nuevos
        if (change.type != DocumentChangeType.added) continue;

        final data = change.doc.data();
        if (data == null) continue;

        final senderUid = data['senderUid'] as String? ?? '';
        final receiverUid = data['receiverUid'] as String? ?? '';
        final text =
            data['text'] as String? ?? 'Tienes un nuevo mensaje';

        if (receiverUid != uid) continue;
        if (senderUid == uid) continue;

        // ================== OBTENER NOMBRE DEL REMITENTE ==================
        String senderName = 'Usuario';
        try {
          if (senderUid.isNotEmpty) {
            final senderDoc =
            await _db.collection('users').doc(senderUid).get();
            if (senderDoc.exists) {
              final senderData =
                  senderDoc.data() as Map<String, dynamic>? ?? {};
              senderName = (senderData['fullName'] ??
                  senderData['displayName'] ??
                  senderData['name'] ??
                  senderName)
                  .toString();
            }
          }
        } catch (e) {
          print('Error al leer nombre del remitente ($senderUid): $e');
        }

        final title = '$senderName';
        // ================================================================

        await NotificationService.instance.addNotification(
          userId: uid,
          title: title,
          body: text,
          type: 'message',
          extraData: {
            'messageId': change.doc.id,
            'chatPath': change.doc.reference.parent.parent?.path,
            'senderUid': senderUid,
          },
        );
      }
    }, onError: (e, st) {
      print('ERROR en startListeningToIncomingMessages(): $e');
      print('STACK: $st');
    });
  }

  Future<void> dispose() async {
    await _messagesSub?.cancel();
    _messagesSub = null;
  }
}
