import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:vinculed_app_1/src/core/providers/user_provider.dart';

import 'package:vinculed_app_1/src/ui/web_app/candidato/inicio.dart';
import 'package:vinculed_app_1/src/ui/web_app/reclutador/inicio.dart';
import 'package:vinculed_app_1/src/ui/web_app/inicio_admin.dart';

class InicioPage extends StatefulWidget {
  const InicioPage({super.key});

  @override
  State<InicioPage> createState() => _InicioPageState();
}

class _InicioPageState extends State<InicioPage> {
  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    // Usamos 'read' en initState porque no queremos escuchar cambios,
    // solo queremos disparar la función.
    final userDataProvider = context.read<UserDataProvider>();
    
    // Solo carga los datos si el rol aún no está en el provider
    if (userDataProvider.rol == null) { 
      final user = FirebaseAuth.instance.currentUser!;
        await userDataProvider.updateToken(user);
        await userDataProvider.getIdUsuario(user); 
    }
  }

  @override
  Widget build(BuildContext context) {
    // Usamos 'watch' para que este widget se reconstruya
    // cuando el rol finalmente esté disponible.
    final String? rol = context.watch<UserDataProvider>().rol;

    if (rol == null) {
      // Muestra un spinner mientras la API responde
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (rol == 'alumno') {
      return const HomeRegisteredPage(); 
    } else if (rol == 'reclutador') {
      return const HomeRecruiterPage();
    }else if(rol == 'admin'){
      return const InicioAdminPage();
    }
    return const Scaffold(
      body: Center(child: Text("Error: Rol de usuario desconocido.")),
    );
  }
}