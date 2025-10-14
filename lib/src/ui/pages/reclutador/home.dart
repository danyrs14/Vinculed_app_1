import 'package:flutter/material.dart';
import 'package:vinculed_app_1/src/core/controllers/theme_controller.dart';
import 'package:vinculed_app_1/src/ui/widgets/textos/textos.dart';
import 'package:vinculed_app_1/src/ui/widgets/elements_app/candidate_card.dart'; // <-- nuevo import

class HomeRec extends StatelessWidget {
  const HomeRec({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;

    // Datos provisionales (reemplaza por Firestore/API si lo deseas).
    const candidates = <CandidateData>[
      CandidateData(
        name: 'Fernando Torres Juarez',
        role: 'Becario de QA',
        studentInfo: 'ESCOM, IPN 8° Semestre',
        skills: 'Backend, UI/UX, Python',
        photoUrl:
        'https://images.unsplash.com/photo-1573497161161-c3e73707e25c?q=80&w=1200&auto=format&fit=crop',
      ),
      CandidateData(
        name: 'Edgar Gomez Martinez',
        role: 'Sin Puesto aun',
        studentInfo: 'ESCOM, IPN 5° Semestre',
        skills: 'Bases de Datos, Java',
        photoUrl:
        'https://images.unsplash.com/photo-1504593811423-6dd665756598?q=80&w=1200&auto=format&fit=crop',
      ),
    ];

    return Scaffold(
      backgroundColor: theme.background(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),

              // Saludo + avatar
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(width: 4),
                  const CircleAvatar(
                    radius: 26,
                    backgroundImage: AssetImage('assets/images/amlo.jpg'),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Texto(text: '@Usuario_Registrado', fontSize: 16),
                      SizedBox(height: 2),
                      Texto(text: 'Bienvenido de Nuevo', fontSize: 20),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Tarjetas de candidatos (desde el widget externo)
              for (final c in candidates) ...[
                CandidateCard(data: c),
                const SizedBox(height: 18),
              ],

              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
