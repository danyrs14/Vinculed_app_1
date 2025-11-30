import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();

  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  Future<void> initPush() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('initPush(): No hay usuario autenticado, no se puede registrar FCM.');
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
        },
        SetOptions(merge: true),
      );

      print('Token FCM guardado correctamente en users/${user.uid}');

      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
        print('Token FCM actualizado: $newToken');

        await _db.collection('users').doc(user.uid).set(
          {
            'fcmToken': newToken,
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
}
