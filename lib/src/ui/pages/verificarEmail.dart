import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:vinculed_app_1/src/ui/pages/modulo_candidato/menu.dart';


class verificarEmailPage extends StatefulWidget {
  const verificarEmailPage({super.key});

  @override
  State<verificarEmailPage> createState() => _verificarEmailPageState();
}

class _verificarEmailPageState extends State<verificarEmailPage> {

  @override
  void initState() {
    super.initState();
    _revisarVerificacionEmail();
  }

  Future<void> _revisarVerificacionEmail() async {
    User? user = FirebaseAuth.instance.currentUser;
    try{
      await user?.reload();
      if (user != null && user.emailVerified) {
        return;
      } else if (mounted) { //Verifica cada 5 segundos
        Future.delayed(const Duration(seconds: 5), () {
          _revisarVerificacionEmail();
        });
      }
    } catch (e) {
      _mostrarMensaje("Error al verificar el correo: ${e.toString()}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.blue,
            title: const Text("Verificar correo electrónico"),
            centerTitle: true,
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Se ha enviado un correo de verificación a su dirección de correo electrónico. Por favor, revise su bandeja de entrada y haga clic en el enlace de verificación.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () async {
                    try{
                      User? user = FirebaseAuth.instance.currentUser;
                      await user?.sendEmailVerification();
                      _mostrarMensaje("Correo de verificación reenviado.");
                    } catch (e) {
                      _mostrarMensaje("Error al reenviar el correo: ${e.toString()}");
                    }
                  },
                  child: const Text("Reenviar correo de verificación"),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () async {
                    try{
                      await FirebaseAuth.instance.signOut();
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    } catch (e) {
                      _mostrarMensaje("Error al cerrar sesión: ${e.toString()}");
                    }
                  },
                  child: const Text("Cerrar sesión"),
                ),
              ],
            ),
          ),
        );
  }
  

  void _mostrarMensaje(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje)),
    );
  }
}