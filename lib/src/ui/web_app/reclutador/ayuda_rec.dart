import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:vinculed_app_1/src/core/controllers/theme_controller.dart';
import 'package:vinculed_app_1/src/ui/widgets/elements/header.dart';
import 'package:vinculed_app_1/src/ui/widgets/elements/footer.dart';
import 'package:vinculed_app_1/src/ui/widgets/elements/faq_item.dart';
import 'package:vinculed_app_1/src/ui/widgets/elements/header2.dart';
import 'package:vinculed_app_1/src/ui/widgets/elements/header3.dart';

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
      appBar: EscomHeader3(
        onLoginTap: () => context.go('/reclutador/perfil_rec'),
        onNotifTap: () {},
        onMenuSelected: (label) {
          switch (label) {
            case "Inicio":
              context.go('/inicio_rec');
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
                                  children: [
                                    FaqItem(
                                      question: '¿Cómo elijo el rol de trabajo de una vacante?',
                                      answer: 'Usa "Selecciona el rol o roles" para asociar la vacante a uno o varios roles. Esto ayuda a que candidatos adecuados la encuentren.',
                                    ),
                                    SizedBox(height: 16),
                                    FaqItem(
                                      question: '¿Cómo agrego habilidades a la vacante?',
                                      answer: 'En "Requisitos específicos" elige habilidades técnicas. En "Habilidades blandas" agrega habilidades blandas e idiomas. Puedes combinar ambas.',
                                    ),
                                    SizedBox(height: 16),
                                    FaqItem(
                                      question: '¿Qué formato uso para el monto de beca?',
                                      answer: 'Ingresa un número válido (ej. 1500.00). Se valida automáticamente; evita símbolos y texto.',
                                    ),
                                    SizedBox(height: 16),
                                    FaqItem(
                                      question: '¿Cómo capturo la dirección de la vacante?',
                                      answer: 'Completa calle y número, municipio/ciudad y entidad. El código postal es opcional, pero recomendado.',
                                    ),
                                    SizedBox(height: 16),
                                    FaqItem(
                                      question: '¿Para qué sirven las fechas de la vacante?',
                                      answer: 'Inicio/fin describen el periodo de la vacante. "Fecha límite" define hasta cuándo se reciben postulaciones.',
                                    ),
                                    SizedBox(height: 16),
                                    FaqItem(
                                      question: '¿Qué extensión debe tener la descripción?',
                                      answer: 'Hasta 4000 caracteres. Sé claro con responsabilidades, requisitos y beneficios.',
                                    ),
                                    SizedBox(height: 16),
                                    FaqItem(
                                      question: '¿Cómo ver el detalle de una vacante publicada?',
                                      answer: 'En "Mis Vacantes" toca el boton "Ver detalle" de una vacante de la lista para ver toda su información y las personas que se han postulado.',
                                    ),
                                    SizedBox(height: 16),
                                    FaqItem(
                                      question: '¿Cómo editar una vacante?',
                                      answer: 'Dentro del detalle pulsa "Editar", realiza los cambios y guarda. Volverás a la vista anterior y la información se mostrará actualizada automáticamente.',
                                    ),
                                    SizedBox(height: 16),
                                    FaqItem(
                                      question: '¿Cómo eliminar una vacante?',
                                      answer: 'Ve los detalles de la vacante y elige la opción de eliminar. Confirma en el cuadro de diálogo y la vacante desaparecerá del listado. Esta acción no se puede deshacer.',
                                    ),
                                    SizedBox(height: 16),
                                    FaqItem(
                                      question: '¿Cómo cambiar el estado (Activa / Expirada)?',
                                      answer: 'En el detalle de la vacante usa el botón para cambiar estado. Puedes alternar entre Activa y Expirada según corresponda, para permitir o impedir nuevas postulaciones.',
                                    ),
                                    SizedBox(height: 16),
                                    FaqItem(
                                      question: '¿Dónde veo los alumnos que se postularon a una vacante?',
                                      answer: 'Al abrir el detalle de la vacante verás la sección de postulaciones en la parte inferior. Si aún no hay, aparecerá un mensaje indicándolo. Puedes revisar los perfiles de los alumnos que se postularon, contactarlos por los mensajes de la plataforma y reclutarlos o rechazarlos para una vacante específica, según tu criterio.',
                                    ),
                                    SizedBox(height: 16),
                                    FaqItem(
                                      question: '¿Para qué sirve el botón "Marcar como Completado"?',
                                      answer: 'Usa este botón para indicar que el alumno ya cumplió con las actividades de la vacante en el periodo acordado. Esto ayuda a mantener tu lista de alumnos reclutados organizada.',
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
