import 'package:flutter/material.dart';
import 'package:vinculed_app_1/src/core/controllers/theme_controller.dart';
import 'package:vinculed_app_1/src/ui/widgets/textos/textos.dart';

class Experiencias extends StatelessWidget {
  final theme = ThemeController.instance;
  final List<Map<String, String>> ExperienciasItems = [
    {
      'title': 'Fabricacion de Puertas',
      'description': 'Servicio de soldadura e instalacion de puertas',
      'image': 'assets/images/pq3.png',
    },
    {
      'title': 'Rampa Multiusos',
      'description': 'Producto personalizado a gusto del cliente',
      'image': 'assets/images/rampas.png',
    },
    {
      'title': 'Puerta Merik',
      'description': 'Uno de nuestros productos estrella',
      'image': 'assets/images/puerta.jpg',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;

    return Scaffold(
      backgroundColor: theme.background(),
      body: SafeArea(
        child: Center(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0), // Espaciado para el título
                child: Texto(
                  text: 'Experiencias',
                  fontSize: 24,
                ),
              ),
              
            ],
          ),
        ),
      ),
    );
  }
}
