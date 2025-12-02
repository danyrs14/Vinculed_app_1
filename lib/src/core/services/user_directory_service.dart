import 'package:cloud_firestore/cloud_firestore.dart';

class UserDirectoryService {
  UserDirectoryService._();
  static final instance = UserDirectoryService._();

  final _db = FirebaseFirestore.instance;

  Future<void> syncAlumno({
    required String uid,
    required int idAlumno,
    required String name,
    String? email,
    String? photoUrl,
  }) async {
    final data = <String, dynamic>{
      'name': name,
      'tipo': 'alumno',
      'idAlumno': idAlumno,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (email != null && email.trim().isNotEmpty) {
      data['email'] = email.trim();
    }
    if (photoUrl != null && photoUrl.trim().isNotEmpty) {
      data['photoUrl'] = photoUrl.trim();
    }

    await _db.collection('users').doc(uid).set(
      data,
      SetOptions(merge: true),
    );
  }

  Future<void> syncReclutador({
    required String uid,
    required int idReclutador,
    required String name,
    String? email,
    String? photoUrl,
    String? companyName,
    String? companyLogoUrl,
  }) async {
    final data = <String, dynamic>{
      'name': name,
      'tipo': 'reclutador',
      'idReclutador': idReclutador,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (email != null && email.trim().isNotEmpty) {
      data['email'] = email.trim();
    }
    if (photoUrl != null && photoUrl.trim().isNotEmpty) {
      data['photoUrl'] = photoUrl.trim();
    }
    if (companyName != null && companyName.trim().isNotEmpty) {
      data['companyName'] = companyName.trim();
    }
    if (companyLogoUrl != null && companyLogoUrl.trim().isNotEmpty) {
      data['companyLogoUrl'] = companyLogoUrl.trim();
    }

    await _db.collection('users').doc(uid).set(
      data,
      SetOptions(merge: true),
    );
  }

  Future<void> updateFcmToken({
    required String uid,
    required String fcmToken,
  }) async {
    await _db.collection('users').doc(uid).set(
      {
        'fcmToken': fcmToken,
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }
}
