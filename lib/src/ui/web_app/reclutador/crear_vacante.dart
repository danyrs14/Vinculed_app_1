// lib/src/ui/pages/create_vacancy_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:vinculed_app_1/src/core/controllers/theme_controller.dart';
import 'package:vinculed_app_1/src/ui/widgets/buttons/simple_buttons.dart';
import 'package:vinculed_app_1/src/ui/widgets/elements/footer.dart';
import 'package:vinculed_app_1/src/ui/widgets/elements/header3.dart';
import 'package:vinculed_app_1/src/ui/widgets/text_inputs/habilidades_multi_dropdown.dart';
import 'package:vinculed_app_1/src/ui/widgets/text_inputs/roles_multi_dropdown.dart';
import 'package:vinculed_app_1/src/ui/widgets/text_inputs/text_form_field.dart';
import 'package:vinculed_app_1/src/ui/widgets/text_inputs/dropdown.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:vinculed_app_1/src/core/providers/user_provider.dart';

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

  final _formKey = GlobalKey<FormState>();

  // ===== Controllers (generales) =====
  final _nombreCtrl = TextEditingController();
  final _salarioCtrl = TextEditingController();
  final _direccionCtrl = TextEditingController();
  final _descripcionCtrl = TextEditingController();
  final _horarioCtrl = TextEditingController();
  final _conocimientosCtrl = TextEditingController();
  final _beneficiosCtrl = TextEditingController();
  final _duracionCtrl = TextEditingController();
  final _observacionesCtrl = TextEditingController();
  final _numeroVacantesCtrl = TextEditingController();
  final _escolaridadCtrl = TextEditingController();
  String? _modalidad; // Remoto, Híbrido, Presencial

  // Dirección
  final _municipioCtrl = TextEditingController();
  final _entidadCtrl = TextEditingController();
  final _cpCtrl = TextEditingController();

  // Fechas (controllers)
  final _fechaInicioCtrl = TextEditingController();
  final _fechaFinCtrl = TextEditingController();
  final _fechaLimiteCtrl = TextEditingController();
  final _fechaPublicacionCtrl = TextEditingController();

  // Selección de roles de trabajo
  List<RoleOption> _rolesSeleccionados = [];

  // IDs de habilidades seleccionadas
  List<int> _habTecnicasIds = [];
  List<int> _habBlandasIds = [];

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
    _horarioCtrl.dispose();
    _conocimientosCtrl.dispose();
    _beneficiosCtrl.dispose();
    _duracionCtrl.dispose();
    _observacionesCtrl.dispose();
    _numeroVacantesCtrl.dispose();
    _escolaridadCtrl.dispose();

    _municipioCtrl.dispose();
    _entidadCtrl.dispose();
    _cpCtrl.dispose();

    _fechaInicioCtrl.dispose();
    _fechaFinCtrl.dispose();
    _fechaLimiteCtrl.dispose();
    _fechaPublicacionCtrl.dispose();

    super.dispose();
  }

  String _fmt(DateTime dt) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${dt.year}-${two(dt.month)}-${two(dt.day)} ${two(dt.hour)}:${two(dt.minute)}:00';
  }

  Future<void> _pickDateTime({required TextEditingController controller, required ValueChanged<DateTime?> onPicked}) async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (d == null) return;
    final t = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(now));
    final picked = DateTime(d.year, d.month, d.day, t?.hour ?? 0, t?.minute ?? 0);
    controller.text = _fmt(picked);
    onPicked(picked);
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
                            child: Form(
                              key: _formKey,
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
                                  StyledTextFormField(
                                    controller: _nombreCtrl,
                                    title: 'Título de la vacante (ej. Analista de Datos)',
                                    isRequired: true,
                                    validator: (v) => (v == null || v.trim().isEmpty) ? 'El título es obligatorio' : null,
                                  ),
                                  const SizedBox(height: 8),
                                  RolesMultiDropdown(
                                    label: 'Selecciona el rol o roles de trabajo con los que se relaciona la vacante',
                                    hintText: '',
                                    onChanged: (roles) => setState(() => _rolesSeleccionados = roles),
                                  ),
                                  const SizedBox(height: 12),
                                  StyledTextFormField(
                                    controller: _salarioCtrl,
                                    title: 'Monto de beca mensual (ej. 1500.00)',
                                    keyboardType: TextInputType.number,
                                    isRequired: true,
                                    validator: (v) {
                                      if (v == null || v.trim().isEmpty) return 'El monto de beca es obligatorio';
                                      final n = double.tryParse(v.replaceAll(',', '.'));
                                      if (n == null) return 'Ingresa un número válido';
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                  // Dirección detallada
                                  StyledTextFormField(
                                    controller: _direccionCtrl,
                                    title: 'Calle y número de la dirección',
                                    isRequired: true,
                                    validator: (v) => (v == null || v.trim().isEmpty) ? 'La ubicación es obligatoria' : null,
                                  ),
                                  const SizedBox(height: 12),
                                  isMobile
                                      ? Column(
                                          children: [
                                            StyledTextFormField(
                                              controller: _municipioCtrl,
                                              title: 'Municipio o Ciudad',
                                              isRequired: true,
                                              validator: (v) => (v == null || v.trim().isEmpty) ? 'Municipio/Ciudad es obligatorio' : null,
                                            ),
                                            const SizedBox(height: 12),
                                            StyledTextFormField(
                                              controller: _entidadCtrl,
                                              title: 'Entidad (Estado)',
                                              isRequired: true,
                                              validator: (v) => (v == null || v.trim().isEmpty) ? 'Entidad es obligatoria' : null,
                                            ),
                                            const SizedBox(height: 12),
                                            StyledTextFormField(
                                              controller: _cpCtrl,
                                              title: 'Código Postal',
                                              keyboardType: TextInputType.number,
                                              isRequired: true,
                                              validator: (v) {
                                                if (v == null || v.trim().isEmpty) return 'C.P. es obligatorio'; // opcional
                                                if (int.tryParse(v) == null) return 'CP inválido';
                                                if (v.length < 4 || v.length > 10) return 'CP inválido';
                                                return null;
                                              },
                                            ),
                                          ],
                                        )
                                      : Row(
                                          children: [
                                            Expanded(
                                              child: StyledTextFormField(
                                                controller: _municipioCtrl,
                                                title: 'Municipio / Ciudad',
                                                isRequired: true,
                                                validator: (v) => (v == null || v.trim().isEmpty) ? 'Municipio/Ciudad es obligatorio' : null,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: StyledTextFormField(
                                                controller: _entidadCtrl,
                                                title: 'Entidad (Estado)',
                                                isRequired: true,
                                                validator: (v) => (v == null || v.trim().isEmpty) ? 'Entidad es obligatoria' : null,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: StyledTextFormField(
                                                controller: _cpCtrl,
                                                title: 'Código Postal',
                                                keyboardType: TextInputType.number,
                                                isRequired: true,
                                                validator: (v) {
                                                  if (v == null || v.trim().isEmpty) return 'C.P. es obligatorio';
                                                  if (int.tryParse(v) == null) return 'C.P. inválido';
                                                  if (v.length < 4 || v.length > 10) return 'C.P. inválido';
                                                  return null;
                                                },
                                              ),
                                            ),
                                          ],
                                        ),

                                  const SizedBox(height: 16),

                                  // ===== Requisitos Específicos (Habilidades técnicas) =====
                                  _CardBox(
                                    title: 'REQUISITOS ESPECÍFICOS:',
                                    child: HabilidadesMultiDropdown(
                                      label: 'Selecciona habilidades técnicas que debe tener el candidato',
                                      hintText: '',
                                      allowedTipo: 'técnica',
                                      onChanged: (list) => setState(() => _habTecnicasIds = list.map((e) => e.id).toList()),
                                      initialSelectedIds: const [],
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  StyledTextFormField(
                                    controller: _conocimientosCtrl,
                                    title: 'Conocimientos (opcional, redacta detalles específicos si no fue suficiente el campo anterior)',
                                    maxLines: 4,
                                    maxLength: 1000,
                                    isRequired: false,
                                  ),

                                  const SizedBox(height: 16),

                                  // Fechas y duración
                                  isMobile
                                      ? Column(
                                          children: [
                                            _DateTimePickerField(
                                              label: 'Fecha inicio (opcional)',
                                              controller: _fechaInicioCtrl,
                                              onTap: () => _pickDateTime(controller: _fechaInicioCtrl, onPicked: (_) {}),
                                            ),
                                            const SizedBox(height: 12),
                                            _DateTimePickerField(
                                              label: 'Fecha fin (opcional)',
                                              controller: _fechaFinCtrl,
                                              onTap: () => _pickDateTime(controller: _fechaFinCtrl, onPicked: (_) {}),
                                            ),
                                            const SizedBox(height: 12),
                                            StyledTextFormField(
                                              controller: _duracionCtrl,
                                              title: 'Duración (en meses, ej. 6 meses)',
                                              isRequired: true,
                                              validator: (v) => (v == null || v.trim().isEmpty) ? 'La duración es obligatoria' : null,
                                            ),
                                          ],
                                        )
                                      : Row(
                                          children: [
                                            Expanded(
                                              child: _DateTimePickerField(
                                                label: 'Fecha inicio (opcional)',
                                                controller: _fechaInicioCtrl,
                                                onTap: () => _pickDateTime(controller: _fechaInicioCtrl, onPicked: (_) {}),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: _DateTimePickerField(
                                                label: 'Fecha fin (opcional)',
                                                controller: _fechaFinCtrl,
                                                onTap: () => _pickDateTime(controller: _fechaFinCtrl, onPicked: (_) {}),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: StyledTextFormField(
                                                controller: _duracionCtrl,
                                                title: 'Duración (en meses, ej. 6 meses)',
                                                isRequired: true,
                                                validator: (v) => (v == null || v.trim().isEmpty) ? 'La duración es obligatoria' : null,
                                              ),
                                            ),
                                          ],
                                        ),
                                  const SizedBox(height: 12),

                                  // Modalidad + Fecha límite
                                  isMobile
                                      ? Column(
                                          children: [
                                            DropdownInput<String>(
                                              title: 'Modalidad',
                                              required: true,
                                              items: const [
                                                DropdownMenuItem(value: 'Remoto', child: Text('Remoto')),
                                                DropdownMenuItem(value: 'Híbrido', child: Text('Híbrido')),
                                                DropdownMenuItem(value: 'Presencial', child: Text('Presencial')),
                                              ],
                                              value: _modalidad,
                                              onChanged: (v) => setState(() => _modalidad = v),
                                              validator: (v) => v == null ? 'Selecciona una modalidad' : null,
                                            ),
                                            const SizedBox(height: 12),
                                            _DateTimePickerField(
                                              label: 'Fecha límite de postulación (opcional)',
                                              controller: _fechaLimiteCtrl,
                                              onTap: () => _pickDateTime(controller: _fechaLimiteCtrl, onPicked: (_) {}),
                                            ),
                                          ],
                                        )
                                      : Row(
                                          children: [
                                            Expanded(
                                              child: DropdownInput<String>(
                                                title: 'Modalidad',
                                                required: true,
                                                items: const [
                                                  DropdownMenuItem(value: 'Remoto', child: Text('Remoto')),
                                                  DropdownMenuItem(value: 'Híbrido', child: Text('Híbrido')),
                                                  DropdownMenuItem(value: 'Presencial', child: Text('Presencial')),
                                                ],
                                                value: _modalidad,
                                                onChanged: (v) => setState(() => _modalidad = v),
                                                validator: (v) => v == null ? 'Selecciona una modalidad' : null,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: _DateTimePickerField(
                                                label: 'Fecha límite de postulación (opcional)',
                                                controller: _fechaLimiteCtrl,
                                                onTap: () => _pickDateTime(controller: _fechaLimiteCtrl, onPicked: (_) {}),
                                              ),
                                            ),
                                          ],
                                        ),

                                  const SizedBox(height: 12),

                                  // Escolaridad requerida
                                  StyledTextFormField(
                                    controller: _escolaridadCtrl,
                                    title: 'Escolaridad (obligatoria, ej. Mínimo 6º semestre de Ing. en Sistemas)',
                                    isRequired: true,
                                    validator: (v) => (v == null || v.trim().isEmpty) ? 'La escolaridad es obligatoria' : null,
                                  ),

                                  const SizedBox(height: 18),

                                  // ===== Habilidades blandas + Observaciones + Vacantes =====
                                  _HabilidadesBlandasSearchable(
                                    title: 'HABILIDADES BLANDAS:',
                                    options: const [],
                                    selected: const [],
                                    onAdd: (_) {},
                                    onRemove: (_) {},
                                    onSelectedHabilidadesChanged: (list) => _habBlandasIds = list.map((e) => e.id).toList(),
                                  ),
                                  const SizedBox(height: 12),
                                  StyledTextFormField(
                                    controller: _observacionesCtrl,
                                    title: 'Observaciones (opcional, hasta 400 caracteres)',
                                    maxLines: 3,
                                    maxLength: 400,
                                    isRequired: false,
                                  ),
                                  const SizedBox(height: 12),
                                  StyledTextFormField(
                                    controller: _numeroVacantesCtrl,
                                    title: 'Número de vacantes',
                                    keyboardType: TextInputType.number,
                                    isRequired: true,
                                    validator: (v) {
                                      if (v == null || v.trim().isEmpty) return 'El número de vacantes es obligatorio';
                                      if (int.tryParse(v) == null) return 'Ingresa un número entero válido';
                                      return null;
                                    },
                                  ),

                                  const SizedBox(height: 18),

                                  // Descripción y otros textos
                                  StyledTextFormField(
                                    controller: _descripcionCtrl,
                                    title: 'Descripción de la vacante (máx. 4000 caracteres)',
                                    maxLines: 6,
                                    maxLength: 4000,
                                    isRequired: true,
                                    validator: (v) => (v == null || v.trim().isEmpty) ? 'La descripción es obligatoria' : null,
                                  ),
                                  const SizedBox(height: 12),
                                  StyledTextFormField(
                                    controller: _beneficiosCtrl,
                                    title: 'Beneficios (opcional, máx. 1500 caracteres)',
                                    maxLines: 4,
                                    maxLength: 1500,
                                    isRequired: false,
                                  ),
                                  const SizedBox(height: 12),
                                  StyledTextFormField(
                                    controller: _horarioCtrl,
                                    title: 'Horario (ej. Lunes a Viernes, 9:00 AM - 6:00 PM)',
                                    isRequired: true,
                                    validator: (v) => (v == null || v.trim().isEmpty) ? 'El horario es obligatorio' : null,
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

  void _publicar() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Corrige los errores del formulario')));
      return;
    }
    try {
      final userProv = Provider.of<UserDataProvider>(context, listen: false);
      final headers = await userProv.getAuthHeaders();
      final idReclutador = userProv.idRol;

      final habilidadesSet = <int>{}..addAll(_habTecnicasIds)..addAll(_habBlandasIds);
      final habilidadesList = habilidadesSet.map((id) => { 'id_habilidad': id }).toList();
      final rolesList = _rolesSeleccionados.map((r) => { 'id_roltrabajo': r.id }).toList();

      final payload = <String, dynamic>{
        'id_reclutador': idReclutador,
        'titulo': _nombreCtrl.text.trim(),
        'descripcion': _descripcionCtrl.text.trim(),
        'beneficios': _beneficiosCtrl.text.trim().isEmpty ? null : _beneficiosCtrl.text.trim(),
        'duracion': _duracionCtrl.text.trim(),
        'fecha_inicio': _fechaInicioCtrl.text.trim().isEmpty ? null : _fechaInicioCtrl.text.trim(),
        'fecha_fin': _fechaFinCtrl.text.trim().isEmpty ? null : _fechaFinCtrl.text.trim(),
        'monto_beca': double.tryParse(_salarioCtrl.text.replaceAll(',', '.')),
        'horario': _horarioCtrl.text.trim(),
        'ubicacion': _direccionCtrl.text.trim(),
        'ciudad': _municipioCtrl.text.trim(),
        'entidad': _entidadCtrl.text.trim(),
        'codigo_postal': _cpCtrl.text.trim().isEmpty ? null : int.tryParse(_cpCtrl.text.trim()),
        'modalidad': _modalidad,
        'fecha_limite': _fechaLimiteCtrl.text.trim().isEmpty ? null : _fechaLimiteCtrl.text.trim(),
        'escolaridad': _escolaridadCtrl.text.trim(),
        'conocimientos': _conocimientosCtrl.text.trim().isEmpty ? null : _conocimientosCtrl.text.trim(),
        'habilidades': habilidadesList,
        'observaciones': _observacionesCtrl.text.trim().isEmpty ? null : _observacionesCtrl.text.trim(),
        'numero_vacantes': int.tryParse(_numeroVacantesCtrl.text.trim()),
        'roles_relacionados': rolesList.isEmpty ? null : rolesList,
      };

      payload.removeWhere((k, v) => v == null);

      final resp = await http.post(
        Uri.parse('https://oda-talent-back-81413836179.us-central1.run.app/api/reclutadores/crear_vacante'),
        headers: headers,
        body: jsonEncode(payload),
      );

      if (!mounted) return;
      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vacante creada correctamente')));
        if (resp.statusCode == 201) {
          context.go('/reclutador/postulaciones');
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error ${resp.statusCode}: ${resp.body}')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al enviar: $e')));
    }
  }
}

// ===================================================================
// ===============  WIDGETS DE APOYO VISUAL (inline)  =================
// ===================================================================

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

// Reusable pequeño campo de fecha/hora
class _DateTimePickerField extends StatelessWidget {
  const _DateTimePickerField({
    required this.label,
    required this.controller,
    required this.onTap,
  });

  final String label;
  final TextEditingController controller;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;
    return TextFormField(
      controller: controller,
      readOnly: true,
      onTap: onTap,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 14, color: Colors.grey, fontFamily: 'Poppins'),
        floatingLabelStyle: TextStyle(color: theme.fuente(), fontFamily: 'Poppins'),
        border: const OutlineInputBorder(),
        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: theme.secundario())),
        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: theme.secundario(), width: 1.4)),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        suffixIcon: const Icon(Icons.calendar_today),
      ),
    );
  }
}

// ====== Habilidades blandas selector (ya adaptado) ======
class _HabilidadesBlandasSearchable extends StatefulWidget {
  const _HabilidadesBlandasSearchable({
    required this.title,
    required this.options,
    required this.selected,
    required this.onAdd,
    required this.onRemove,
    this.onSelectedHabilidadesChanged,
  });

  final String title;
  final List<String> options; // no usado
  final List<String> selected; // no usado
  final void Function(String) onAdd; // compat
  final void Function(String) onRemove; // compat
  final ValueChanged<List<HabilidadOption>>? onSelectedHabilidadesChanged;

  @override
  State<_HabilidadesBlandasSearchable> createState() => _HabilidadesBlandasSearchableState();
}

class _HabilidadesBlandasSearchableState extends State<_HabilidadesBlandasSearchable> {
  void _onChanged(List<HabilidadOption> list) {
    widget.onSelectedHabilidadesChanged?.call(list);
  }

  @override
  Widget build(BuildContext context) {
    return _CardBox(
      title: widget.title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HabilidadesMultiDropdown(
            label: 'Selecciona habilidades blandas e idiomas que debe tener el candidato',
            hintText: '',
            allowedTipos: const ['blanda', 'idioma'],
            onChanged: _onChanged,
            initialSelectedIds: const [],
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
