import 'package:flutter/material.dart';
import 'package:vinculed_app_1/src/core/controllers/theme_controller.dart';
import 'package:vinculed_app_1/src/ui/widgets/buttons/simple_buttons.dart';
import 'package:vinculed_app_1/src/ui/widgets/textos/textos.dart';

class Perfil extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;
    return Scaffold(
      backgroundColor: theme.background(),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0), // Espaciado de todo el contenido
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start, // Alineación hacia el inicio
              children: [
                Texto(
                  text: 'Perfil',
                  fontSize: 24,
                ),
                //contenido futuro
              ],
            ),
          ),
        ),
      ),
    );
  }
}
