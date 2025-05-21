import 'package:flutter/material.dart';
import 'package:vinculed_app_1/src/core/controllers/theme_controller.dart';
import 'package:vinculed_app_1/src/ui/widgets/textos/textos.dart';

class Mensajes extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;
    return Scaffold(
      backgroundColor: theme.background(),
      body: Padding(
        padding: const EdgeInsets.all(16.0), // Espaciado alrededor del contenido
        child: Center(
          child: ListView(
            children: [
              Texto(
                text: 'Mensajes',
                fontSize: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
