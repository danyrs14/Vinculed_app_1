import 'package:flutter/material.dart';
import 'package:vinculed_app_1/src/core/controllers/theme_controller.dart';
import 'package:vinculed_app_1/src/ui/widgets/elements_app/postulacion_card.dart';
import 'package:vinculed_app_1/src/ui/widgets/textos/textos.dart';

class VacantesRec extends StatelessWidget {
  const VacantesRec({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;

    return Scaffold(
      backgroundColor: theme.background(),
      // Tu AppBar y menú ya existen en otro lado; aquí solo el contenido.
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 8),

              // Título centrado como en la imagen
              const Texto(text: 'Mis Vacantes', fontSize: 22),
              const SizedBox(height: 16),

              // Tarjeta de la postulación (reutilizable, en archivo aparte)
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: // Dentro de tu pantalla con una lista:
                  PostulacionCard.postulado(
                    title: 'Becario de QA',
                    company: 'BBVA Mexico',
                    city: 'Ciudad de Mexico',
                    onUnapply: () {
                      // Quita este elemento de tu lista y haz setState si estás en StatefulWidget.
                      // appliedJobs.removeAt(index);
                      // setState(() {});
                    },
                  ),

                ),
              ),

              // Si agregarás más tarjetas, repite PostulacionCard o usa un ListView.builder.
            ],
          ),
        ),
      ),
    );
  }
}
