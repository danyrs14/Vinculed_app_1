// lib/src/ui/pages/create_vacancy_page.dart
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

  // ===== Controllers (generales) =====
  final _nombreCtrl = TextEditingController();
  final _salarioCtrl = TextEditingController();
  final _direccionCtrl = TextEditingController();
  final _descripcionCtrl = TextEditingController();

  // Nuevos campos solicitados
  final _beneficiosCtrl = TextEditingController();
  final _fechaInicioCtrl = TextEditingController();
  final _fechaFinCtrl = TextEditingController();
  final _duracionCtrl = TextEditingController();
  final _fechaLimiteCtrl = TextEditingController();
  final _fechaPublicacionCtrl = TextEditingController();
  String? _modalidad; // Presencial, Remoto, Híbrido
  final _observacionesCtrl = TextEditingController();
  final _numeroVacantesCtrl = TextEditingController();

  // ===== Opciones de requisitos =====
  final List<String> _especificosOpciones = const [
    'Sistemas', 'Informática', 'QA', 'Electrónica',
    'Ciberseguridad', 'Desarrollo móvil', 'Backend Node.js',
    'Flutter', 'SQL/MySQL', 'AWS', 'Git/GitHub',
  ];
  final List<String> _especificosSel = ['1. Ingeniero en Sistemas'];

  // ESCOLARES: ahora se agregan desde un TextField libre
  final List<String> _escolaresSel = ['1. Universitario sin título'];
  final _escolarInputCtrl = TextEditingController();

  // HABILIDADES BLANDAS: dropdown con búsqueda
  final List<String> _habilidadesBlandasOpc = const [
    'Comunicación efectiva',
    'Trabajo en equipo',
    'Liderazgo',
    'Adaptabilidad',
    'Gestión del tiempo',
    'Pensamiento crítico',
    'Resolución de problemas',
    'Proactividad',
    'Empatía',
    'Creatividad',
  ];
  final List<String> _habilidadesBlandasSel = [];

  // Modalidad
  final List<String> _modalidades = const ['Presencial', 'Remoto', 'Híbrido'];

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

    _beneficiosCtrl.dispose();
    _fechaInicioCtrl.dispose();
    _fechaFinCtrl.dispose();
    _duracionCtrl.dispose();
    _fechaLimiteCtrl.dispose();
    _fechaPublicacionCtrl.dispose();
    _observacionesCtrl.dispose();
    _numeroVacantesCtrl.dispose();

    _escolarInputCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;
    final isMobile = MediaQuery.of(context).size.width < 900;

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
              context.go('/my_vacancy');
              break;
            case "Postulaciones":
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
                final minBodyHeight = constraints.maxHeight - _footerReservedSpace - _extraBottomPadding;

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
                            constraints: BoxConstraints(minHeight: minBodyHeight > 0 ? minBodyHeight : 0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // ===== Título =====
                                Row(
                                  children: [
                                    const CircleAvatar(
                                      radius: 18,
                                      backgroundImage: AssetImage('assets/images/escom.png'),
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

                                // ===== Formulario: Campos principales =====
                                TextInput(controller: _nombreCtrl, title: 'Nombre de la Vacante'),
                                const SizedBox(height: 12),
                                TextInput(
                                  controller: _salarioCtrl,
                                  title: 'Salario',
                                  keyboardType: TextInputType.number,
                                ),
                                const SizedBox(height: 12),
                                TextInput(controller: _direccionCtrl, title: 'Dirección donde se laborará'),
                                const SizedBox(height: 16),

                                // ===== Bloque de Requisitos (2 columnas) =====
                                isMobile
                                    ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    _RequisitosEscolaresTextOnly(
                                      title: 'REQUISITOS ESCOLARES:',
                                      inputController: _escolarInputCtrl,
                                      selected: _escolaresSel,
                                      onAdd: _addEscolarText,
                                      onRemove: _removeEscolar,
                                    ),
                                    const SizedBox(height: 18),
                                    _RequisitosDropdownColumn(
                                      title: 'REQUISITOS ESPECÍFICOS:',
                                      options: _especificosOpciones,
                                      selected: _especificosSel,
                                      onAdd: _addEspecifico,
                                      onRemove: _removeEspecifico,
                                    ),
                                  ],
                                )
                                    : Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: _RequisitosEscolaresTextOnly(
                                        title: 'REQUISITOS ESCOLARES:',
                                        inputController: _escolarInputCtrl,
                                        selected: _escolaresSel,
                                        onAdd: _addEscolarText,
                                        onRemove: _removeEscolar,
                                      ),
                                    ),
                                    const SizedBox(width: 18),
                                    Expanded(
                                      child: _RequisitosDropdownColumn(
                                        title: 'REQUISITOS ESPECÍFICOS:',
                                        options: _especificosOpciones,
                                        selected: _especificosSel,
                                        onAdd: _addEspecifico,
                                        onRemove: _removeEspecifico,
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 18),

                                // ===== Campos extra solicitados =====
                                TextInput(controller: _beneficiosCtrl, title: 'Beneficios'),
                                const SizedBox(height: 12),

                                // Fechas y duración
                                isMobile
                                    ? Column(
                                  children: [
                                    TextInput(controller: _fechaInicioCtrl, title: 'Fecha inicio (AAAA-MM-DD)'),
                                    const SizedBox(height: 12),
                                    TextInput(controller: _fechaFinCtrl, title: 'Fecha fin (AAAA-MM-DD)'),
                                    const SizedBox(height: 12),
                                    TextInput(controller: _duracionCtrl, title: 'Duración (ej. 6 meses)'),
                                  ],
                                )
                                    : Row(
                                  children: [
                                    Expanded(child: TextInput(controller: _fechaInicioCtrl, title: 'Fecha inicio (AAAA-MM-DD)')),
                                    const SizedBox(width: 12),
                                    Expanded(child: TextInput(controller: _fechaFinCtrl, title: 'Fecha fin (AAAA-MM-DD)')),
                                    const SizedBox(width: 12),
                                    Expanded(child: TextInput(controller: _duracionCtrl, title: 'Duración (ej. 6 meses)')),
                                  ],
                                ),
                                const SizedBox(height: 12),

                                // Modalidad + Fechas de publicación/postulación
                                isMobile
                                    ? Column(
                                  children: [
                                    _ModalidadField(
                                      value: _modalidad,
                                      options: _modalidades,
                                      onChanged: (v) => setState(() => _modalidad = v),
                                    ),
                                    const SizedBox(height: 12),
                                    TextInput(controller: _fechaLimiteCtrl, title: 'Fecha límite de postulación (AAAA-MM-DD)'),
                                    const SizedBox(height: 12),
                                    TextInput(controller: _fechaPublicacionCtrl, title: 'Fecha de publicación (AAAA-MM-DD)'),
                                  ],
                                )
                                    : Row(
                                  children: [
                                    Expanded(
                                      child: _ModalidadField(
                                        value: _modalidad,
                                        options: _modalidades,
                                        onChanged: (v) => setState(() => _modalidad = v),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(child: TextInput(controller: _fechaLimiteCtrl, title: 'Fecha límite de postulación (AAAA-MM-DD)')),
                                    const SizedBox(width: 12),
                                    Expanded(child: TextInput(controller: _fechaPublicacionCtrl, title: 'Fecha de publicación (AAAA-MM-DD)')),
                                  ],
                                ),

                                const SizedBox(height: 18),

                                // ===== Agregar para: Habilidades blandas, Observaciones, Número de vacantes =====
                                _HabilidadesBlandasSearchable(
                                  title: 'HABILIDADES BLANDAS:',
                                  options: _habilidadesBlandasOpc,
                                  selected: _habilidadesBlandasSel,
                                  onAdd: _addHabilidadBlanda,
                                  onRemove: _removeHabilidadBlanda,
                                ),
                                const SizedBox(height: 12),
                                TextInput(controller: _observacionesCtrl, title: 'Observaciones'),
                                const SizedBox(height: 12),
                                TextInput(controller: _numeroVacantesCtrl, title: 'Número de vacantes', keyboardType: TextInputType.number),

                                const SizedBox(height: 18),

                                // Descripción
                                TextInput(controller: _descripcionCtrl, title: 'Añade una descripción'),
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

          // ===== Footer animado =====
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
                child: Builder(
                  builder: (context) {
                    final isMobile = MediaQuery.of(context).size.width < 900;
                    return EscomFooter(isMobile: isMobile);
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===== Handlers (Escolares) =====
  void _addEscolarText() {
    final v = _escolarInputCtrl.text.trim();
    if (v.isEmpty) return;
    setState(() {
      final idx = _escolaresSel.length + 1;
      _escolaresSel.add('$idx. $v');
      _escolarInputCtrl.clear();
    });
  }

  void _removeEscolar(String v) {
    setState(() => _escolaresSel.remove(v));
  }

  // ===== Handlers (Específicos) =====
  void _addEspecifico(String v) {
    if (!_especificosSel.contains(v)) {
      setState(() => _especificosSel.add(v));
    }
  }

  void _removeEspecifico(String v) {
    setState(() => _especificosSel.remove(v));
  }

  // ===== Handlers (Habilidades blandas) =====
  void _addHabilidadBlanda(String v) {
    if (!_habilidadesBlandasSel.contains(v)) {
      setState(() => _habilidadesBlandasSel.add(v));
    }
  }

  void _removeHabilidadBlanda(String v) {
    setState(() => _habilidadesBlandasSel.remove(v));
  }

  void _publicar() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Vacante publicada (demo UI).')),
    );
  }
}

// ===================================================================
// ===============  WIDGETS DE APOYO VISUAL (inline)  =================
// ===================================================================

class _ChipList extends StatelessWidget {
  const _ChipList({required this.items, required this.onRemove});

  final List<String> items;
  final void Function(String) onRemove;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items
          .map(
            (e) => Chip(
          label: Text(e),
          deleteIcon: const Icon(Icons.close, size: 18),
          onDeleted: () => onRemove(e),
        ),
      )
          .toList(),
    );
  }
}

class _RequisitosEscolaresTextOnly extends StatelessWidget {
  const _RequisitosEscolaresTextOnly({
    required this.title,
    required this.inputController,
    required this.selected,
    required this.onAdd,
    required this.onRemove,
  });

  final String title;
  final TextEditingController inputController;
  final List<String> selected;
  final VoidCallback onAdd;
  final void Function(String) onRemove;

  @override
  Widget build(BuildContext context) {
    return _CardBox(
      title: title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: inputController,
                  decoration: const InputDecoration(
                    labelText: 'Escribe un requisito escolar y presiona Agregar',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => onAdd(),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: onAdd,
                  icon: const Icon(Icons.add),
                  label: const Text('Agregar'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _ChipList(items: selected, onRemove: onRemove),
        ],
      ),
    );
  }
}

class _RequisitosDropdownColumn extends StatefulWidget {
  const _RequisitosDropdownColumn({
    required this.title,
    required this.options,
    required this.selected,
    required this.onAdd,
    required this.onRemove,
  });

  final String title;
  final List<String> options;
  final List<String> selected;
  final void Function(String) onAdd;
  final void Function(String) onRemove;

  @override
  State<_RequisitosDropdownColumn> createState() => _RequisitosDropdownColumnState();
}

class _RequisitosDropdownColumnState extends State<_RequisitosDropdownColumn> {
  String? _current;

  @override
  Widget build(BuildContext context) {
    return _CardBox(
      title: widget.title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _current,
                  items: widget.options
                      .map((e) => DropdownMenuItem<String>(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (v) => setState(() => _current = v),
                  decoration: const InputDecoration(
                    labelText: 'Selecciona un requisito específico',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _current == null ? null : () => widget.onAdd(_current!),
                  icon: const Icon(Icons.add),
                  label: const Text('Agregar'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _ChipList(items: widget.selected, onRemove: widget.onRemove),
        ],
      ),
    );
  }
}

// ====== FIX AQUÍ: Autocomplete con controller + focusNode ======
class _HabilidadesBlandasSearchable extends StatefulWidget {
  const _HabilidadesBlandasSearchable({
    required this.title,
    required this.options,
    required this.selected,
    required this.onAdd,
    required this.onRemove,
  });

  final String title;
  final List<String> options;
  final List<String> selected;
  final void Function(String) onAdd;
  final void Function(String) onRemove;

  @override
  State<_HabilidadesBlandasSearchable> createState() => _HabilidadesBlandasSearchableState();
}

class _HabilidadesBlandasSearchableState extends State<_HabilidadesBlandasSearchable> {
  final TextEditingController _fieldCtrl = TextEditingController();
  final FocusNode _fieldFocus = FocusNode(); // <-- añadido

  @override
  void dispose() {
    _fieldCtrl.dispose();
    _fieldFocus.dispose(); // <-- añadido
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _CardBox(
      title: widget.title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RawAutocomplete<String>(
            textEditingController: _fieldCtrl, // <-- pasamos ambos
            focusNode: _fieldFocus,            // <-- pasamos ambos
            optionsBuilder: (TextEditingValue textEditingValue) {
              final q = textEditingValue.text.trim().toLowerCase();
              if (q.isEmpty) return const Iterable<String>.empty();
              return widget.options.where((opt) => opt.toLowerCase().contains(q));
            },
            fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
              // controller == _fieldCtrl y focusNode == _fieldFocus
              return TextField(
                controller: controller,
                focusNode: focusNode,
                decoration: const InputDecoration(
                  labelText: 'Buscar y agregar habilidad blanda',
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (_) => onFieldSubmitted(),
              );
            },
            onSelected: (String selection) {
              widget.onAdd(selection);
              _fieldCtrl.clear();
              _fieldFocus.requestFocus();
            },
            optionsViewBuilder: (context, onSelected, options) {
              return Align(
                alignment: Alignment.topLeft,
                child: Material(
                  elevation: 4.0,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 240, maxWidth: 520),
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      itemCount: options.length,
                      itemBuilder: (BuildContext context, int index) {
                        final String option = options.elementAt(index);
                        return ListTile(
                          title: Text(option),
                          onTap: () => onSelected(option),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          _ChipList(items: widget.selected, onRemove: widget.onRemove),
        ],
      ),
    );
  }
}

class _ModalidadField extends StatelessWidget {
  const _ModalidadField({
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String? value;
  final List<String> options;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value,
      items: options.map((e) => DropdownMenuItem<String>(value: e, child: Text(e))).toList(),
      onChanged: onChanged,
      decoration: const InputDecoration(
        labelText: 'Modalidad',
        border: OutlineInputBorder(),
      ),
    );
  }
}

class _CardBox extends StatelessWidget {
  const _CardBox({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.w700,
      color: const Color(0xFF22313F),
    );
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x11000000)),
        boxShadow: const [
          BoxShadow(
            blurRadius: 10,
            spreadRadius: 0,
            offset: Offset(0, 2),
            color: Color(0x0F000000),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: titleStyle),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
