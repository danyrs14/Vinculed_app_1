import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class UserDataProvider extends ChangeNotifier {
  String? _nombreUsuario;
  int? _idUsuario; 
  String? _rol;
  int? _idRol;

  // Cache de habilidades disponibles para evitar múltiples consultas
  List<Map<String, dynamic>>? _habilidadesDisponibles;
  bool _habilidadesCargadas = false;

  String? get nombreUsuario => _nombreUsuario;
  int? get idUsuario => _idUsuario;
  String? get rol => _rol;
  int? get idRol => _idRol;
  List<Map<String, dynamic>>? get habilidadesDisponibles => _habilidadesDisponibles;
  bool get habilidadesCargadas => _habilidadesCargadas;

  Future<Map<String, String>> getAuthHeaders() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('No hay usuario logueado para hacer la petición.');
    }
  
    final token = await user.getIdToken(); 
    
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  Future<void> updateToken(User user) async {
    _nombreUsuario = user.displayName;
    // Notifica a cualquier widget que esté "escuchando" que los datos cambiaron
    notifyListeners(); 
  }

  Future<void> getIdUsuario(User user) async{
    try{
      final headers = await getAuthHeaders();

      final response = await http.get(
        Uri.parse('http://localhost:3000/api/usuarios/uid/${user.uid}'), //movil
        //Uri.parse('https://oda-talent-back-81413836179.us-central1.run.app/api/usuarios/uid/${user.uid}'), //web
        headers: headers,
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

  // Precargar habilidades disponibles una sola vez
  Future<void> preloadHabilidades() async {
    if (_habilidadesCargadas) return;
    try {
      final headers = await getAuthHeaders();

      final resp = await http.get(
        Uri.parse('https://oda-talent-back-81413836179.us-central1.run.app/api/habilidades/disponibles'),
        headers: headers,
      );
      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        final data = jsonDecode(resp.body) as List;
        _habilidadesDisponibles = data.cast<Map<String, dynamic>>();
        _habilidadesCargadas = true;
        notifyListeners();
      } else {
        print('Error ${resp.statusCode} al precargar habilidades');
      }
    } catch (e) {
      print('Excepción al precargar habilidades: $e');
    }
  }

  // 6. Método para limpiar los datos al cerrar sesión
  void clearData() {
    _nombreUsuario = null;
    _idUsuario = null;
    _rol = null;
    _idRol = null;
    _habilidadesDisponibles = null;
    _habilidadesCargadas = false;
    notifyListeners();
  }
}