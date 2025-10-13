import 'package:flutter/material.dart';
import 'package:vinculed_app_1/src/core/controllers/theme_controller.dart';
import 'package:vinculed_app_1/src/ui/widgets/elements_app/job_card.dart';
import 'package:vinculed_app_1/src/ui/widgets/textos/textos.dart';

class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;

    // Datos provisionales (puedes sustituirlos por Firestore / API).
    const jobs = <JobData>[
      JobData(title: 'Becario de QA', city: 'Ciudad de México', company: 'BBVA México'),
      JobData(title: 'Becario Scrum', city: 'Ciudad de México', company: 'IDS'),
      JobData(title: 'Becario de TI', city: 'Ciudad de México', company: 'Banorte IXE'),
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
                children: const [
                  SizedBox(width: 4),
                  CircleAvatar(
                    radius: 26,
                    backgroundImage: AssetImage('assets/images/amlo.jpg'),
                  ),
                  SizedBox(width: 10),
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

              // Lista de vacantes
              for (final job in jobs) ...[
                JobCard(
                  data: job,
                  // Puedes inyectar tus callbacks aquí:
                  // onApply: () => context.push('/postular/${job.id}'),
                  // onFavoriteTap: () => ...,
                  // onHide: () => ...,
                ),
                const SizedBox(height: 14),
              ],
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
