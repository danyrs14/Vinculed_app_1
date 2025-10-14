import 'package:flutter/material.dart';
import 'package:vinculed_app_1/src/core/controllers/theme_controller.dart';
import 'package:vinculed_app_1/src/ui/widgets/textos/textos.dart';

/// ===== Modelo de datos =====
class CandidateData {
  final String name;
  final String role;
  final String studentInfo;
  final String skills;
  final String photoUrl;

  const CandidateData({
    required this.name,
    required this.role,
    required this.studentInfo,
    required this.skills,
    required this.photoUrl,
  });
}

/// ===== Tarjeta de candidato (estilo del mock) =====
class CandidateCard extends StatelessWidget {
  const CandidateCard({super.key, required this.data});

  final CandidateData data;

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;

    return Container(
      decoration: BoxDecoration(
        color: theme.background(),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Acento vertical azul
          Container(
            width: 3,
            height: 255,
            decoration: BoxDecoration(
              color: theme.primario(),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                bottomLeft: Radius.circular(14),
              ),
            ),
          ),

          // Contenido
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Foto grande
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: AspectRatio(
                      aspectRatio: 4 / 3,
                      child: Image.network(
                        data.photoUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          alignment: Alignment.center,
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.person, size: 48),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Nombre
                  Texto(
                    text: data.name,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),

                  // Rol
                  Texto(
                    text: data.role,
                    fontSize: 14,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),

                  // Estudiante
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Texto(
                        text: 'Estudiante: ',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                      Expanded(
                        child: Texto(
                          text: data.studentInfo,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Habilidades
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Texto(
                        text: 'Habilidades: ',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                      Expanded(
                        child: Texto(
                          text: data.skills,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
