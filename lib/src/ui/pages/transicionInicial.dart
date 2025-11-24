import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:vinculed_app_1/src/core/providers/user_provider.dart';
import 'package:vinculed_app_1/src/ui/pages/candidato/menu.dart';
import 'package:vinculed_app_1/src/ui/pages/login.dart';
import 'package:vinculed_app_1/src/ui/pages/reclutador/menu.dart';
import 'package:vinculed_app_1/src/ui/pages/verificarEmail.dart';
import 'package:vinculed_app_1/src/ui/pages/splashscreen.dart';


class TrasicionPage extends StatefulWidget {
  @override
  _TrasicionPageState createState() => _TrasicionPageState();
} 
class _TrasicionPageState extends State<TrasicionPage> {
  String? _lastLoadedUid;
  bool _kickoffInProgress = false;

  void _kickoffLoad(User user) {
    if (_kickoffInProgress || _lastLoadedUid == user.uid) return;
    _kickoffInProgress = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final prov = context.read<UserDataProvider>();
      prov.updateToken(user);
      if (prov.rol == null) {
        await prov.getIdUsuario(user);
      }
      if (!mounted) return;
      setState(() {
        _lastLoadedUid = user.uid;
        _kickoffInProgress = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FirebaseAuth.instance.userChanges(), 
      builder: (context, snapshot){
            if (snapshot.hasError) {
              return const Text('Algo salió mal');
            }
            if (snapshot.connectionState == ConnectionState.waiting){
              return SplashScreen();
            }
            if (!snapshot.hasData){
              return LoginPage();
            } 
            final user = snapshot.data!;
            if(!user.emailVerified){
              return verificarEmailPage();
            }

            // Disparar carga de provider una sola vez por uid
            _kickoffLoad(user);

            final prov = context.watch<UserDataProvider>();
            if(prov.rol == null){
              // Aún cargando rol/id: mostrar SplashScreen como loader
              return SplashScreen();
            }
            if(prov.rol == 'alumno'){
              return const MenuPage();
            } else if(prov.rol == 'reclutador'){
              return const MenuPageRec();
            }else if(prov.rol == 'admin'){
              return const MenuPage();
            }
            return const Scaffold(
              body: Center(child: Text("Error: Rol de usuario desconocido.")),
            );
          }
      );
  }
}