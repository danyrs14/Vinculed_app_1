import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:vinculed_app_1/src/core/controllers/theme_controller.dart';

import 'package:vinculed_app_1/src/ui/widgets/elements/header.dart';
import 'package:vinculed_app_1/src/ui/widgets/elements/footer.dart';
import 'package:vinculed_app_1/src/ui/widgets/elements/header2.dart';
import 'package:vinculed_app_1/src/ui/widgets/text_inputs/text_input.dart';
import 'package:vinculed_app_1/src/ui/widgets/buttons/simple_buttons.dart';

class JobSearchPage extends StatefulWidget {
  const JobSearchPage({super.key});

  @override
  State<JobSearchPage> createState() => _JobSearchPageState();
}

class _JobSearchPageState extends State<JobSearchPage> {
  final _queryCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();

  final _scrollCtrl = ScrollController();
  bool _showFooter = false;

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

    // si el contenido cabe en pantalla, no muestres footer
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
    _queryCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;
    final w = MediaQuery.of(context).size.width;
    final isMobile = w < 700;

    return Scaffold(
      backgroundColor: theme.background(),
      appBar: EscomHeader2(
        onLoginTap: () => context.go('/alumno/perfil_cand'),
        onNotifTap: () {},
        onMenuSelected: (label) {
          switch (label) {
            case "Inicio":
              context.go('/inicio');
              break;

            case "Postulaciones":
              context.go('/alumno/mis_postulaciones');
              break;

            case "Mensajes":
              context.go('/alumno/messages');
              break;

            case "Experiencias":
              context.go('/alumno/experiencias');
              break;

            case "FAQ":
              context.go('/alumno/faq');
              break;

            case "Preferencias":
              context.go('/alumno/preferences');
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
                        constraints: const BoxConstraints(maxWidth: 900),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: minBodyHeight > 0 ? minBodyHeight : 0,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // Avatar + Título
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const CircleAvatar(
                                      radius: 22,
                                      backgroundImage: AssetImage('assets/images/amlo.jpg'),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Buscar Vacantes',
                                      style: TextStyle(
                                        fontSize: isMobile ? 26 : 32,
                                        fontWeight: FontWeight.w800,
                                        color: const Color(0xFF22313F),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 28),

                                // Formulario centrado
                                ConstrainedBox(
                                  constraints: const BoxConstraints(maxWidth: 620),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      TextInput(
                                        title: 'Buscar',
                                        controller: _queryCtrl,
                                        keyboardType: TextInputType.text,
                                      ),
                                      const SizedBox(height: 12),
                                      TextInput(
                                        title: 'Ingresa una Ubicacion',
                                        controller: _locationCtrl,
                                        keyboardType: TextInputType.streetAddress,
                                      ),
                                      const SizedBox(height: 18),
                                      Align(
                                        alignment: Alignment.center,
                                        child: SizedBox(
                                          width: 320,
                                          child: SimpleButton(
                                            title: 'Buscar Empleo',
                                            onTap: () => context.go('/vacante_job'),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
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

          // Footer animado: aparece al llegar al final del contenido
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

  void _onSearch() {
    // aquí puedes llamar a tu backend o navegar a resultados
    // print('Buscar: ${_queryCtrl.text} en ${_locationCtrl.text}');
  }
}
