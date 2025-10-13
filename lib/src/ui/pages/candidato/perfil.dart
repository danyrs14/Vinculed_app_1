import 'package:flutter/material.dart';
import 'package:vinculed_app_1/src/core/controllers/theme_controller.dart';
import 'package:vinculed_app_1/src/ui/widgets/textos/textos.dart';

class Perfil extends StatelessWidget {
  const Perfil({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;

    return Scaffold(
      backgroundColor: theme.background(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Column(
            children: [
              // Encabezado SIN fondo azul y SIN "visualizaciones"
              const _Header(),
              const SizedBox(height: 16),

              // Usuario + rol
              const Texto(text: '@Usuario_Registrado', fontSize: 18),
              const SizedBox(height: 4),
              const Texto(text: 'Alumno', fontSize: 14),
              const SizedBox(height: 16),

              // CV box
              const _CvBox(fileName: 'CV_User.pdf'),
              const SizedBox(height: 18),

              // Secciones (texto con título y valor, y acción al lado)
              _ProfileSection(
                label: 'Correo Electrónico:',
                value: 'eminemrs14@gmail.com',
                actionIcon: Icons.edit,
                onAction: () {},
              ),
              _ProfileSection(
                label: 'Carrera:',
                value: 'Ingeniería en Sistemas Computacionales',
                actionIcon: Icons.edit,
                onAction: () {},
              ),
              _ProfileSection(
                label: 'Biografía:',
                value:
                'Busco oportunidades laborales, en el campo de la ingeniería, '
                    'colaborando con mis conocimientos a las empresas.',
                actionIcon: Icons.edit,
                onAction: () {},
              ),
              _ProfileSection(
                label: 'Habilidades Técnicas:',
                value: 'Python, Java, Kotlin, Linux',
                actionIcon: Icons.add_circle_outline,
                onAction: () {},
              ),
              _ProfileSection(
                label: 'Habilidades Blandas:',
                value: 'Comunicación, Trabajo en equipo',
                actionIcon: Icons.add_circle_outline,
                onAction: () {},
              ),
              _ProfileSection(
                label: 'Área de Especialidad:',
                value: 'TI, Frontend, UI/UX',
                actionIcon: Icons.add_circle_outline,
                onAction: () {},
              ),
              _ProfileSection(
                label: 'Idiomas:',
                value: 'Inglés C1, Español Nativo',
                actionIcon: Icons.add_circle_outline,
                onAction: () {},
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

/// ---------- Widgets auxiliares ----------

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    // Encabezado limpio: engrane arriba a la derecha, título centrado y avatar
    return Column(
      children: [
        // Fila con botón de ajustes alineado a la derecha
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {},
              tooltip: 'Ajustes',
            ),
          ],
        ),
        const Texto(text: 'Perfil', fontSize: 22),
        const SizedBox(height: 12),
        const CircleAvatar(
          radius: 42,
          backgroundImage: AssetImage('assets/images/amlo.jpg'), // reemplaza por tu asset
        ),
      ],
    );
  }
}

class _CvBox extends StatelessWidget {
  const _CvBox({required this.fileName});
  final String fileName;

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: theme.background(),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black87, width: 1.1),
      ),
      child: Row(
        children: [
          const Icon(Icons.attachment),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              fileName,
              style: const TextStyle(fontSize: 14),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            onPressed: () {
              // abrir/seleccionar CV
            },
            icon: const Icon(Icons.more_vert),
          ),
        ],
      ),
    );
  }
}

class _ProfileSection extends StatelessWidget {
  const _ProfileSection({
    required this.label,
    required this.value,
    required this.actionIcon,
    this.onAction,
  });

  final String label;
  final String value;
  final IconData actionIcon;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título + acción a la derecha
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                onPressed: onAction,
                icon: Icon(actionIcon, size: 20, color: theme.primario()),
                tooltip: label,
              ),
            ],
          ),
          // Valor
          Text(
            value,
            style: const TextStyle(fontSize: 14, height: 1.35),
          ),
        ],
      ),
    );
  }
}
