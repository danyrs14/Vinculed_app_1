import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class UserDataProvider extends ChangeNotifier {

  String? _idToken;
  String? _nombreUsuario;
  int? _idUsuario; 
  String? _rol;
  int? _idRol;

  String? get idToken => _idToken;
  String? get nombreUsuario => _nombreUsuario;
  int? get idUsuario => _idUsuario;
  String? get rol => _rol;
  int? get idRol => _idRol;

  Future<void> updateToken(User user) async {
    _idToken = await user.getIdToken(true);
    _nombreUsuario = user.displayName;
    // Notifica a cualquier widget que esté "escuchando" que los datos cambiaron
    notifyListeners(); 
  }

  Future<void> getIdUsuario(User user) async{
    try{
      final response = await http.get(
        //Uri.parse('http://10.0.2.2:3000/api/usuarios/${user.uid}'), //movil
        Uri.parse('https://oda-talent-back-81413836179.us-central1.run.app/api/usuarios/uid/${user.uid}'), //web
        headers: {
          'Authorization': 'Bearer $_idToken',
        },
      );
      final responseDecoded = jsonDecode(response.body);
      _idUsuario = responseDecoded['id'];
      _rol = responseDecoded['rol'];
      _idRol = responseDecoded['id_rol'];
      notifyListeners();
    }catch(e){
      print('Error al obtener el id_usuario: $e');
    }
  }


  // 6. Método para limpiar los datos al cerrar sesión
  void clearData() {
    _idToken = null;
    _nombreUsuario = null;
    _idUsuario = null;
    _rol = null;
    _idRol = null;
    notifyListeners();
  }
}