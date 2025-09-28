import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:vinculed_app_1/src/core/controllers/theme_controller.dart';
import 'package:vinculed_app_1/src/ui/widgets/elements/header.dart';
import 'package:vinculed_app_1/src/ui/widgets/elements/footer.dart';
import 'package:vinculed_app_1/src/ui/widgets/elements/faq_item.dart';
import 'package:vinculed_app_1/src/ui/widgets/elements/header2.dart';

class FaqPage extends StatefulWidget {
  const FaqPage({super.key});

  @override
  State<FaqPage> createState() => _FaqPageState();
}

class _FaqPageState extends State<FaqPage> {
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

    // Si no hay scroll suficiente, oculta el footer
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
    final isMobile = MediaQuery.of(context).size.width < 720;

    return Scaffold(
      backgroundColor: theme.background(),
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
          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final minBodyHeight =
                    constraints.maxHeight - _footerReservedSpace - _extraBottomPadding;

                return SingleChildScrollView(
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
                              // Título principal
                              Text(
                                'Ayuda',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: isMobile ? 28 : 34,
                                  fontWeight: FontWeight.w900,
                                  color: const Color(0xFF22313F),
                                ),
                              ),
                              const SizedBox(height: 10),

                              // Descripción
                              ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 680),
                                child: const Text(
                                  'En esta sección encontrarás respuestas de las preguntas '
                                      'más destacadas sobre cómo usar la aplicación.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(height: 1.5),
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Lista de preguntas (FAQ)
                              ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 560),
                                child: const Column(
                                  children: const [
                                    FaqItem(
                                      question: '¿Cómo postularme?',
                                      answer:
                                      'Entra a "Mis Vacantes" o usa la búsqueda, abre la vacante y presiona "Postularme". '
                                          'Sigue los pasos para enviar tu solicitud.',
                                      initiallyExpanded: false,
                                    ),
                                    SizedBox(height: 16),
                                    FaqItem(
                                      question: '¿Cómo edito mi perfil?',
                                      answer:
                                      'Accede a la sección "Mi Perfil" para actualizar tu información personal, académica y profesional. '
                                          'No olvides guardar los cambios.',
                                      initiallyExpanded: true,
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
                );
              },
            ),
          ),

          // Footer animado
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
}
