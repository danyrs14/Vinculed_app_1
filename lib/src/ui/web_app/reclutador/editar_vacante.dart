import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:vinculed_app_1/src/core/controllers/theme_controller.dart';
import 'package:vinculed_app_1/src/core/providers/user_provider.dart';
import 'package:vinculed_app_1/src/ui/widgets/elements/header3.dart';
import 'package:vinculed_app_1/src/ui/widgets/elements/footer.dart';
import 'package:vinculed_app_1/src/ui/widgets/buttons/simple_buttons.dart';
import 'package:vinculed_app_1/src/ui/widgets/text_inputs/dropdown.dart';
import 'package:vinculed_app_1/src/ui/widgets/text_inputs/text_form_field.dart';
import 'package:vinculed_app_1/src/ui/widgets/text_inputs/habilidades_multi_dropdown.dart';
import 'package:vinculed_app_1/src/ui/widgets/text_inputs/roles_multi_dropdown.dart';

class _LocalCardBox extends StatelessWidget {
  const _LocalCardBox({required this.title, required this.child});
  final String title; final Widget child;
  @override
  Widget build(BuildContext context){
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white,borderRadius: BorderRadius.circular(14),border: Border.all(color: const Color(0x11000000)), boxShadow: const [BoxShadow(blurRadius:10,offset:Offset(0,2),color: Color(0x0F000000))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start,children:[
        Text(title, style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF22313F)) ),
        const SizedBox(height:12), child,
      ]),
    );
  }
}
class _LocalDateTimePickerField extends StatelessWidget {
  const _LocalDateTimePickerField({required this.label, required this.controller, required this.onTap});
  final String label; final TextEditingController controller; final VoidCallback onTap;
  @override
  Widget build(BuildContext context){
    final theme = ThemeController.instance;
    return TextFormField(
      readOnly:true,
      controller:controller,
      onTap:onTap,
      decoration: InputDecoration(
        labelText:label,
        labelStyle: const TextStyle(fontSize:14,color:Colors.grey,fontFamily:'Poppins'),
        floatingLabelStyle: TextStyle(color: theme.fuente(), fontFamily:'Poppins'),
        border: const OutlineInputBorder(),
        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: theme.secundario())),
        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: theme.secundario(), width:1.4)),
        isDense:true,
        contentPadding: const EdgeInsets.symmetric(vertical:14, horizontal:12),
        suffixIcon: const Icon(Icons.calendar_today),
      ),
    );
  }
}
class _LocalHabilidadesBlandas extends StatefulWidget {
  const _LocalHabilidadesBlandas({required this.onSelected, required this.initialSelectedIds});
  final ValueChanged<List<HabilidadOption>> onSelected;
  final List<int> initialSelectedIds;
  @override State<_LocalHabilidadesBlandas> createState()=> _LocalHabilidadesBlandasState();
}
class _LocalHabilidadesBlandasState extends State<_LocalHabilidadesBlandas>{
  List<int> _ids = [];
  @override void initState(){ super.initState(); _ids = List<int>.from(widget.initialSelectedIds); }
  @override void didUpdateWidget(covariant _LocalHabilidadesBlandas oldWidget){
    super.didUpdateWidget(oldWidget);
    final oldSet = Set<int>.from(oldWidget.initialSelectedIds);
    final newSet = Set<int>.from(widget.initialSelectedIds);
    if(oldSet.length != newSet.length || !oldSet.containsAll(newSet)){
      setState(()=> _ids = List<int>.from(widget.initialSelectedIds));
    }
  }
  @override Widget build(BuildContext context){
    return _LocalCardBox(title: 'HABILIDADES BLANDAS:', child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
      HabilidadesMultiDropdown(label: 'Selecciona habilidades blandas e idiomas', hintText: '', allowedTipos: const ['blanda','idioma'], initialSelectedIds: _ids, onChanged: (list){ _ids = list.map((e)=> e.id).toList(); widget.onSelected(list); }),
      const SizedBox(height:12),
    ]));
  }
}

class EditVacancyPage extends StatefulWidget {
  const EditVacancyPage({super.key, this.idVacante});
  final int? idVacante;
  @override
  State<EditVacancyPage> createState() => _EditVacancyPageState();
}

class _EditVacancyPageState extends State<EditVacancyPage> {
  final _scrollCtrl = ScrollController();
  bool _showFooter = false;
  static const double _footerReservedSpace = EscomFooter.height;
  static const double _extraBottomPadding = 24.0;
  static const double _atEndThreshold = 4.0;
  final _formKey = GlobalKey<FormState>();

  // Controllers (same as create)
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
  final _municipioCtrl = TextEditingController();
  final _entidadCtrl = TextEditingController();
  final _cpCtrl = TextEditingController();
  final _fechaInicioCtrl = TextEditingController();
  final _fechaFinCtrl = TextEditingController();
  final _fechaLimiteCtrl = TextEditingController();

  List<RoleOption> _rolesSeleccionados = [];
  List<int> _habTecnicasIds = [];
  List<int> _habBlandasIds = [];

  bool _loadingData = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _onScroll();
      _fetchVacante();
    });
  }

  void _onScroll() {
    final pos = _scrollCtrl.position;
    if (!pos.hasPixels || !pos.hasContentDimensions) return;
    if (pos.maxScrollExtent <= 0) { if (_showFooter) setState(() => _showFooter = false); return; }
    final atBottom = pos.pixels >= (pos.maxScrollExtent - _atEndThreshold);
    if (atBottom != _showFooter) setState(() => _showFooter = atBottom);
  }

  Future<void> _fetchVacante() async {
    final id = widget.idVacante;
    if (id == null) return;
    setState(() { _loadingData = true; _loadError = null; });
    try {
      final provider = context.read<UserDataProvider>();
      final idReclutador = provider.idRol;
      if (idReclutador == null) { setState(() { _loadError = 'Sin id_reclutador'; _loadingData = false; }); return; }
      final headers = await provider.getAuthHeaders();
      final uri = Uri.parse('https://oda-talent-back-81413836179.us-central1.run.app/api/vacantes/detalles?id_vacante=$id&id_reclutador=$idReclutador');
      final resp = await http.get(uri, headers: headers);
      if (resp.statusCode != 200) { setState(() { _loadError = 'Error ${resp.statusCode}'; _loadingData = false; }); return; }
      final data = jsonDecode(resp.body) as Map<String,dynamic>;
      _fillForm(data);
      setState(() { _loadingData = false; });
    } catch (e) {
      setState(() { _loadError = 'Excepción: $e'; _loadingData = false; });
    }
  }

  void _fillForm(Map<String,dynamic> d) {
    _nombreCtrl.text = d['titulo']?.toString() ?? '';
    _descripcionCtrl.text = d['descripcion']?.toString() ?? '';
    _beneficiosCtrl.text = d['beneficios']?.toString() ?? '';
    _duracionCtrl.text = d['duracion']?.toString() ?? '';
    _fechaInicioCtrl.text = d['fecha_inicio']?.toString() ?? '';
    _fechaFinCtrl.text = d['fecha_fin']?.toString() ?? '';
    _salarioCtrl.text = d['monto_beca']?.toString() ?? '';
    _horarioCtrl.text = d['horario']?.toString() ?? '';
    _direccionCtrl.text = d['ubicacion']?.toString() ?? '';
    _municipioCtrl.text = d['ciudad']?.toString() ?? '';
    _entidadCtrl.text = d['entidad']?.toString() ?? '';
    _cpCtrl.text = d['codigo_postal']?.toString() ?? '';
    _modalidad = d['modalidad']?.toString();
    _fechaLimiteCtrl.text = d['fecha_limite']?.toString() ?? '';
    _escolaridadCtrl.text = d['escolaridad']?.toString() ?? '';
    _conocimientosCtrl.text = d['conocimientos']?.toString() ?? '';
    _observacionesCtrl.text = d['observaciones']?.toString() ?? '';
    _numeroVacantesCtrl.text = d['numero_vacantes']?.toString() ?? '';
    // roles
    final roles = (d['roles_relacionados'] as List? ?? []).map((e) {
      if (e is Map<String,dynamic>) {
        return RoleOption(id: e['id_roltrabajo'] ?? e['id'] ?? 0, area: e['area']?.toString() ?? '', nombre: e['nombre']?.toString() ?? (e['rol']?.toString() ?? 'Rol'));
      }
      return RoleOption(id: 0, area: '', nombre: e.toString());
    }).toList();
    _rolesSeleccionados = roles;
    // habilidades
    final habs = (d['habilidades'] as List? ?? []);
    _habTecnicasIds = [];
    _habBlandasIds = [];
    for (var h in habs) {
      if (h is Map<String,dynamic>) {
        final tipo = (h['tipo']?.toString() ?? '');
        final idH = h['id_habilidad'] ?? h['id'] ?? 0;
        if (tipo.contains('Técnicas')) _habTecnicasIds.add(idH);
        else _habBlandasIds.add(idH);
      }
    }
  }

  String _fmt(DateTime dt) {
    String two(int v) => v.toString().padLeft(2,'0');
    return '${dt.year}-${two(dt.month)}-${two(dt.day)} ${two(dt.hour)}:${two(dt.minute)}:00';
  }
  DateTime? _tryParseInput(String? s){
    if(s==null) return null; final t=s.trim(); if(t.isEmpty) return null;
    final onlyDate = RegExp(r'^\d{4}-\d{2}-\d{2}$');
    if(onlyDate.hasMatch(t)){
      try{ final p=t.split('-'); return DateTime(int.parse(p[0]),int.parse(p[1]),int.parse(p[2]),0,0,0);}catch(_){ }
    }
    final re = RegExp(r'^(\d{4})-(\d{2})-(\d{2}) (\d{2}):(\d{2}):(\d{2})$');
    final m = re.firstMatch(t);
    if(m!=null){ try{ return DateTime(int.parse(m.group(1)!),int.parse(m.group(2)!),int.parse(m.group(3)!),int.parse(m.group(4)!),int.parse(m.group(5)!),int.parse(m.group(6)!)); }catch(_){ } }
    try{ return DateTime.parse(t).toLocal(); }catch(_){ return null; }
  }

  Future<void> _pickDateTime({required TextEditingController controller}) async {
    final now = DateTime.now();
    final d = await showDatePicker(context: context, initialDate: now, firstDate: DateTime(2000), lastDate: DateTime(2100));
    if (d == null) return;
    final t = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(now));
    final picked = DateTime(d.year,d.month,d.day,t?.hour??0,t?.minute??0);
    controller.text = _fmt(picked);
  }

  @override
  void dispose() {
    _scrollCtrl..removeListener(_onScroll)..dispose();
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
            case 'Inicio': context.go('/inicio'); break;
            case 'Crear Vacante': context.go('/reclutador/new_vacancy'); break;
            case 'Postulaciones': context.go('/reclutador/postulaciones'); break;
            case 'FAQ': context.go('/reclutador/faq_rec'); break;
            case 'Mensajes': context.go('/reclutador/msg_rec'); break;
          }
        },
      ),
      body: Stack(children: [
        Positioned.fill(child: _buildForm(isMobile)),
        Positioned(left:0,right:0,bottom:0,child: AnimatedSlide(
          duration: const Duration(milliseconds:220), curve: Curves.easeOut,
          offset: _showFooter ? Offset.zero : const Offset(0,1),
          child: AnimatedOpacity(duration: const Duration(milliseconds:220), opacity: _showFooter?1:0,
            child: EscomFooter(isMobile: isMobile),
          ),
        ))
      ]),
    );
  }

  Widget _buildForm(bool isMobile) {
    if (_loadingData) return const Center(child: CircularProgressIndicator());
    if (_loadError != null) return Center(child: Text(_loadError!, style: const TextStyle(color: Colors.red)));
    return LayoutBuilder(
      builder: (context, constraints) {
        final minH = constraints.maxHeight - _footerReservedSpace - _extraBottomPadding;
        return NotificationListener<ScrollNotification>(
          onNotification: (n) {
            if (n is ScrollUpdateNotification || n is UserScrollNotification || n is ScrollEndNotification) {
              _onScroll();
            }
            return false;
          },
          child: SingleChildScrollView(
            controller: _scrollCtrl,
            padding: const EdgeInsets.only(bottom: _footerReservedSpace + _extraBottomPadding),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal:24, vertical:28),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: minH > 0 ? minH : 0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            const CircleAvatar(radius: 18, backgroundImage: AssetImage('assets/images/escom.png'), backgroundColor: Colors.transparent),
                            const SizedBox(width: 12),
                            Text('Editar Vacante', style: TextStyle(fontSize: isMobile?24:32, fontWeight: FontWeight.w800, color: const Color(0xFF22313F))),
                          ]),
                          const SizedBox(height:24),
                          StyledTextFormField(controller: _nombreCtrl, title: 'Título de la vacante', isRequired: true, validator: (v)=> (v==null||v.trim().isEmpty)?'Obligatorio':null),
                          const SizedBox(height:8),
                          RolesMultiDropdown(label: 'Roles de trabajo relacionados', hintText: '', initialSelectedIds: _rolesSeleccionados.map((e)=> e.id).toList(), onChanged: (r)=> setState(()=> _rolesSeleccionados = r)),
                          const SizedBox(height:12),
                          StyledTextFormField(controller: _salarioCtrl, title: 'Monto de beca mensual', keyboardType: TextInputType.number, isRequired:true, validator:(v){ if(v==null||v.trim().isEmpty) return 'Obligatorio'; return double.tryParse(v.replaceAll(',', '.'))==null? 'Número inválido': null; }),
                          const SizedBox(height:12),
                          StyledTextFormField(controller: _direccionCtrl, title: 'Calle y número', isRequired:true, validator:(v)=> (v==null||v.trim().isEmpty)?'Obligatorio':null),
                          const SizedBox(height:12),
                          isMobile? Column(children:[
                            StyledTextFormField(controller: _municipioCtrl, title: 'Municipio/Ciudad', isRequired:true, validator:(v)=> (v==null||v.trim().isEmpty)?'Obligatorio':null),
                            const SizedBox(height:12),
                            StyledTextFormField(controller: _entidadCtrl, title: 'Entidad', isRequired:true, validator:(v)=> (v==null||v.trim().isEmpty)?'Obligatorio':null),
                            const SizedBox(height:12),
                            StyledTextFormField(controller: _cpCtrl, title: 'Código Postal', keyboardType: TextInputType.number, isRequired:false),
                          ]) : Row(children:[
                            Expanded(child: StyledTextFormField(controller: _municipioCtrl, title: 'Municipio/Ciudad', isRequired:true, validator:(v)=> (v==null||v.trim().isEmpty)?'Obligatorio':null)),
                            const SizedBox(width:12),
                            Expanded(child: StyledTextFormField(controller: _entidadCtrl, title: 'Entidad', isRequired:true, validator:(v)=> (v==null||v.trim().isEmpty)?'Obligatorio':null)),
                            const SizedBox(width:12),
                            Expanded(child: StyledTextFormField(controller: _cpCtrl, title: 'Código Postal', keyboardType: TextInputType.number, isRequired:false)),
                          ]),
                          const SizedBox(height:16),
                          // REPLACED WIDGETS
                          _LocalCardBox(title: 'REQUISITOS ESPECÍFICOS:', child: HabilidadesMultiDropdown(label: 'Habilidades técnicas requeridas', hintText: '', allowedTipo: 'técnica', initialSelectedIds: _habTecnicasIds, onChanged: (list)=> setState(()=> _habTecnicasIds = list.map((e)=> e.id).toList())),),
                          const SizedBox(height:12),
                          StyledTextFormField(controller: _conocimientosCtrl, title: 'Conocimientos (opcional)', maxLines:4, maxLength:1000, isRequired:false),
                          const SizedBox(height:16),
                          isMobile? Column(children:[
                            _LocalDateTimePickerField(label: 'Fecha inicio', controller: _fechaInicioCtrl, onTap: ()=> _pickDateTime(controller: _fechaInicioCtrl)),
                            const SizedBox(height:12),
                            _LocalDateTimePickerField(label: 'Fecha fin', controller: _fechaFinCtrl, onTap: ()=> _pickDateTime(controller: _fechaFinCtrl)),
                            const SizedBox(height:12),
                            StyledTextFormField(controller: _duracionCtrl, title: 'Duración', isRequired:true, validator:(v)=> (v==null||v.trim().isEmpty)?'Obligatorio':null),
                          ]) : Row(children:[
                            Expanded(child: _LocalDateTimePickerField(label: 'Fecha inicio', controller: _fechaInicioCtrl, onTap: ()=> _pickDateTime(controller: _fechaInicioCtrl)) ),
                            const SizedBox(width:12),
                            Expanded(child: _LocalDateTimePickerField(label: 'Fecha fin', controller: _fechaFinCtrl, onTap: ()=> _pickDateTime(controller: _fechaFinCtrl)) ),
                            const SizedBox(width:12),
                            Expanded(child: StyledTextFormField(controller: _duracionCtrl, title: 'Duración', isRequired:true, validator:(v)=> (v==null||v.trim().isEmpty)?'Obligatorio':null)),
                          ]),
                          const SizedBox(height:12),
                          isMobile? Column(children:[
                            DropdownInput(value: _modalidad, items: const [DropdownMenuItem(value:'Remoto',child: Text('Remoto')), DropdownMenuItem(value:'Híbrido',child: Text('Híbrido')), DropdownMenuItem(value:'Presencial',child: Text('Presencial'))], onChanged:(v)=> setState(()=> _modalidad=v),title: 'Modalidad', required: true,),
                            const SizedBox(height:12),
                            _LocalDateTimePickerField(label: 'Fecha límite', controller: _fechaLimiteCtrl, onTap: ()=> _pickDateTime(controller: _fechaLimiteCtrl)),
                          ]) : Row(children:[
                            Expanded(child: DropdownButtonFormField<String>(value: _modalidad, items: const [DropdownMenuItem(value:'Remoto',child: Text('Remoto')), DropdownMenuItem(value:'Híbrido',child: Text('Híbrido')), DropdownMenuItem(value:'Presencial',child: Text('Presencial'))], onChanged:(v)=> setState(()=> _modalidad=v), decoration: const InputDecoration(labelText:'Modalidad', border: OutlineInputBorder()))),
                            const SizedBox(width:12),
                            Expanded(child: _LocalDateTimePickerField(label: 'Fecha límite', controller: _fechaLimiteCtrl, onTap: ()=> _pickDateTime(controller: _fechaLimiteCtrl)) ),
                          ]),
                          const SizedBox(height:12),
                          StyledTextFormField(controller: _escolaridadCtrl, title: 'Escolaridad', isRequired:true, validator:(v)=> (v==null||v.trim().isEmpty)?'Obligatorio':null),
                          const SizedBox(height:18),
                          _LocalHabilidadesBlandas(initialSelectedIds: _habBlandasIds, onSelected: (list){ _habBlandasIds = list.map((e)=> e.id).toList(); }),
                          const SizedBox(height:12),
                          StyledTextFormField(controller: _observacionesCtrl, title: 'Observaciones (opcional)', maxLines:3, maxLength:400, isRequired:false),
                          const SizedBox(height:12),
                          StyledTextFormField(controller: _numeroVacantesCtrl, title: 'Número de vacantes', keyboardType: TextInputType.number, isRequired:true, validator:(v){ if(v==null||v.trim().isEmpty) return 'Obligatorio'; return int.tryParse(v)==null? 'Entero inválido': null; }),
                          const SizedBox(height:18),
                          StyledTextFormField(controller: _descripcionCtrl, title: 'Descripción', maxLines:6, maxLength:4000, isRequired:true, validator:(v)=> (v==null||v.trim().isEmpty)?'Obligatorio':null),
                          const SizedBox(height:12),
                          StyledTextFormField(controller: _beneficiosCtrl, title: 'Beneficios (opcional)', maxLines:4, maxLength:1500, isRequired:false),
                          const SizedBox(height:12),
                          StyledTextFormField(controller: _horarioCtrl, title: 'Horario', isRequired:true, validator:(v)=> (v==null||v.trim().isEmpty)?'Obligatorio':null),
                          const SizedBox(height:18),
                          Align(alignment: Alignment.center, child: SizedBox(width: isMobile?240:320, child: SimpleButton(title: 'Guardar Cambios', onTap: _guardarCambios))),
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
    );
  }

  Future<void> _guardarCambios() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Corrige los errores antes de guardar')));
      return;
    }
    // Validaciones de fechas
    final ahora = DateTime.now();
    final hoy = DateTime(ahora.year, ahora.month, ahora.day);
    final fInicio = _tryParseInput(_fechaInicioCtrl.text);
    final fFin = _tryParseInput(_fechaFinCtrl.text);
    final fLimite = _tryParseInput(_fechaLimiteCtrl.text);
    DateTime? only(DateTime? d)=> d==null? null: DateTime(d.year,d.month,d.day);
    final oInicio = only(fInicio); final oFin = only(fFin); final oLimite = only(fLimite);
    final errores = <String>[];
    if (oInicio != null && oInicio.isBefore(hoy)) errores.add('La fecha de inicio no puede ser menor que hoy.');
    if (oFin != null && oFin.isBefore(hoy)) errores.add('La fecha de fin no puede ser menor que hoy.');
    if (oLimite != null && oInicio != null && oLimite.isAfter(oInicio)) errores.add('La fecha límite debe ser anterior o igual a la fecha de inicio.');
    if (oLimite != null && oLimite.isBefore(hoy)) errores.add('La fecha límite no puede ser menor que hoy.');
    if (oFin != null && oInicio != null && oFin.isBefore(oInicio)) errores.add('La fecha de fin no puede ser menor que la fecha de inicio.');
    if(errores.isNotEmpty){
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errores.join('\n'))));
      return;
    }
    try {
      final provider = context.read<UserDataProvider>();
      final headers = await provider.getAuthHeaders();
      final idReclutador = provider.idRol;
      final idVacante = widget.idVacante;
      final habilidadesSet = <int>{}..addAll(_habTecnicasIds)..addAll(_habBlandasIds);
      final habilidadesList = habilidadesSet.map((id) => {'id_habilidad': id}).toList();
      final rolesList = _rolesSeleccionados.map((r)=> {'id_roltrabajo': r.id}).toList();
      final payload = <String,dynamic>{
        'id_vacante': idVacante,
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
      payload.removeWhere((k,v)=> v==null);
      final resp = await http.put(Uri.parse('https://oda-talent-back-81413836179.us-central1.run.app/api/reclutadores/editar_vacante'), headers: headers, body: jsonEncode(payload));
      if (!mounted) return;
      if (resp.statusCode >=200 && resp.statusCode <300) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cambios guardados')));
        context.go('/reclutador/postulaciones');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error ${resp.statusCode}: ${resp.body}')));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Excepción: $e')));
    }
  }
}
