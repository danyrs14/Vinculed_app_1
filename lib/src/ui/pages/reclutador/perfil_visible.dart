import 'package:flutter/material.dart';
import 'package:vinculed_app_1/src/core/controllers/theme_controller.dart';
import 'package:vinculed_app_1/src/ui/pages/reclutador/estado_vacante.dart';
import 'package:vinculed_app_1/src/ui/widgets/buttons/simple_buttons.dart';
import 'package:vinculed_app_1/src/ui/widgets/textos/textos.dart';

class PerfilPostuladoPage extends StatelessWidget {
  const PerfilPostuladoPage({
    super.key,
    this.nombre = 'Fernando Torres Juarez',
    this.rol = 'Becario de QA',
    this.cvFileName = 'CV_User.pdf',
    this.correo = 'eminemrs14@gmail.com',
    this.carrera = 'Ingenieria en Sistemas Co mputacionales',
    this.biografia =
    'Busco oportunidades laborales, en el campo de la ingenieria, colaborando con mis conocimientos a las empresas.',
    this.habTecnicas = 'Python, Java, Kotlin, Linux',
    this.habBlandas = 'Comunicacion, Trabajo en equipo',
    this.area = 'TI, Frontend, UI/UX',
    this.idiomas = 'Ingles C1, Español Nativo',
    this.onCumplePerfil,
    this.onDescartar,
  });

  final String nombre;
  final String rol;
  final String cvFileName;
  final String correo;
  final String carrera;
  final String biografia;
  final String habTecnicas;
  final String habBlandas;
  final String area;
  final String idiomas;

  /// Callbacks para los botones de acción
  final VoidCallback? onCumplePerfil;
  final VoidCallback? onDescartar;

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;

    return Scaffold(
      backgroundColor: theme.background(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _HeaderPerfilPostulado(title: 'Perfil del Postulado'),
              const SizedBox(height: 12),
              // Avatar + Nombre + Rol
              const CircleAvatar(
                radius: 48,
                backgroundImage: AssetImage('assets/images/amlo.jpg'),
              ),
              const SizedBox(height: 12),
              Texto(
                text: nombre,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
              const SizedBox(height: 4),
              Texto(text: rol, fontSize: 14),

              const SizedBox(height: 16),
              _CvBox(fileName: cvFileName),

              const SizedBox(height: 18),
              _ProfileSection(
                label: 'Correo Electronico:',
                value: correo,
                actionIcon: Icons.edit, // en la imagen hay iconos de acción
                onAction: () {},
              ),
              _ProfileSection(
                label: 'Carrera:',
                value: carrera,
                actionIcon: Icons.edit,
                onAction: () {},
              ),
              _ProfileSection(
                label: 'Biografia:',
                value: biografia,
                actionIcon: Icons.edit,
                onAction: () {},
              ),
              _ProfileSection(
                label: 'Habilidades Tecnicas:',
                value: habTecnicas,
                actionIcon: Icons.edit,
                onAction: () {},
              ),
              _ProfileSection(
                label: 'Habilidades Blandas:',
                value: habBlandas,
                actionIcon: Icons.edit,
                onAction: () {},
              ),
              _ProfileSection(
                label: 'Area de Especialidad:',
                value: area,
                actionIcon: Icons.edit,
                onAction: () {},
              ),
              _ProfileSection(
                label: 'Idiomas:',
                value: idiomas,
                actionIcon: Icons.edit,
                onAction: () {},
              ),

              const SizedBox(height: 12),

              // Botones de acción
              Row(
                children: [
                  Expanded(
                    child: SimpleButton(
                      title: 'Cumple',
                      onTap: onCumplePerfil ??
                              () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Marcado como que cumple el perfil'),
                                backgroundColor: theme.primario(),
                              ),
                            );
                          },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: SimpleButton(
                      title: 'Descartar',
                      onTap: onDescartar ??
                              () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Postulado descartado'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

/// ---------- Encabezado con mismo estilo base (título centrado) ----------
class _HeaderPerfilPostulado extends StatelessWidget {
  const _HeaderPerfilPostulado({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
                color: Colors.black87,
                onPressed: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => VacanteDetallePage()),
                ),
              ),
            ],
          ),
          Texto(text: title, fontSize: 22, fontWeight: FontWeight.w700),
        ],
      ),
    );
  }
}

/// ---------- Caja de CV (idéntica al patrón previo) ----------
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
        borderRadius: BorderRadius.circular(6),
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

/// ---------- Sección de perfil (reutiliza el mismo diseño del código previo) ----------
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

/// ---------- Botón primario reutilizable ----------
class _PrimaryActionButton extends StatelessWidget {
  const _PrimaryActionButton({
    required this.title,
    required this.color,
    required this.onTap,
  });

  final String title;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: 0,
        ),
        onPressed: onTap,
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 15.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
