import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class UserDataProvider extends ChangeNotifier {

  String? _idToken;
  String? _nombreUsuario;
  String? _idUsuario; 
  String? _rol;

  String? get idToken => _idToken;
  String? get nombreUsuario => _nombreUsuario;
  String? get idUsuario => _idUsuario;
  String? get rol => _rol;

  Future<void> updateToken(User user) async {
    _idToken = await user.getIdToken();
    _nombreUsuario = user.displayName;
    // Notifica a cualquier widget que esté "escuchando" que los datos cambiaron
    notifyListeners(); 
  }

  Future<void> getIdUsuario(User user) async{
    try{
      final response = await http.get(
        //Uri.parse('http://10.0.2.2:3000/api/usuarios/${user.uid}'), //movil
        Uri.parse('http://localhost:3000/api/usuarios/uid/${user.uid}'), //web
        headers: {
          'Authorization': 'Bearer $_idToken',
        },
      );
      final responseDecoded = jsonDecode(response.body);
      _idUsuario = responseDecoded['id'].toString();
      _rol = responseDecoded['rol'];
      notifyListeners();
    }catch(e){
      print('Error al obtener el id_usuario: $e');
    }
  }


  // 6. Método para limpiar los datos al cerrar sesión
  void clearData() {
    _idToken = null;
    _idUsuario = null;
    _rol = null;
    notifyListeners();
  }
}