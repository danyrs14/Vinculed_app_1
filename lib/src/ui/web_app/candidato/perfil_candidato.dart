import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:vinculed_app_1/src/core/controllers/theme_controller.dart';
import 'package:vinculed_app_1/src/ui/widgets/elements/header.dart';
import 'package:vinculed_app_1/src/ui/widgets/elements/footer.dart';
import 'package:vinculed_app_1/src/ui/widgets/elements/header2.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({super.key});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  final _scrollCtrl = ScrollController();
  bool _showFooter = false;
  final usuario = FirebaseAuth.instance.currentUser!;

  static const double _footerReservedSpace = EscomFooter.height;
  static const double _extraBottomPadding = 24.0;
  static const double _atEndThreshold = 4.0;

  // Simulación de un archivo de CV “seleccionado”
  String _cvName = 'CV_User.pdf';

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_handleScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _handleScroll());
  }

  void _handleScroll() {
    final pos = _scrollCtrl.position;
    if (!pos.hasPixels || !pos.hasContentDimensions) return;

    // si el contenido cabe en pantalla, ocultar footer
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
      appBar: EscomHeader2(
        onLoginTap: () => context.go('/perfil_cand'),
        onNotifTap: () {},
        onMenuSelected: (label) {
          switch (label) {
            case "Inicio":
              context.go('/inicio');
              break;

            case "Postulaciones":
              context.go('/mis_postulaciones');
              break;

            case "Mensajes":
              context.go('/messages');
              break;

            case "Experiencias":
              context.go('/experiencias');
              break;

            case "FAQ":
              context.go('/faq');
              break;

            case "Preferencias":
              context.go('/preferences');
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
                                // ───────────────── Banner + Avatar + CV ─────────────────
                                _BannerSection(
                                  isMobile: isMobile,
                                  cvName: _cvName,
                                  onPickCv: () {
                                    // aquí abrirías tu picker; por ahora simulamos cambio
                                    setState(() => _cvName = 'CV_Actualizado.pdf');
                                  },
                                ),

                                const SizedBox(height: 18),

                                // ───────────────── Nombre y Rol ─────────────────
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 24),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${usuario.displayName}',
                                        style: const TextStyle(
                                          fontSize: 26,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF1F2A36),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      const Text(
                                        'Alumno',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 22),

                                // ───────────────── Datos en dos columnas ─────────────────
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 24),
                                  child: isMobile
                                      ? Column(
                                    children: [
                                      _InfoColumn(
                                        items: _leftItems(),
                                        crossAxisStart: true,
                                      ),
                                      const SizedBox(height: 24),
                                      _InfoColumn(
                                        items: _rightItems(theme),
                                        crossAxisStart: true,
                                      ),
                                    ],
                                  )
                                      : Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: _InfoColumn(items: _leftItems()),
                                      ),
                                      const SizedBox(width: 24),
                                      Expanded(
                                        child: _InfoColumn(items: _rightItems(theme)),
                                      ),
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

          // ───────────────── Footer animado ─────────────────
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

  // ---------------- helpers de contenido ----------------

  List<_InfoItem> _leftItems() => const [
    _InfoItem(
      label: 'Correo Electronico:',
      value: 'eminemsrl4@gmail.com',
      editable: false,
      icon: Icons.edit_outlined,
    ),
    _InfoItem(
      label: 'Carrera:',
      value: 'Ingeniería en Sistemas Computacionales',
      editable: true,
      icon: Icons.edit_outlined,
    ),
    _InfoItem(
      label: 'Habilidades Tecnicas:',
      value: 'Python, Java, Kotlin, Linux',
      editable: true,
      icon: Icons.edit_outlined,
    ),
    _InfoItem(
      label: 'Area de Especialidad:',
      value: 'TI, Frontend, UI/UX',
      editable: true,
      icon: Icons.edit_outlined,
    ),
  ];

  List<_InfoItem> _rightItems(ThemeController theme) => [
    const _InfoItem(
      label: 'Biografía:',
      value:
      'Busco oportunidades laborales, en el\ncampo de la ingeniería, colaborando con\nmis conocimientos a las empresas.',
      editable: true,
      icon: Icons.edit_outlined,
      multiLine: true,
    ),
    _InfoItem(
      label: 'Habilidades Blandas:',
      value: 'Comunicación, Trabajo en equipo',
      editable: true,
      icon: Icons.add_circle_outline,
      actionColor: theme.secundario(),
    ),
    _InfoItem(
      label: 'Idiomas:',
      value: 'Inglés C1, Español Nativo',
      editable: true,
      icon: Icons.add_circle_outline,
      actionColor: theme.secundario(),
    ),
  ];
}

/* ════════════════════════ Secciones ─═══════════════════════ */

class _BannerSection extends StatelessWidget {
  const _BannerSection({
    required this.isMobile,
    required this.cvName,
    required this.onPickCv,
  });

  final bool isMobile;
  final String cvName;
  final VoidCallback onPickCv;

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;

    return Stack(
      children: [
        // Banner
        AspectRatio(
          aspectRatio: 16 / 4.5,
          child: ClipRRect(
            child: Image.asset(
              'assets/images/portada.jpg', // pon tu imagen en assets
              fit: BoxFit.cover,
            ),
          ),
        ),

        // Avatar + input CV
        Positioned.fill(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Avatar
                  Container(
                    margin: const EdgeInsets.only(bottom: 18),
                    child: const CircleAvatar(
                      radius: 58,
                      backgroundImage: AssetImage('assets/images/amlo.jpg'),
                    ),
                  ),
                  const Spacer(),

                  // Input CV (lado derecho)
                  if (!isMobile)
                    Container(
                      margin: const EdgeInsets.only(bottom: 18),
                      width: 360,
                      height: 44,
                      decoration: BoxDecoration(
                        color: theme.background(),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFBFD7E2), width: 1.4),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: onPickCv,
                        child: Row(
                          children: [
                            const SizedBox(width: 12),
                            const Icon(Icons.attach_file, size: 18, color: Colors.black54),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                cvName,
                                style: const TextStyle(color: Colors.black87),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoColumn extends StatelessWidget {
  const _InfoColumn({
    required this.items,
    this.crossAxisStart = false,
  });

  final List<_InfoItem> items;
  final bool crossAxisStart;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
      crossAxisStart ? CrossAxisAlignment.start : CrossAxisAlignment.stretch,
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
  final bool editable;
  final bool multiLine;
  final IconData icon;
  final Color? actionColor;

  const _InfoItem({
    required this.label,
    required this.value,
    required this.editable,
    required this.icon,
    this.multiLine = false,
    this.actionColor,
  });
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.item});
  final _InfoItem item;

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;

    return Row(
      crossAxisAlignment: item.multiLine ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        // Etiqueta
        SizedBox(
          width: 190,
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
        // Acción
        const SizedBox(width: 8),
        Icon(
          item.icon,
          size: 18,
          color: item.actionColor ?? Colors.black54,
        ),
      ],
    );
  }
}
