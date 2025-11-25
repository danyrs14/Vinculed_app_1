import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:vinculed_app_1/src/core/controllers/theme_controller.dart';
import 'package:vinculed_app_1/src/ui/pages/reclutador/editar_vacante.dart';
import 'package:vinculed_app_1/src/ui/widgets/buttons/simple_buttons.dart';
import 'package:vinculed_app_1/src/ui/widgets/textos/textos.dart';

// Header & Footer como en pantallas anteriores
import 'package:vinculed_app_1/src/ui/widgets/elements/header3.dart';
import 'package:vinculed_app_1/src/ui/widgets/elements/footer.dart';

class PerfilPostuladoPage extends StatefulWidget {
  const PerfilPostuladoPage({
    super.key,
    this.nombre = 'Fernando Torres Juarez',
    this.rol = 'Becario de QA',
    this.cvFileName = 'CV_User.pdf',
    this.correo = 'eminemrs14@gmail.com', // NO editable (sin ícono)
    this.carrera = 'Ingenieria en Sistemas Computacionales',
    this.biografia =
    'Busco oportunidades laborales, en el campo de la ingenieria, colaborando con mis conocimientos a las empresas.',
    this.habTecnicas = 'Python, Java, Kotlin, Linux',
    this.habBlandas = 'Comunicacion, Trabajo en equipo',
    this.area = 'TI, Frontend, UI/UX',
    this.idiomas = 'Ingles C1, Español Nativo',
    // NUEVOS CAMPOS:
    this.fechaNacimiento = '12/03/2002',
    this.escolaridad = 'Licenciatura (en curso)',
    this.ciudad = 'CDMX',
    this.semestreActual = '7°',
    this.telefono = '+52 55 1234 5678',
    this.urlsExternas = const [
      'https://linkedin.com/in/fernando-torres',
      'https://github.com/fernandotj'
    ],
    this.cursos = const [
      'Curso de Testing QA - Platzi (2024)',
      'Flutter Intermedio - Udemy (2025)'
    ],
    this.onCumplePerfil,
    this.onDescartar,
  });

  final String nombre;
  final String rol;
  final String cvFileName;
  final String correo; // NO editable
  final String carrera;
  final String biografia;
  final String habTecnicas;
  final String habBlandas;
  final String area;
  final String idiomas;

  // Nuevos campos
  final String fechaNacimiento;
  final String escolaridad;
  final String ciudad;
  final String semestreActual;
  final String telefono;
  final List<String> urlsExternas;
  final List<String> cursos;

  /// Callbacks para los botones de acción
  final VoidCallback? onCumplePerfil;
  final VoidCallback? onDescartar;

  @override
  State<PerfilPostuladoPage> createState() => _PerfilPostuladoPageState();
}

class _PerfilPostuladoPageState extends State<PerfilPostuladoPage> {
  final _scrollCtrl = ScrollController();
  bool _showFooter = false;

  static const double _footerReservedSpace = EscomFooter.height;
  static const double _extraBottomPadding = 24.0;
  static const double _atEndThreshold = 4.0;

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_handleScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _handleScroll());
  }

  void _handleScroll() {
    if (!_scrollCtrl.hasClients) return;
    final pos = _scrollCtrl.position;
    if (!pos.hasPixels || !pos.hasContentDimensions) return;

    if (pos.maxScrollExtent <= 0) {
      if (_showFooter) setState(() => _showFooter = false);
      return;
    }

    final atBottom = pos.pixels >= (pos.maxScrollExtent - _atEndThreshold);
    if (atBottom != _showFooter) setState(() => _showFooter = atBottom);
  }

  @override
  void dispose() {
    _scrollCtrl
      ..removeListener(_handleScroll)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;
    final w = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: theme.background(),
      appBar: EscomHeader3(
        onLoginTap: () => context.go('/reclutador/perfil_rec'),
        onNotifTap: () {},
        onMenuSelected: (label) {
          switch (label) {
            case "Inicio":
              context.go('/inicio');
              break;
            case "Crear Vacante":
              context.go('/reclutador/new_vacancy');
              break;
            case "Mis Vacantes":
              context.go('/reclutador/postulaciones');
              break;
            case "FAQ":
              context.go('/reclutador/faq_rec');
              break;
            case "Mensajes":
              context.go('/reclutador/msg_rec');
              break;
          }
        },
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final minBodyHeight =
                    constraints.maxHeight - _footerReservedSpace - _extraBottomPadding;

                return NotificationListener<ScrollNotification>(
                  onNotification: (n) {
                    if (n is ScrollUpdateNotification ||
                        n is UserScrollNotification ||
                        n is ScrollEndNotification) {
                      _handleScroll();
                    }
                    return false;
                  },
                  child: SingleChildScrollView(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10)
                        .copyWith(bottom: _footerReservedSpace + _extraBottomPadding),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1100),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: minBodyHeight > 0 ? minBodyHeight : 0,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const SizedBox(height: 4),
                              const _HeaderPerfilPostulado(title: 'Perfil del Postulado'),
                              const SizedBox(height: 12),

                              // Avatar + Nombre + Rol
                              const CircleAvatar(
                                radius: 48,
                                backgroundImage: AssetImage('assets/images/amlo.jpg'),
                              ),
                              const SizedBox(height: 12),
                              Texto(
                                text: widget.nombre,
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                              const SizedBox(height: 4),
                              Texto(text: widget.rol, fontSize: 14),

                              const SizedBox(height: 16),
                              _CvBox(fileName: widget.cvFileName),

                              const SizedBox(height: 18),

                              // ======= INFO PRINCIPAL (sin íconos de editar) =======
                              _ProfileSection(
                                label: 'Correo Electronico:',
                                value: widget.correo,
                              ),
                              _ProfileSection(
                                label: 'Carrera:',
                                value: widget.carrera,
                              ),
                              _ProfileSection(
                                label: 'Fecha de nacimiento:',
                                value: widget.fechaNacimiento,
                              ),
                              _ProfileSection(
                                label: 'Escolaridad:',
                                value: widget.escolaridad,
                              ),
                              _ProfileSection(
                                label: 'Ciudad:',
                                value: widget.ciudad,
                              ),
                              _ProfileSection(
                                label: 'Semestre actual:',
                                value: widget.semestreActual,
                              ),
                              _ProfileSection(
                                label: 'Teléfono:',
                                value: widget.telefono,
                              ),

                              // ======= TEXTO LARGO =======
                              _ProfileSection(
                                label: 'Biografia:',
                                value: widget.biografia,
                              ),
                              _ProfileSection(
                                label: 'Habilidades Tecnicas:',
                                value: widget.habTecnicas,
                              ),
                              _ProfileSection(
                                label: 'Habilidades Blandas:',
                                value: widget.habBlandas,
                              ),
                              _ProfileSection(
                                label: 'Area de Especialidad:',
                                value: widget.area,
                              ),
                              _ProfileSection(
                                label: 'Idiomas:',
                                value: widget.idiomas,
                              ),

                              // ======= LISTAS (URLS y CURSOS) =======
                              _ProfileSection(
                                label: 'URLs externas:',
                                value: _joinBullets(widget.urlsExternas),
                              ),
                              _ProfileSection(
                                label: 'Cursos:',
                                value: _joinBullets(widget.cursos),
                              ),

                              const SizedBox(height: 12),

                              // Botones de acción
                              Row(
                                children: [
                                  Expanded(
                                    child: SimpleButton(
                                      title: 'Cumple',
                                      onTap: widget.onCumplePerfil ??
                                              () {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                content: const Text(
                                                  'Marcado como que cumple el perfil',
                                                ),
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
                                      onTap: widget.onDescartar ??
                                              () {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
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

                              const SizedBox(height: 28),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Footer animado como en las otras pantallas
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: AnimatedSlide(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              offset: _showFooter ? Offset.zero : const Offset(0, 1),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 220),
                opacity: _showFooter ? 1 : 0,
                child: EscomFooter(isMobile: w < 700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper para listas en formato viñetas simples
  static String _joinBullets(List<String> items) {
    if (items.isEmpty) return '—';
    return items.map((e) => '• $e').join('\n');
  }
}

/// ---------- Encabezado interno (botón atrás + título) ----------
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
                  MaterialPageRoute(builder: (context) => EditarVacantePage()),
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

/// ---------- Caja de CV ----------
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

/// ---------- Sección de perfil (misma estética, sin iconos) ----------
class _ProfileSection extends StatelessWidget {
  const _ProfileSection({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título (sin ícono a la derecha)
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
            ],
          ),
          // Valor
          Text(
            value.isEmpty ? '—' : value,
            style: const TextStyle(fontSize: 14, height: 1.35),
          ),
        ],
      ),
    );
  }
}

/// ---------- Botón primario reutilizable (sin cambios) ----------
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
