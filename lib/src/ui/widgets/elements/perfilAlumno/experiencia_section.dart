import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:vinculed_app_1/src/core/providers/user_provider.dart';
import 'package:vinculed_app_1/src/ui/widgets/elements/perfilAlumno/habilidad_clase.dart';
import 'package:vinculed_app_1/src/ui/widgets/text_inputs/text_form_field.dart';
import 'package:vinculed_app_1/src/ui/widgets/buttons/simple_buttons.dart';
import 'package:vinculed_app_1/src/ui/widgets/text_inputs/habilidades_multi_dropdown.dart';

class ExperienciaItem {
  final int idExperiencia;
  final int idAlumno;
  final String cargo;
  final String empresa;
  final String fechaInicio;
  final String? fechaFin;
  final String? descripcion;
  final List<HabilidadItem> habilidadesDesarrolladas;
  ExperienciaItem({
    required this.idExperiencia,
    required this.idAlumno,
    required this.cargo,
    required this.empresa,
    required this.fechaInicio,
    required this.fechaFin,
    required this.descripcion,
    required this.habilidadesDesarrolladas,
  });
  factory ExperienciaItem.fromJson(Map<String, dynamic> j) => ExperienciaItem(
        idExperiencia: j['id_experiencia'] ?? 0,
        idAlumno: j['id_alumno'] ?? 0,
        cargo: j['cargo'],
        empresa: j['empresa'],
        fechaInicio: j['fecha_inicio'],
        fechaFin: j['fecha_fin'],
        descripcion: j['descripcion'],
        habilidadesDesarrolladas: (j['habilidades_desarrolladas'] as List? ?? [])
            .map((e) => HabilidadItem.fromJson(e))
            .toList(),
      );
}

class ExperienciaSection extends StatelessWidget {
  const ExperienciaSection({super.key, required this.items, required this.emptyText, required this.onUpdated});
  final List<ExperienciaItem> items;
  final String emptyText;
  final VoidCallback onUpdated;

  String _display(ExperienciaItem e) {
    final ini = e.fechaInicio.length >= 10 ? e.fechaInicio.substring(0,10) : e.fechaInicio;
    final fin = e.fechaFin == null || e.fechaFin!.isEmpty
        ? 'Presente'
        : (e.fechaFin!.length >= 10 ? e.fechaFin!.substring(0,10) : e.fechaFin!);
    return '${e.cargo} en ${e.empresa}\n$ini - $fin';
  }

  Future<void> _pickDate(BuildContext context, TextEditingController controller) async {
    DateTime initial = DateTime.now();
    final txt = controller.text.trim();
    if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(txt)) {
      try { initial = DateTime.parse(txt); } catch (_) {}
    }
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1950, 1, 1),
      lastDate: DateTime(2100, 12, 31),
    );
    if (picked != null) controller.text = _fmtDate(picked);
  }

  String _fmtDate(DateTime d) => '${d.year.toString().padLeft(4,'0')}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}'
  ;

  void _openEditSelection(BuildContext context) async {
    if (items.isEmpty) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Editar Experiencias'),
          content: Text('No hay elementos en "Experiencias" todavía.'),
          actions: [
            SimpleButton(
              title: 'Cerrar',
              backgroundColor: Colors.blueGrey,
              textColor: Colors.white,
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      );
      return;
    }
    final idx = await showDialog<int>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Selecciona una experiencia'),
        content: SizedBox(
          width: 480,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: items.length,
            itemBuilder: (ctx, i) => ListTile(
              title: Text(_display(items[i])),
              onTap: () => Navigator.pop(ctx, i),
            ),
          ),
        ),
        actions: [
          SimpleButton(
            title: 'Cancelar',
            icon: Icons.close_outlined,
            backgroundColor: Colors.blueGrey,
            textColor: Colors.white,
            onTap: () => Navigator.pop(context),
          ),
        ],
      ),
    );
    if (idx != null) _openEditForm(context, items[idx]);
  }

  void _openEditForm(BuildContext context, ExperienciaItem item) {
    final formKey = GlobalKey<FormState>();
    final cargoCtrl = TextEditingController(text: item.cargo);
    final empresaCtrl = TextEditingController(text: item.empresa);
    final inicioCtrl = TextEditingController(text: item.fechaInicio.substring(0,10));
    final finCtrl = TextEditingController(text: (item.fechaFin ?? '').isNotEmpty ? item.fechaFin!.substring(0,10) : '');
    final descripcionCtrl = TextEditingController(text: item.descripcion ?? '');

    List<HabilidadOption> selectedHabOptions = [];
    final initialHabIds = item.habilidadesDesarrolladas.map((h) => h.idHabilidad).toList();

    showDialog(
      context: context,
      builder: (dialogCtx) {
        bool saving = false;
        return StatefulBuilder(
          builder: (ctx, setState) => AlertDialog(
            title: const Text('Editar Experiencia'),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    StyledTextFormField(
                      title: 'Cargo',
                      controller: cargoCtrl,
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Cargo requerido' : null,
                    ),
                    StyledTextFormField(
                      title: 'Empresa',
                      controller: empresaCtrl,
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Empresa requerida' : null,
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: StyledTextFormField(
                            title: 'Fecha inicio (YYYY-MM-DD)',
                            controller: inicioCtrl,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'Requerida';
                              if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(v)) return 'Formato inválido';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          tooltip: 'Seleccionar fecha',
                          icon: const Icon(Icons.calendar_today_outlined),
                          onPressed: () => _pickDate(context, inicioCtrl),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: StyledTextFormField(
                            title: 'Fecha fin (opcional)',
                            controller: finCtrl,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return null;
                              if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(v)) return 'Formato inválido';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          tooltip: 'Seleccionar fecha',
                          icon: const Icon(Icons.calendar_today_outlined),
                          onPressed: () => _pickDate(context, finCtrl),
                        ),
                      ],
                    ),
                    StyledTextFormField(
                      title: 'Descripción (opcional)',
                      controller: descripcionCtrl,
                      validator: (v) {
                        if (v == null || v.isEmpty) return null;
                        if (v.length > 1990) return 'Máximo 1990 caracteres';
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),
                    HabilidadesMultiDropdown(
                      label: 'Habilidades desarrolladas (opcional)',
                      initialSelectedIds: initialHabIds,
                      authToken: Provider.of<UserDataProvider>(context, listen: false).idToken,
                      onChanged: (opts) { selectedHabOptions = opts; },
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              
              SimpleButton(
                title: saving ? 'Eliminando...' : 'Eliminar',
                icon: Icons.delete_outline,
                backgroundColor: Colors.redAccent,
                textColor: Colors.white,
                onTap: saving
                    ? null
                    : () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text('Confirmar eliminación'),
                            content: const Text('¿Eliminar esta experiencia? Esta acción no se puede deshacer.'),
                            actions: [
                              SimpleButton(onTap: () => Navigator.pop(_, true), title: ('Eliminar'), backgroundColor: Colors.redAccent,icon: Icons.delete_outline, textColor: Colors.white,),
                              SimpleButton(onTap: () => Navigator.pop(_, false), title: ('Cancelar'), backgroundColor: Colors.blueGrey,icon: Icons.close_outlined, textColor: Colors.white,),
                            ],
                          ),
                        );
                        if (confirm != true) return;
                        setState(() => saving = true);
                        try {
                          final provider = Provider.of<UserDataProvider>(context, listen: false);
                          final uri = Uri.parse('http://localhost:3000/api/alumnos/experiencia/eliminar');
                          final payload = jsonEncode({
                            'id_experiencia': item.idExperiencia,
                            'id_alumno': item.idAlumno,
                          });
                          final resp = await http.delete(
                            uri,
                            headers: {
                              'Content-Type': 'application/json',
                              if (provider.idToken != null) 'Authorization': 'Bearer ${provider.idToken}',
                            },
                            body: payload,
                          );
                          if (resp.statusCode >= 200 && resp.statusCode < 300) {
                            Navigator.pop(dialogCtx);
                            onUpdated();
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Experiencia eliminada')));
                          } else {
                            setState(() => saving = false);
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error ${resp.statusCode} al eliminar')));
                          }
                        } catch (e) {
                          setState(() => saving = false);
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Excepción: $e')));
                        }
                      },
              ),
              SimpleButton(
                title: 'Cancelar',
                icon: Icons.close_outlined,
                backgroundColor: Colors.blueGrey,
                textColor: Colors.white,
                onTap: () => Navigator.pop(dialogCtx),
              ),
              SimpleButton(
                title: saving ? 'Guardando...' : 'Guardar',
                icon: Icons.save_outlined,
                onTap: saving
                    ? null
                    : () async {
                        if (!formKey.currentState!.validate()) return;
                        // Validaciones extra orden fechas si fin existe
                        if (finCtrl.text.trim().isNotEmpty) {
                          final ini = DateTime.tryParse(inicioCtrl.text.trim());
                          final fin = DateTime.tryParse(finCtrl.text.trim());
                          if (ini == null || fin == null) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fechas inválidas')));
                            return;
                          }
                          if (fin.isBefore(ini)) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fin antes de inicio')));
                            return;
                          }
                        }
                        setState(() => saving = true);
                        try {
                          final provider = Provider.of<UserDataProvider>(context, listen: false);
                          final uri = Uri.parse('http://localhost:3000/api/alumnos/experiencia/actualizar');
                          final habs = selectedHabOptions.isEmpty
                              ? <Map<String, dynamic>>[]
                              : selectedHabOptions.map((h) => {'id_habilidad': h.id}).toList();
                          final Map<String, dynamic> payload = {
                            'id_experiencia': item.idExperiencia,
                            'id_alumno': item.idAlumno,
                            'cargo': cargoCtrl.text.trim(),
                            'empresa': empresaCtrl.text.trim(),
                            'fecha_inicio': inicioCtrl.text.trim(),
                            'habilidades_desarrolladas': habs,
                          };
                          final finTxt = finCtrl.text.trim();
                          if (finTxt.isNotEmpty) payload['fecha_fin'] = finTxt;
                          final descTxt = descripcionCtrl.text.trim();
                          if (descTxt.isNotEmpty) payload['descripcion'] = descTxt;

                          final resp = await http.put(
                            uri,
                            headers: {
                              'Content-Type': 'application/json',
                              if (provider.idToken != null) 'Authorization': 'Bearer ${provider.idToken}',
                            },
                            body: jsonEncode(payload),
                          );
                          if (resp.statusCode == 200) {
                            Navigator.pop(dialogCtx);
                            onUpdated();
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Experiencia actualizada')));
                          } else {
                            setState(() => saving = false);
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error ${resp.statusCode} al actualizar')));
                          }
                        } catch (e) {
                          setState(() => saving = false);
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Excepción: $e')));
                        }
                      },
              ),
            ],
          ),
        );
      },
    );
  }

  void _openAddForm(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final cargoCtrl = TextEditingController();
    final empresaCtrl = TextEditingController();
    final inicioCtrl = TextEditingController();
    final finCtrl = TextEditingController();
    final descripcionCtrl = TextEditingController();

    List<HabilidadOption> selectedHabOptions = [];

    showDialog(
      context: context,
      builder: (dialogCtx) {
        bool saving = false;
        return StatefulBuilder(
          builder: (ctx, setState) => AlertDialog(
            title: const Text('Agregar Experiencia'),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    StyledTextFormField(
                      title: 'Cargo',
                      controller: cargoCtrl,
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Cargo requerido' : null,
                    ),
                    StyledTextFormField(
                      title: 'Empresa',
                      controller: empresaCtrl,
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Empresa requerida' : null,
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: StyledTextFormField(
                            title: 'Fecha inicio (YYYY-MM-DD)',
                            controller: inicioCtrl,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'Requerida';
                              if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(v)) return 'Formato inválido';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          tooltip: 'Seleccionar fecha',
                          icon: const Icon(Icons.calendar_today_outlined),
                          onPressed: () => _pickDate(context, inicioCtrl),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: StyledTextFormField(
                            title: 'Fecha fin (opcional)',
                            controller: finCtrl,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return null;
                              if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(v)) return 'Formato inválido';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          tooltip: 'Seleccionar fecha',
                          icon: const Icon(Icons.calendar_today_outlined),
                          onPressed: () => _pickDate(context, finCtrl),
                        ),
                      ],
                    ),
                    StyledTextFormField(
                      title: 'Descripción (opcional)',
                      controller: descripcionCtrl,
                      validator: (v) {
                        if (v == null || v.isEmpty) return null;
                        if (v.length > 1990) return 'Máximo 1990 caracteres';
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),
                    HabilidadesMultiDropdown(
                      label: 'Habilidades desarrolladas (opcional)',
                      initialSelectedIds: const [],
                      authToken: Provider.of<UserDataProvider>(context, listen: false).idToken,
                      onChanged: (opts) { selectedHabOptions = opts; },
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              SimpleButton(
                title: 'Cancelar',
                icon: Icons.close_outlined,
                backgroundColor: Colors.blueGrey,
                textColor: Colors.white,
                onTap: () => Navigator.pop(dialogCtx),
              ),
              SimpleButton(
                title: saving ? 'Guardando...' : 'Agregar',
                icon: Icons.add,
                onTap: saving
                    ? null
                    : () async {
                        if (!formKey.currentState!.validate()) return;
                        if (finCtrl.text.trim().isNotEmpty) {
                          final ini = DateTime.tryParse(inicioCtrl.text.trim());
                          final fin = DateTime.tryParse(finCtrl.text.trim());
                          if (ini == null || fin == null) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fechas inválidas')));
                            return;
                          }
                          if (fin.isBefore(ini)) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fin antes de inicio')));
                            return;
                          }
                        }
                        setState(() => saving = true);
                        try {
                          final provider = Provider.of<UserDataProvider>(context, listen: false);
                          final idAlumno = provider.idRol;
                          if (idAlumno == null) {
                            setState(() => saving = false);
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No se encontró id_alumno')));
                            return;
                          }
                          final uri = Uri.parse('http://localhost:3000/api/alumnos/experiencia/agregar');
                          final habs = selectedHabOptions.isEmpty
                              ? <Map<String, dynamic>>[]
                              : selectedHabOptions.map((h) => {'id_habilidad': h.id}).toList();
                          final Map<String, dynamic> payload = {
                            'id_alumno': idAlumno,
                            'cargo': cargoCtrl.text.trim(),
                            'empresa': empresaCtrl.text.trim(),
                            'fecha_inicio': inicioCtrl.text.trim(),
                            'habilidades_desarrolladas': habs,
                          };
                          final finTxt = finCtrl.text.trim();
                          if (finTxt.isNotEmpty) payload['fecha_fin'] = finTxt;
                          final descTxt = descripcionCtrl.text.trim();
                          if (descTxt.isNotEmpty) payload['descripcion'] = descTxt;

                          final resp = await http.post(
                            uri,
                            headers: {
                              'Content-Type': 'application/json',
                              if (provider.idToken != null) 'Authorization': 'Bearer ${provider.idToken}',
                            },
                            body: jsonEncode(payload),
                          );
                          if (resp.statusCode >= 200 && resp.statusCode < 300) {
                            Navigator.pop(dialogCtx);
                            onUpdated();
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Experiencia agregada')));
                          } else {
                            setState(() => saving = false);
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error ${resp.statusCode} al agregar')));
                          }
                        } catch (e) {
                          setState(() => saving = false);
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Excepción: $e')));
                        }
                      },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(
            width: 190,
            child: Text('Experiencia Laboral:', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
          Expanded(
            child: Text(emptyText, style: const TextStyle(color: Colors.black54)),
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Editar',
            icon: const Icon(Icons.edit_outlined, size: 18, color: Colors.black54),
            onPressed: () => _openEditSelection(context),
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Agregar',
            icon: const Icon(Icons.add, size: 18, color: Colors.black54),
            onPressed: () => _openAddForm(context),
          ),
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(
          width: 190,
          child: Text('Experiencia Laboral:', style: TextStyle(fontWeight: FontWeight.w700)),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final c in items)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(_display(c)),
                ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          tooltip: 'Editar lista',
          icon: const Icon(Icons.edit_outlined, size: 18, color: Colors.black54),
          onPressed: () => _openEditSelection(context),
        ),
        const SizedBox(width: 8),
        IconButton(
          tooltip: 'Agregar',
          icon: const Icon(Icons.add, size: 18, color: Colors.black54),
          onPressed: () => _openAddForm(context),
        ),
      ],
    );
  }
}