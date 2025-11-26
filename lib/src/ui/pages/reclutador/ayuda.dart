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
        //onRegisterTap: () => context.go('/signin'),
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
                                child: const Column(
                                  children: [
                                    FaqItem(
                                      question: '¿Cómo ver el detalle de una vacante publicada?',
                                      answer: 'En "Mis Vacantes" toca la vacante de la lista para ver toda su información y las personas que se han postulado.',
                                      initiallyExpanded: true,
                                    ),
                                    SizedBox(height: 16),
                                    FaqItem(
                                      question: '¿Cómo editar una vacante y refrescar los datos?',
                                      answer: 'Dentro del detalle pulsa "Editar", realiza los cambios y guarda. Volverás a la vista anterior y la información se mostrará actualizada automáticamente.',
                                      initiallyExpanded: false,
                                    ),
                                    SizedBox(height: 16),
                                    FaqItem(
                                      question: '¿Por qué veo "No hay vacantes publicadas"?',
                                      answer: 'Todavía no has creado vacantes. Para publicar la primera, usa el botón con el símbolo "+" en la barra superior.',
                                      initiallyExpanded: false,
                                    ),
                                    SizedBox(height: 16),
                                    FaqItem(
                                      question: '¿Cómo eliminar una vacante?',
                                      answer: 'Abre la vacante y elige la opción de eliminar. Confirma en el cuadro de diálogo y la vacante desaparecerá del listado. Esta acción no se puede deshacer.',
                                      initiallyExpanded: false,
                                    ),
                                    SizedBox(height: 16),
                                    FaqItem(
                                      question: '¿Cómo cambiar el estado (Activa / Expirada)?',
                                      answer: 'En el detalle de la vacante usa el botón para cambiar estado. Puedes alternar entre Activa y Expirada según corresponda, para permitir o impedir nuevas postulaciones.',
                                      initiallyExpanded: false,
                                    ),
                                    SizedBox(height: 16),
                                    FaqItem(
                                      question: '¿Dónde veo las postulaciones de una vacante?',
                                      answer: 'Al abrir el detalle de la vacante verás la sección de postulaciones en la parte inferior. Si aún no hay, aparecerá un mensaje indicándolo.',
                                      initiallyExpanded: false,
                                    ),
                                    SizedBox(height: 16),
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
  int? _openIndex; // índice de la tarjeta abierta, null si ninguna

  void _toggleCard(int index) {
    setState(() {
      _openIndex = (_openIndex == index) ? null : index;
    });
  }

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
                title: '¿Cómo ver el detalle de una vacante publicada?',
                isOpen: _openIndex == 0,
                onToggle: () => _toggleCard(0),
                child: const Text(
                  'En "Mis Vacantes" toca el boton "Ver detalle" de una vacante de la lista para ver toda su información y las personas que se han postulado.',
                  style: TextStyle(fontSize: 13.5, height: 1.45),
                ),
              ),
              const SizedBox(height: 12),
              _FaqCard(
                title: '¿Cómo editar una vacante?',
                isOpen: _openIndex == 1,
                onToggle: () => _toggleCard(1),
                child: const Text(
                  'Dentro del detalle pulsa "Editar", realiza los cambios y guarda. Volverás a la vista anterior y la información se mostrará actualizada automáticamente.',
                  style: TextStyle(fontSize: 13.5, height: 1.45),
                ),
              ),
              const SizedBox(height: 12),
              _FaqCard(
                title: '¿Por qué veo "No hay vacantes publicadas"?',
                isOpen: _openIndex == 2,
                onToggle: () => _toggleCard(2),
                child: const Text(
                  'Todavía no has creado vacantes. Para publicar la primera, usa el botón con el símbolo "+" en la barra superior.',
                  style: TextStyle(fontSize: 13.5, height: 1.45),
                ),
              ),
              const SizedBox(height: 12),
              _FaqCard(
                title: '¿Cómo eliminar una vacante?',
                isOpen: _openIndex == 3,
                onToggle: () => _toggleCard(3),
                child: const Text(
                  'Abre la vacante y elige la opción de eliminar. Confirma en el cuadro de diálogo y la vacante desaparecerá del listado. Esta acción no se puede deshacer.',
                  style: TextStyle(fontSize: 13.5, height: 1.45),
                ),
              ),
              const SizedBox(height: 12),
              _FaqCard(
                title: '¿Cómo cambiar el estado (Activa / Expirada)?',
                isOpen: _openIndex == 4,
                onToggle: () => _toggleCard(4),
                child: const Text(
                  'En el detalle de la vacante usa el botón para cambiar estado. Puedes alternar entre Activa y Expirada según corresponda, para permitir o impedir nuevas postulaciones.',
                  style: TextStyle(fontSize: 13.5, height: 1.45),
                ),
              ),
              const SizedBox(height: 12),
              _FaqCard(
                title: '¿Dónde veo los alumnos que se postularon a una vacante?',
                isOpen: _openIndex == 5,
                onToggle: () => _toggleCard(5),
                child: const Text(
                  'Al abrir el detalle de la vacante verás la sección de postulaciones en la parte inferior. Si aún no hay, aparecerá un mensaje indicándolo.',
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
