import 'package:flutter/material.dart';
import 'package:vinculed_app_1/src/ui/pages/modulo_candidato/menu.dart';
import 'package:vinculed_app_1/src/ui/widgets/buttons/simple_buttons.dart';

class RoleSelectionPage extends StatelessWidget {
  const RoleSelectionPage({
    super.key,
    this.onAlumnoTap,
    this.onReclutaTap,
  });

  /// Opcional: acciones personalizadas
  final VoidCallback? onAlumnoTap;
  final VoidCallback? onReclutaTap;


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Fondo sencillo; cámbialo por tu Theme si lo deseas
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF6F7FB), Color(0xFFE9ECF5)],
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 28,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: SimpleButton(
                        onTap: (){
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MenuPage(),
                            ),
                          );
                        },
                        title: "Alumno",
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Botón Recluta
                    SizedBox(
                      width: double.infinity,
                      child: SimpleButton(
                        onTap: (){},
                        title: 'Recluta',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _defaultRoute(BuildContext context, String route) {
    // Intenta navegar; si la ruta no existe, muestra un SnackBar
    Navigator.of(context).pushNamed(route).catchError((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ruta no encontrada: $route')),
      );
    });
  }
}
