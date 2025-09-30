import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:vinculed_app_1/src/core/controllers/theme_controller.dart';
import 'package:vinculed_app_1/src/ui/widgets/elements/footer.dart';
import 'package:vinculed_app_1/src/ui/widgets/elements/header3.dart';

class UserProfile extends StatefulWidget {
  const UserProfile({super.key});

  @override
  State<UserProfile> createState() => _UserProfileState();
}

class _UserProfileState extends State<UserProfile> {
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
    final isMobile = w < 900;

    return Scaffold(
      backgroundColor: theme.background(),
      appBar: EscomHeader3(
        onLoginTap: () => context.go('/perfil_rec'),
        onRegisterTap: () => context.go('/signin'),
        onNotifTap: () {},
        onMenuSelected: (label) {
          switch (label) {
            case "Inicio":
              context.go('/inicio_rec');
              break;
            case "Crear Vacante":
              context.go('/new_vacancy');
              break;
            case "Mis Vacantes":
              context.go('/my_vacancy');
              break;
            case "Postulaciones":
              context.go('/postulaciones');
              break;
            case "FAQ":
              context.go('/faq_rec');
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
                    padding: const EdgeInsets.only(
                      bottom: _footerReservedSpace + _extraBottomPadding,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1100),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: minBodyHeight > 0 ? minBodyHeight : 0,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // ───────── Banner + Avatar ─────────
                                const _Banner(),

                                const SizedBox(height: 18),

                                // ───────── Nombre y Rol ─────────
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 24),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: const [
                                      Text(
                                        'Jorge Hernandez Ortega',
                                        style: TextStyle(
                                          fontSize: 26,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF1F2A36),
                                        ),
                                      ),
                                      SizedBox(height: 6),
                                      Text(
                                        'Reclutador',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 22),

                                // ───────── Datos en dos columnas ─────────
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 24),
                                  child: isMobile
                                      ? Column(
                                    children: [
                                      _InfoColumn(items: _leftItems()),
                                      const SizedBox(height: 24),
                                      _InfoColumn(items: _rightItems()),
                                    ],
                                  )
                                      : Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(child: _InfoColumn(items: _leftItems())),
                                      const SizedBox(width: 24),
                                      Expanded(child: _InfoColumn(items: _rightItems())),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 28),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // ───────── Footer animado ─────────
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

  // ───────── Contenido (datos fijos como en la imagen) ─────────

  List<_InfoItem> _leftItems() => const [
    _InfoItem(
      label: 'Correo Electronico:',
      value: 'eminemsrl4@gmail.com',
      icon: Icons.edit_outlined,
      circle: true,
    ),
    _InfoItem(
      label: 'Carrera:',
      value: 'BBVA México',
      icon: Icons.edit_outlined,
      circle: true,
    ),
    _InfoItem(
      label: 'Numero de Telefono',
      value: '+52 5578962166',
      icon: Icons.circle_outlined,
      circle: true,
    ),
    _InfoItem(
      label: 'Puesto en la Empresa',
      value: 'Analista de Personal',
      icon: Icons.circle_outlined,
      circle: true,
    ),
  ];

  List<_InfoItem> _rightItems() => const [
    _InfoItem(
      label: 'Direccion de la empresa',
      value:
      'Av. Miguel Othón de Mendizábal Ote. 343-\nLocales 2-5, Industrial Vallejo, Gustavo A.\nMadero, 07700 Ciudad de México, CDMX',
      icon: Icons.edit_outlined,
      circle: true,
      multiLine: true,
    ),
    _InfoItem(
      label: 'Area de Especialidad',
      value: 'Recursos Humanos',
      icon: Icons.add, // ícono con círculo como en la imagen
      circle: true,
    ),
    _InfoItem(
      label: 'Idiomas:',
      value: 'Ingles C1, Español Nativo',
      icon: Icons.add,
      circle: true,
    ),
  ];
}

/* ════════════════════════ Secciones / Widgets internos ═══════════════════════ */

class _Banner extends StatelessWidget {
  const _Banner();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Banner
        AspectRatio(
          aspectRatio: 16 / 4.5,
          child: Image.asset(
            'assets/images/portada.jpg',
            fit: BoxFit.cover,
          ),
        ),
        // Avatar alineado a la izquierda, pegado al borde inferior
        Positioned(
          left: 24,
          bottom: 18,
          child: CircleAvatar(
            radius: 58,
            backgroundColor: Colors.white,
            child: const CircleAvatar(
              radius: 54,
              backgroundImage: AssetImage('assets/images/reclutador.png'),
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoColumn extends StatelessWidget {
  const _InfoColumn({required this.items});

  final List<_InfoItem> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final it in items) ...[
          _InfoRow(item: it),
          const SizedBox(height: 16),
        ],
      ],
    );
  }
}

class _InfoItem {
  final String label;
  final String value;
  final IconData icon;
  final bool multiLine;
  final bool circle;

  const _InfoItem({
    required this.label,
    required this.value,
    required this.icon,
    this.multiLine = false,
    this.circle = false,
  });
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.item});
  final _InfoItem item;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: item.multiLine ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        // Etiqueta
        SizedBox(
          width: 210,
          child: Text(
            item.label,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        // Valor
        Expanded(
          child: Text(
            item.value,
            style: const TextStyle(color: Colors.black87, height: 1.4),
          ),
        ),
        // Acción (icono en círculo)
        const SizedBox(width: 10),
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: item.circle ? Border.all(color: Colors.black54, width: 1.2) : null,
          ),
          alignment: Alignment.center,
          child: Icon(item.icon, size: 14, color: Colors.black87),
        ),
      ],
    );
  }
}
