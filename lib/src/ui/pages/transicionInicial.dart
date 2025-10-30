import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:vinculed_app_1/src/core/controllers/theme_controller.dart';
import 'package:vinculed_app_1/src/ui/pages/login.dart';
import 'package:vinculed_app_1/src/ui/pages/verificarEmail.dart';
import 'package:vinculed_app_1/src/ui/pages/modulo_candidato/menu.dart';


class TrasicionPage extends StatefulWidget {
  @override
  _TrasicionPageState createState() => _TrasicionPageState();
} 
class _TrasicionPageState extends State<TrasicionPage> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FirebaseAuth.instance.userChanges(), 
      builder: (context, snapshot){
            if (snapshot.hasError) {
              return const Text('Algo salió mal');
            }
            // if(snapshot.connectionState == ConnectionState.waiting){
            //   return _splashScreenContainer(theme);
            // }
            if (!snapshot.hasData){
              return LoginPage();
            } 
            final user = snapshot.data!;
            if(!user.emailVerified){
              return verificarEmailPage();
            }
            return MenuPage();
          }
      );
  }
}