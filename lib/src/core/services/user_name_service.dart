import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import 'package:vinculed_app_1/src/core/providers/user_provider.dart';

class UserNameService {
  UserNameService._internal();

  static final UserNameService instance = UserNameService._internal();

  final Map<String, String> _cache = {};

  Future<String> getNameByUid(BuildContext context, String uid) async {
    if (uid.isEmpty) return 'Usuario';
    if (_cache.containsKey(uid)) {
      return _cache[uid]!;
    }

    try {
      final userProv = context.read<UserDataProvider>();
      final headers = await userProv.getAuthHeaders();

      // TODO: CAMBIA ESTA URL POR TU ENDPOINT REAL
      final uri = Uri.parse(
        'https://oda-talent-back-81413836179.us-central1.run.app/api/usuarios/by_uid',
      ).replace(queryParameters: {
        'uid': uid,
      });

      final resp = await http.get(uri, headers: headers);

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        final data = jsonDecode(resp.body);

        // ajusta la clave según tu JSON, aquí asumo "nombre"
        final String nombre = (data['nombre'] ?? '').toString().trim();

        if (nombre.isNotEmpty) {
          _cache[uid] = nombre;
          return nombre;
        }
      }

      // Si algo sale raro, devolvemos un fallback
      return 'Usuario';
    } catch (_) {
      return 'Usuario';
    }
  }
}
