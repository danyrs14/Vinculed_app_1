import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:vinculed_app_1/src/core/controllers/theme_controller.dart';
import 'package:vinculed_app_1/src/core/providers/user_provider.dart';
import 'package:vinculed_app_1/src/ui/pages/reclutador/menu.dart';
import 'package:vinculed_app_1/src/ui/widgets/buttons/simple_buttons.dart';
import 'package:vinculed_app_1/src/ui/widgets/text_inputs/text_form_field.dart';
import 'package:vinculed_app_1/src/ui/widgets/text_inputs/roles_multi_dropdown.dart';
import 'package:vinculed_app_1/src/ui/widgets/text_inputs/habilidades_multi_dropdown.dart';
import 'package:vinculed_app_1/src/ui/widgets/text_inputs/dropdown.dart';
import 'package:vinculed_app_1/src/ui/widgets/textos/textos.dart';

class CrearVacantePage extends StatefulWidget {
  const CrearVacantePage({super.key});
  @override
  State<CrearVacantePage> createState() => _CrearVacantePageState();
}

class _CrearVacantePageState extends State<CrearVacantePage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers generales
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
  String? _modalidad;

  // Dirección detallada
  final _municipioCtrl = TextEditingController();
  final _entidadCtrl = TextEditingController();
  final _cpCtrl = TextEditingController();

  // Fechas
  final _fechaInicioCtrl = TextEditingController();
  final _fechaFinCtrl = TextEditingController();
  final _fechaLimiteCtrl = TextEditingController();

  // Selecciones de roles y habilidades
  List<RoleOption> _rolesSeleccionados = [];
  List<int> _habTecnicasIds = [];
  List<int> _habBlandasIds = [];

  @override
  void dispose() {
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
    super.dispose();
  }

  String _fmt(DateTime dt) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${dt.year}-${two(dt.month)}-${two(dt.day)} ${two(dt.hour)}:${two(dt.minute)}:00';
  }

  Future<void> _pickDateTime({required TextEditingController controller}) async {
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
      final habilidadesList = habilidadesSet.map((id) => {'id_habilidad': id}).toList();
      final rolesList = _rolesSeleccionados.map((r) => {'id_roltrabajo': r.id}).toList();

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
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error ${resp.statusCode}: ${resp.body}')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al enviar: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;

    return Scaffold(
      backgroundColor: theme.background(),
      appBar: AppBar(
          elevation: 0,
          backgroundColor: theme.background(),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            color: Colors.black87,
            // El icono de back SÍ regresa a la pantalla anterior
            onPressed: () => Navigator.pop(context),
            ),
          title: const Texto(
            text: 'Crear Vacante',
            fontSize: 22,
          ),
        ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    
                    StyledTextFormField(
                      controller: _nombreCtrl,
                      title: 'Título de la vacante (ej. Analista de Datos)',
                      isRequired: true,
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'El título es obligatorio' : null,
                    ),
                    const SizedBox(height: 8),
                    RolesMultiDropdown(
                      label: 'Selecciona el rol o roles de trabajo relacionados',
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
                    StyledTextFormField(
                      controller: _direccionCtrl,
                      title: 'Calle y número de la dirección',
                      isRequired: true,
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'La ubicación es obligatoria' : null,
                    ),
                    const SizedBox(height: 12),
                    // Dirección detallada móvil
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
                    const SizedBox(height: 16),

                    _CardBox(
                      title: 'REQUISITOS ESPECÍFICOS:',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          HabilidadesMultiDropdown(
                            label: 'Selecciona habilidades técnicas que debe tener el candidato',
                            hintText: '',
                            allowedTipo: 'técnica',
                            onChanged: (list) => setState(() => _habTecnicasIds = list.map((e) => e.id).toList()),
                            initialSelectedIds: const [],
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    StyledTextFormField(
                      controller: _conocimientosCtrl,
                      title: 'Conocimientos (opcional)',
                      maxLines: 4,
                      maxLength: 1000,
                      isRequired: false,
                    ),
                    const SizedBox(height: 16),

                    // Fechas y duración (móvil)
                    _DateTimePickerField(
                      label: 'Fecha inicio (opcional)',
                      controller: _fechaInicioCtrl,
                      onTap: () => _pickDateTime(controller: _fechaInicioCtrl),
                    ),
                    const SizedBox(height: 12),
                    _DateTimePickerField(
                      label: 'Fecha fin (opcional)',
                      controller: _fechaFinCtrl,
                      onTap: () => _pickDateTime(controller: _fechaFinCtrl),
                    ),
                    const SizedBox(height: 12),
                    StyledTextFormField(
                      controller: _duracionCtrl,
                      title: 'Duración (ej. 6 meses)',
                      isRequired: true,
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'La duración es obligatoria' : null,
                    ),
                    const SizedBox(height: 12),

                    DropdownInput<String>(
                      title: 'Modalidad',
                      required: true,
                      items: const [
                        DropdownMenuItem(value: 'Remoto', child: Text('Remoto')),
                        DropdownMenuItem(value: 'Híbrido', child: Text('Híbrido')),
                        DropdownMenuItem(value: 'Presencial', child: Text('Presencial')),
                      ],
                      validator: (v) => v == null ? 'Selecciona una modalidad' : null,
                      value: _modalidad,
                      onChanged: (v) => setState(() => _modalidad = v),
                    ),
                    const SizedBox(height: 12),
                    _DateTimePickerField(
                      label: 'Fecha límite de postulación (opcional)',
                      controller: _fechaLimiteCtrl,
                      onTap: () => _pickDateTime(controller: _fechaLimiteCtrl),
                    ),
                    const SizedBox(height: 12),

                    StyledTextFormField(
                      controller: _escolaridadCtrl,
                      title: 'Escolaridad (obligatoria)',
                      isRequired: true,
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'La escolaridad es obligatoria' : null,
                    ),
                    const SizedBox(height: 18),

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
                    const SizedBox(height: 24),
                    Align(
                      alignment: Alignment.center,
                      child: SizedBox(
                        width: 240,
                        height: 48,
                        child: SimpleButton(onTap: _publicar, title: 'Publicar Vacante'),
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
  }
}

class _CardBox extends StatelessWidget {
  const _CardBox({required this.title, required this.child});
  final String title; final Widget child;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x11000000)),
        boxShadow: const [
          BoxShadow(blurRadius: 10, spreadRadius: 0, offset: Offset(0, 2), color: Color(0x0F000000)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF22313F))),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _DateTimePickerField extends StatelessWidget {
  const _DateTimePickerField({required this.label, required this.controller, required this.onTap});
  final String label; final TextEditingController controller; final VoidCallback onTap;
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
        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: theme.secundario()))
            ,
        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: theme.secundario(), width: 1.4)),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        suffixIcon: const Icon(Icons.calendar_today),
      ),
    );
  }
}

class _HabilidadesBlandasSearchable extends StatefulWidget {
  const _HabilidadesBlandasSearchable({required this.title, required this.options, required this.selected, required this.onAdd, required this.onRemove, this.onSelectedHabilidadesChanged});
  final String title; final List<String> options; final List<String> selected; final void Function(String) onAdd; final void Function(String) onRemove; final ValueChanged<List<HabilidadOption>>? onSelectedHabilidadesChanged;
  @override
  State<_HabilidadesBlandasSearchable> createState() => _HabilidadesBlandasSearchableState();
}

class _HabilidadesBlandasSearchableState extends State<_HabilidadesBlandasSearchable> {
  void _onChanged(List<HabilidadOption> list) => widget.onSelectedHabilidadesChanged?.call(list);
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
        ],
      ),
    );
  }
}
