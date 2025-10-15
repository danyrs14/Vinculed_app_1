import 'package:flutter/material.dart';
import 'package:vinculed_app_1/src/core/controllers/theme_controller.dart';
import 'package:vinculed_app_1/src/ui/widgets/textos/textos.dart';

class PerfilRec extends StatelessWidget {
  const PerfilRec({super.key});

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
              // Encabezado (conserva tu estilo actual)
              const _Header(),
              const SizedBox(height: 16),

              // Usuario + rol (según imagen)
              const Texto(text: '@Reclutador_Registrado', fontSize: 18, fontWeight: FontWeight.w700),
              const SizedBox(height: 4),
              const Texto(text: 'Reclutador', fontSize: 14),
              const SizedBox(height: 16),

              // Secciones con la información de la imagen
              _ProfileSection(
                label: 'Correo Electronico:',
                value: 'eminemrs14@gmail.com',
                actionIcon: Icons.edit,
                onAction: () {},
              ),
              _ProfileSection(
                label: 'Empresa:',
                value: 'BBVA Mexico',
                actionIcon: Icons.edit,
                onAction: () {},
              ),
              _ProfileSection(
                label: 'Direccion de la Empresa :',
                value:
                'Av. Miguel Othón de Mendizábal Ote. 343-\n'
                    'Locales 2-5, Industrial Vallejo, Gustavo A.\n'
                    'Madero, 07700 Ciudad de México, CDMX',
                actionIcon: Icons.edit,
                onAction: () {},
              ),
              _ProfileSection(
                label: 'Numero de Telefono:',
                value: '+52 55478963210',
                actionIcon: Icons.add_circle_outline,
                onAction: () {},
              ),
              _ProfileSection(
                label: 'Puesto en la Empresa',
                value: 'Jefe de Recursos Humanos',
                actionIcon: Icons.add_circle_outline,
                onAction: () {},
              ),
              _ProfileSection(
                label: 'Area de Especialidad:',
                value: 'TI, Frontend, UI/UX',
                actionIcon: Icons.add_circle_outline,
                onAction: () {},
              ),
              _ProfileSection(
                label: 'Idiomas:',
                value: 'Ingles C1, Español Nativo',
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
    final theme = ThemeController.instance;

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
        const Texto(text: 'Perfil', fontSize: 22, fontWeight: FontWeight.w700),
        const SizedBox(height: 12),
        const CircleAvatar(
          radius: 42,
          backgroundImage: AssetImage('assets/images/amlo.jpg'), // reemplaza por tu asset/foto
          // Si usas red: backgroundImage: NetworkImage('https://...'),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

// Lo dejo por si después lo vuelves a mostrar
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
            onPressed: () {},
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
                    fontWeight: FontWeight.w700,
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
