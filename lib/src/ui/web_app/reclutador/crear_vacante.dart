import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:vinculed_app_1/src/core/controllers/theme_controller.dart';
import 'package:vinculed_app_1/src/ui/widgets/buttons/simple_buttons.dart';
import 'package:vinculed_app_1/src/ui/widgets/elements/footer.dart';
import 'package:vinculed_app_1/src/ui/widgets/elements/header3.dart';
import 'package:vinculed_app_1/src/ui/widgets/elements/requisitos.dart';
import 'package:vinculed_app_1/src/ui/widgets/text_inputs/text_input.dart';


class CreateVacancyPage extends StatefulWidget {
  const CreateVacancyPage({super.key});

  @override
  State<CreateVacancyPage> createState() => _CreateVacancyPageState();
}

class _CreateVacancyPageState extends State<CreateVacancyPage> {
  final _scrollCtrl = ScrollController();
  bool _showFooter = false;

  static const double _footerReservedSpace = EscomFooter.height;
  static const double _extraBottomPadding = 24.0;
  static const double _atEndThreshold = 4.0;

  // Controllers
  final _nombreCtrl = TextEditingController();
  final _salarioCtrl = TextEditingController();
  final _direccionCtrl = TextEditingController();
  final _descripcionCtrl = TextEditingController();

  // Requisitos (muestra)
  final List<String> _escolaresOpciones = const [
    'Licenciado', 'Titulo', 'Grado', 'Tesis',
    'Prepa', '2 Año', '1 Se', 'Experto', 'Grado',
    '3 Año', '1 Año', 'Tecnico', 'trunco', 'Ultimo S.',
    'licenciatura',
  ];
  final List<String> _especificosOpciones = const [
    'Sistemas', 'Informatica', 'QA', 'Electronica',
  ];

  // Seleccionados (iniciales como en la imagen)
  final List<String> _escolaresSel = ['1. Universitario sin título'];
  final List<String> _especificosSel = ['1. Ingeniero en Sistemas'];

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _onScroll());
  }

  void _onScroll() {
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
      ..removeListener(_onScroll)
      ..dispose();
    _nombreCtrl.dispose();
    _salarioCtrl.dispose();
    _direccionCtrl.dispose();
    _descripcionCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;
    final isMobile = MediaQuery.of(context).size.width < 900;

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
                      _onScroll();
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
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: minBodyHeight > 0 ? minBodyHeight : 0,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Título con avatar
                                Row(
                                  children: [
                                    const CircleAvatar(
                                      radius: 18,
                                      backgroundImage:
                                      AssetImage('assets/images/escom.png'),
                                      backgroundColor: Colors.transparent,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Crear Vacante',
                                      style: TextStyle(
                                        fontSize: isMobile ? 24 : 32,
                                        fontWeight: FontWeight.w800,
                                        color: const Color(0xFF22313F),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),

                                // Formulario
                                TextInput(
                                  controller: _nombreCtrl,
                                  title: 'Nombre de la Vacante',
                                ),
                                const SizedBox(height: 12),
                                TextInput(
                                  controller: _salarioCtrl,
                                  title: 'Salario',
                                  keyboardType: TextInputType.number,
                                ),
                                const SizedBox(height: 12),
                                TextInput(
                                  controller: _direccionCtrl,
                                  title: 'Direccion donde se laborara',
                                ),
                                const SizedBox(height: 16),

                                // Dos columnas de requisitos (USANDO EL NUEVO WIDGET)
                                isMobile
                                    ? Column(
                                  children: [
                                    RequisitosColumn(
                                      titulo: 'REQUISITOS ESCOLARES:',
                                      seleccionados: _escolaresSel,
                                      options: _escolaresOpciones,
                                      onAdd: _addEscolar,
                                      onRemove: _removeEscolar,
                                    ),
                                    const SizedBox(height: 18),
                                    RequisitosColumn(
                                      titulo: 'REQUISITOS ESPECIFICOS:',
                                      seleccionados: _especificosSel,
                                      options: _especificosOpciones,
                                      onAdd: _addEspecifico,
                                      onRemove: _removeEspecifico,
                                    ),
                                  ],
                                )
                                    : Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: RequisitosColumn(
                                        titulo: 'REQUISITOS ESCOLARES:',
                                        seleccionados: _escolaresSel,
                                        options: _escolaresOpciones,
                                        onAdd: _addEscolar,
                                        onRemove: _removeEscolar,
                                      ),
                                    ),
                                    const SizedBox(width: 18),
                                    Expanded(
                                      child: RequisitosColumn(
                                        titulo: 'REQUISITOS ESPECIFICOS:',
                                        seleccionados: _especificosSel,
                                        options: _especificosOpciones,
                                        onAdd: _addEspecifico,
                                        onRemove: _removeEspecifico,
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 18),

                                // Descripción
                                TextInput(
                                  controller: _descripcionCtrl,
                                  title: 'Añade una descripcion',
                                ),
                                const SizedBox(height: 18),

                                // Botón Publicar
                                Align(
                                  alignment: Alignment.center,
                                  child: SizedBox(
                                    width: isMobile ? 240 : 320,
                                    height: 44,
                                    child: SimpleButton(
                                      onTap: _publicar,
                                      title: 'Publicar Vacante',
                                    ),
                                  ),
                                ),
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

  // Handlers seleccionados
  void _addEscolar(String v) {
    if (!_escolaresSel.contains(v)) {
      setState(() => _escolaresSel.add(v));
    }
  }

  void _removeEscolar(String v) {
    setState(() => _escolaresSel.remove(v));
  }

  void _addEspecifico(String v) {
    if (!_especificosSel.contains(v)) {
      setState(() => _especificosSel.add(v));
    }
  }

  void _removeEspecifico(String v) {
    setState(() => _especificosSel.remove(v));
  }

  void _publicar() {
    // Aquí puedes conectar con Firestore/Backend.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Vacante publicada (demo UI).')),
    );
  }
}
