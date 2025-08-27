import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:vinculed_app_1/src/ui/widgets/buttons/simple_buttons.dart';

class NotFoundPage extends StatelessWidget {
  const NotFoundPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Tu animación Lottie
            SizedBox(
              height: 500,
              width: 500,
              child: Lottie.asset(
                'assets/images/error404.json', // Asegúrate de ponerlo en pubspec.yaml
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              "Página no encontrada",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            SimpleButton(
              onTap: () => context.go('/dashboard'),
              title: 'Volver al Inicio',
            ),
          ],
        ),
      ),
    );
  }
}
