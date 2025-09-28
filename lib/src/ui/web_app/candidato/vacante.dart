import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:vinculed_app_1/src/ui/widgets/elements/header.dart';
import 'package:vinculed_app_1/src/ui/widgets/elements/footer.dart';
import 'package:vinculed_app_1/src/ui/widgets/elements/header2.dart';
import 'package:vinculed_app_1/src/ui/widgets/text_inputs/text_input.dart';
import 'package:vinculed_app_1/src/ui/widgets/buttons/simple_buttons.dart';

class JobDetailPage extends StatefulWidget {
  const JobDetailPage({super.key});

  @override
  State<JobDetailPage> createState() => _JobDetailPageState();
}

class _JobDetailPageState extends State<JobDetailPage> {
  // Inputs de la barra de búsqueda superior
  final _qCtrl = TextEditingController();
  final _modeCtrl = TextEditingController();

  final _scrollCtrl = ScrollController();
  bool _showFooter = false;

  // ====== Mismo esquema que JobSearchPage ======
  static const double _footerReservedSpace = EscomFooter.height;
  static const double _extraBottomPadding = 24.0;
  static const double _atEndThreshold = 4.0;

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_handleScroll);
    // Asegura estado correcto tras el primer layout
    WidgetsBinding.instance.addPostFrameCallback((_) => _handleScroll());
  }

  void _handleScroll() {
    final pos = _scrollCtrl.position;
    if (!pos.hasPixels || !pos.hasContentDimensions) return;

    // Si el contenido cabe en pantalla, ocultamos footer (como en JobSearchPage)
    if (pos.maxScrollExtent <= 0) {
      if (_showFooter) setState(() => _showFooter = false);
      return;
    }

    // Mostrar footer únicamente al final del contenido
    final atBottom = pos.pixels >= (pos.maxScrollExtent - _atEndThreshold);
    if (atBottom != _showFooter) {
      setState(() => _showFooter = atBottom);
    }
  }

  @override
  void dispose() {
    _scrollCtrl
      ..removeListener(_handleScroll)
      ..dispose();
    _qCtrl.dispose();
    _modeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 700;

    return Scaffold(
      appBar: EscomHeader2(
        onLoginTap: () => context.go('/perfil_cand'),
        onRegisterTap: () => context.go('/signin'),
        onNotifTap: () {},
        onMenuSelected: (label) {
          switch (label) {
            case "Inicio":
              context.go('/inicio_cand');
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
          // ====== Scroll a pantalla completa con reserva de espacio para footer ======
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
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: minBodyHeight > 0 ? minBodyHeight : 0,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // ───────── Fila de búsqueda superior ─────────
                                LayoutBuilder(
                                  builder: (context, c) {
                                    final wrap = c.maxWidth < 920;
                                    if (wrap) {
                                      return Column(
                                        children: [
                                          TextInput(title: 'Puesto', controller: _qCtrl),
                                          const SizedBox(height: 12),
                                          TextInput(title: 'Ciudad', controller: _modeCtrl),
                                          const SizedBox(height: 12),
                                          Align(
                                            alignment: Alignment.centerRight,
                                            child: SizedBox(
                                              width: 220,
                                              child: SimpleButton(
                                                title: 'Buscar Empleo',
                                                onTap: _onSearch,
                                              ),
                                            ),
                                          ),
                                        ],
                                      );
                                    }
                                    return Row(
                                      children: [
                                        Expanded(
                                          flex: 4,
                                          child: Padding(
                                            padding: const EdgeInsets.only(right: 16),
                                            child: TextInput(title: 'Puesto', controller: _qCtrl),
                                          ),
                                        ),
                                        Expanded(
                                          flex: 3,
                                          child: Padding(
                                            padding: const EdgeInsets.only(right: 16),
                                            child: TextInput(
                                              title: 'Ciudad',
                                              controller: _modeCtrl,
                                            ),
                                          ),
                                        ),
                                        SizedBox(
                                          width: 240,
                                          child: SimpleButton(
                                            title: 'Buscar Empleo',
                                            onTap: _onSearch,
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),

                                const SizedBox(height: 28),

                                // ───────── Encabezado del puesto ─────────
                                const Text(
                                  'Becario de TI',
                                  style: TextStyle(
                                    fontSize: 30,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF1F2A36),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  '\$7500 Mensuales',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Banorte IXE S.A de C.V',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black87,
                                  ),
                                ),

                                const SizedBox(height: 16),

                                // Dirección
                                const _AddressLine('Av. Miguel Othón de Mendizábal Ote. 343-Locales'),
                                const _AddressLine('2-5, Industrial Vallejo, Gustavo A. Madero, 07700'),
                                const _AddressLine('Ciudad de México, CDMX'),

                                const SizedBox(height: 18),

                                // CTA Postularme
                                SizedBox(
                                  width: 220,
                                  child: SimpleButton(
                                    title: 'Postularme',
                                    onTap: _onApply,
                                  ),
                                ),

                                const SizedBox(height: 24),

                                // ───────── Sección REQUISITOS ─────────
                                const _SectionTitle('REQUISITOS'),
                                const SizedBox(height: 14),
                                const _Bullet('Informática, Ing Sistemas, o Afín'),
                                const SizedBox(height: 6),
                                const _Bullet('Universitarios sin Título'),

                                const SizedBox(height: 28),

                                // ───────── Sección DESCRIPCION ─────────
                                const _SectionTitle('DESCRIPCION'),
                                const SizedBox(height: 14),
                                const Text(
                                  'El puesto de Becario de TI está dirigido a estudiantes que desean adquirir experiencia '
                                      'práctica en el área de Tecnologías de la Información dentro de una empresa de tecnología '
                                      'o en el departamento de TI de una organización. El becario trabajará bajo la supervisión de '
                                      'profesionales experimentados en el campo, participando en proyectos tecnológicos y '
                                      'colaborando en tareas de soporte y mantenimiento de sistemas, redes, y aplicaciones de la empresa.',
                                  textAlign: TextAlign.justify,
                                  style: TextStyle(height: 1.5),
                                ),

                                const SizedBox(height: 40),
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

          // ====== Footer animado como en JobSearchPage ======
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
                child: EscomFooter(isMobile: isMobile),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Acciones
  void _onSearch() {
    // context.go('/busqueda_job'); // si ya tienes esa ruta
  }

  void _onApply() {
    // Lógica para postularse
  }
}

/* ───────────────────────── Widgets pequeños ───────────────────────── */

class _AddressLine extends StatelessWidget {
  const _AddressLine(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(color: Colors.black54),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18.0),
          child: Text(
            title,
            style: const TextStyle(
              letterSpacing: 1,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.circle, size: 6),
        const SizedBox(width: 8),
        Expanded(child: Text(text)),
      ],
    );
  }
}
