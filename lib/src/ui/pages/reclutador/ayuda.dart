import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:vinculed_app_1/src/core/controllers/theme_controller.dart';

// TUS COMPONENTES
import 'package:vinculed_app_1/src/ui/widgets/elements/header3.dart' show EscomHeader3;
import 'package:vinculed_app_1/src/ui/widgets/elements/footer.dart' show EscomFooter;
import 'package:vinculed_app_1/src/ui/widgets/elements/faq_item.dart' show FaqItem;

// ===============================
// 1) PANTALLA CON TUS COMPONENTES
// ===============================
class FaqPageRec extends StatefulWidget {
  const FaqPageRec({super.key});

  @override
  State<FaqPageRec> createState() => _FaqPageRecState();
}

class _FaqPageRecState extends State<FaqPageRec> {
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
    final isMobile = MediaQuery.of(context).size.width < 720;

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
            case "Mensajes":
              context.go('/msg_rec');
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
                            minHeight: minBodyHeight.clamp(0, double.infinity).toDouble(),
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
                                constraints: BoxConstraints(maxWidth: 680),
                                child: Text(
                                  'En esta sección encontrarás respuestas de las preguntas '
                                      'más destacadas sobre cómo usar la aplicación.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(height: 1.5),
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Lista de preguntas (FAQ) usando tu FaqItem
                              ConstrainedBox(
                                constraints: BoxConstraints(maxWidth: 560),
                                child: Column(
                                  children: [
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

          // Footer animado (tu componente)
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

// ===================================
// 2) TU VERSION SIMPLE, CORREGIDA
//    (POR SI LA QUIERES SEGUIR USANDO)
// ===================================
class AyudaRec extends StatefulWidget {
  const AyudaRec({super.key});

  @override
  State<AyudaRec> createState() => _AyudaRecState();
}

class _AyudaRecState extends State<AyudaRec> {
  bool _open1 = false; // ¿Cómo elegir?
  bool _open2 = true;  // ¿Cómo edito mi perfil?

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;

    return Scaffold(
      backgroundColor: theme.background(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  SizedBox(width: 4),
                  Expanded(
                    child: Center(
                      child: Text(
                        'Ayuda',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  SizedBox(width: 48),
                ],
              ),
              const SizedBox(height: 14),

              const Text(
                'En esta seccion encontraras respuestas de\n'
                    'las preguntas mas destacadas sobre como\n'
                    'usar la aplicacion.',
                style: TextStyle(fontSize: 14, height: 1.5),
              ),
              const SizedBox(height: 16),

              _FaqCard(
                title: '¿Como elegir?',
                isOpen: _open1,
                onToggle: () => setState(() => _open1 = !_open1),
                child: const Text(
                  'Revisa la descripcion de cada vacante, compara '
                      'requisitos y postulate a las que mejor se ajusten a tu perfil.',
                  style: TextStyle(fontSize: 13.5, height: 1.45),
                ),
              ),
              const SizedBox(height: 12),
              _FaqCard(
                title: '¿Como edito mi perfil?',
                isOpen: _open2,
                onToggle: () => setState(() => _open2 = !_open2),
                child: const Text(
                  'Accede a la sección de \'Configuración de cuenta\' para '
                      'actualizar tu información personal y profesional.',
                  style: TextStyle(fontSize: 13.5, height: 1.45),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _FaqCard extends StatelessWidget {
  const _FaqCard({
    required this.title,
    required this.isOpen,
    required this.onToggle,
    required this.child,
  });

  final String title;
  final bool isOpen;
  final VoidCallback onToggle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.background(),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black87, width: 1),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: theme.primario(),
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Material(
                  color: theme.primario(),
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: onToggle,
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Icon(
                        isOpen
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
              ],
            ),
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 180),
            firstCurve: Curves.easeOut,
            secondCurve: Curves.easeIn,
            crossFadeState:
            isOpen ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}
