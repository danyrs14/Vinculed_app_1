import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:vinculed_app_1/src/core/providers/user_provider.dart';
import 'package:vinculed_app_1/src/ui/widgets/buttons/simple_buttons.dart';
import 'package:vinculed_app_1/src/ui/widgets/text_inputs/text_form_field.dart';
import 'package:vinculed_app_1/src/ui/widgets/text_inputs/dropdown.dart';

class EscolaridadItem {
  final int idEscolaridad;
  final int idAlumno;
  final String nivel;
  final String institucion;
  final String? carrera;
  final String plantel;
  final String nota;
  final int fechaInicio;
  final int fechaFin;
  EscolaridadItem({
    required this.idEscolaridad,
    required this.idAlumno,
    required this.nivel,
    required this.institucion,
    required this.carrera,
    required this.plantel,
    required this.nota,
    required this.fechaInicio,
    required this.fechaFin,
  });
  factory EscolaridadItem.fromJson(Map<String, dynamic> j) => EscolaridadItem(
        idEscolaridad: j['id_escolaridad'] ?? 0,
        idAlumno: j['id_alumno'] ?? 0,
        nivel: j['nivel'],
        institucion: j['institucion'],
        carrera: j['carrera'],
        plantel: j['plantel'],
        nota: j['nota'],
        fechaInicio: j['fecha_inicio'],
        fechaFin: j['fecha_fin'],
      );
}

class EscolaridadSection extends StatelessWidget {
  const EscolaridadSection({super.key, required this.items, required this.emptyText, required this.onUpdated});
  final List<EscolaridadItem> items;
  final String emptyText;
  final VoidCallback onUpdated;

  String _display(EscolaridadItem e) => '${e.carrera != null && e.carrera!.trim().isNotEmpty ? e.carrera : e.nivel} - Plantel: ${e.plantel}, ${e.institucion}. Generación: ${e.fechaInicio} - ${e.fechaFin}. ${e.nota}';

  Future<void> _pickYear(BuildContext context, TextEditingController controller) async {
    final now = DateTime.now();
    final initialYear = int.tryParse(controller.text) ?? now.year;
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(initialYear, 1, 1),
      firstDate: DateTime(1950, 1, 1),
      lastDate: DateTime(2100, 12, 31),
      initialDatePickerMode: DatePickerMode.year,
    );
    if (picked != null) {
      controller.text = picked.year.toString();
    }
  }

  void _openEditSelection(BuildContext context) async {
    if (items.isEmpty) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Editar Escolaridad'),
          content: Text('No hay elementos en "Escolaridad" todavía.'),
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
    final selectedIndex = await showDialog<int>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Selecciona un elemento de Escolaridad'),
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
    if (selectedIndex != null) {
      _openEditForm(context, items[selectedIndex]);
    }
  }

  void _openEditForm(BuildContext context, EscolaridadItem item) {
    final formKey = GlobalKey<FormState>();
    final nivelOptions = const [
      'Bachillerato General',
      'Tecnólogo',
      'Bachillerato Tecnológico',
      'Profesional Técnico',
      'Técnico Superior Universitario',
      'Licenciatura',
    ];
    final notaOptions = const [
      'Pasante',
      'Titulado',
      'Egresado',
      'Cursando',
      'Trunca',
    ];

    String? nivelValue = item.nivel;
    String? notaValue = item.nota;
    final institucionCtrl = TextEditingController(text: item.institucion);
    final carreraCtrl = TextEditingController(text: item.carrera ?? '');
    final plantelCtrl = TextEditingController(text: item.plantel);
    final inicioCtrl = TextEditingController(text: item.fechaInicio.toString());
    final finCtrl = TextEditingController(text: item.fechaFin.toString());

    showDialog(
      context: context,
      builder: (dialogCtx) {
        bool saving = false;
        return StatefulBuilder(
          builder: (ctx, setState) => AlertDialog(
            title: const Text('Editar Escolaridad'),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DropdownInput<String>(
                      title: 'Nivel',
                      required: true,
                      value: nivelValue,
                      items: nivelOptions
                          .map((e) => DropdownMenuItem<String>(value: e, child: Text(e)))
                          .toList(),
                      onChanged: (v) => setState(() => nivelValue = v),
                      validator: (v) => (v == null || v.isEmpty) ? 'Selecciona el nivel' : null,
                    ),
                    StyledTextFormField(
                      title: 'Institución',
                      controller: institucionCtrl,
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Institución requerida' : null,
                    ),
                    StyledTextFormField(
                      title: 'Carrera (opcional)',
                      controller: carreraCtrl,
                    ),
                    StyledTextFormField(
                      title: 'Plantel',
                      controller: plantelCtrl,
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Plantel requerido' : null,
                    ),
                    DropdownInput<String>(
                      title: 'Nota',
                      required: true,
                      value: notaValue,
                      items: notaOptions
                          .map((e) => DropdownMenuItem<String>(value: e, child: Text(e)))
                          .toList(),
                      onChanged: (v) => setState(() => notaValue = v),
                      validator: (v) => (v == null || v.isEmpty) ? 'Selecciona la nota' : null,
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: StyledTextFormField(
                            title: 'Año inicio',
                            controller: inicioCtrl,
                            keyboardType: TextInputType.number,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'Año de inicio requerido';
                              final yr = int.tryParse(v);
                              if (yr == null || v.length != 4) return 'Año inválido';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          tooltip: 'Seleccionar año',
                          icon: const Icon(Icons.calendar_today_outlined),
                          onPressed: () => _pickYear(context, inicioCtrl),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: StyledTextFormField(
                            title: 'Año fin',
                            controller: finCtrl,
                            keyboardType: TextInputType.number,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'Año de fin requerido';
                              final yr = int.tryParse(v);
                              if (yr == null || v.length != 4) return 'Año inválido';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          tooltip: 'Seleccionar año',
                          icon: const Icon(Icons.calendar_today_outlined),
                          onPressed: () => _pickYear(context, finCtrl),
                        ),
                      ],
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
                        // Confirmación rápida
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text('Confirmar eliminación'),
                            content: const Text('¿Eliminar este registro de escolaridad? Esta acción no se puede deshacer.'),
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
                          final uri = Uri.parse('https://oda-talent-back-81413836179.us-central1.run.app/api/alumnos/escolaridad/eliminar');
                          final body = jsonEncode({
                            'id_escolaridad': item.idEscolaridad,
                            'id_alumno': item.idAlumno,
                          });
                          final headers = await provider.getAuthHeaders();
                          final resp = await http.delete(
                            uri,
                            headers: headers,
                            body: body,
                          );
                          if (resp.statusCode >= 200 && resp.statusCode < 300) {
                            Navigator.pop(dialogCtx);
                            onUpdated();
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Escolaridad eliminada')));
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
                        // Validación adicional de rango de años
                        final ini = int.parse(inicioCtrl.text);
                        final fin = int.parse(finCtrl.text);
                        if (fin < ini) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('El año de fin no puede ser menor al de inicio')),
                          );
                          return;
                        }
                        setState(() => saving = true);
                        try {
                          final provider = Provider.of<UserDataProvider>(context, listen: false);
                          final uri = Uri.parse('https://oda-talent-back-81413836179.us-central1.run.app/api/alumnos/escolaridad/actualizar');
                          final body = jsonEncode({
                            'id_escolaridad': item.idEscolaridad,
                            'id_alumno': item.idAlumno,
                            'nivel': nivelValue,
                            'institucion': institucionCtrl.text.trim(),
                            'carrera': carreraCtrl.text.trim().isEmpty ? null : carreraCtrl.text.trim(),
                            'plantel': plantelCtrl.text.trim(),
                            'nota': notaValue,
                            'fecha_inicio': inicioCtrl.text.trim(),
                            'fecha_fin': finCtrl.text.trim(),
                          });
                          final headers = await provider.getAuthHeaders();
                          final resp = await http.put(
                            uri,
                            headers: headers,
                            body: body,
                          );
                          if (resp.statusCode == 200) {
                            Navigator.pop(dialogCtx); // close dialog
                            onUpdated(); // reload profile
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Escolaridad actualizada correctamente')),
                            );
                          } else {
                            setState(() => saving = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error ${resp.statusCode} al actualizar')),
                            );
                          }
                        } catch (e) {
                          setState(() => saving = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Excepción: $e')),
                          );
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
    final nivelOptions = const [
      'Bachillerato General',
      'Tecnólogo',
      'Bachillerato Tecnológico',
      'Profesional Técnico',
      'Técnico Superior Universitario',
      'Licenciatura',
    ];
    final notaOptions = const [
      'Pasante',
      'Titulado',
      'Egresado',
      'Cursando',
      'Trunca',
    ];

    String? nivelValue;
    String? notaValue;
    final institucionCtrl = TextEditingController();
    final carreraCtrl = TextEditingController();
    final plantelCtrl = TextEditingController();
    final inicioCtrl = TextEditingController();
    final finCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogCtx) {
        bool saving = false;
        return StatefulBuilder(
          builder: (ctx, setState) => AlertDialog(
            title: const Text('Agregar Escolaridad'),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DropdownInput<String>(
                      title: 'Nivel',
                      required: true,
                      value: nivelValue,
                      items: nivelOptions.map((e) => DropdownMenuItem<String>(value: e, child: Text(e))).toList(),
                      onChanged: (v) => setState(() => nivelValue = v),
                      validator: (v) => (v == null || v.isEmpty) ? 'Selecciona el nivel' : null,
                    ),
                    StyledTextFormField(
                      title: 'Institución',
                      controller: institucionCtrl,
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Institución requerida' : null,
                    ),
                    StyledTextFormField(
                      title: 'Carrera (opcional)',
                      controller: carreraCtrl,
                    ),
                    StyledTextFormField(
                      title: 'Plantel',
                      controller: plantelCtrl,
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Plantel requerido' : null,
                    ),
                    DropdownInput<String>(
                      title: 'Nota',
                      required: true,
                      value: notaValue,
                      items: notaOptions.map((e) => DropdownMenuItem<String>(value: e, child: Text(e))).toList(),
                      onChanged: (v) => setState(() => notaValue = v),
                      validator: (v) => (v == null || v.isEmpty) ? 'Selecciona la nota' : null,
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: StyledTextFormField(
                            title: 'Año inicio',
                            controller: inicioCtrl,
                            keyboardType: TextInputType.number,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'Año de inicio requerido';
                              final yr = int.tryParse(v);
                              if (yr == null || v.length != 4) return 'Año inválido';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          tooltip: 'Seleccionar año',
                          icon: const Icon(Icons.calendar_today_outlined),
                          onPressed: () => _pickYear(context, inicioCtrl),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: StyledTextFormField(
                            title: 'Año fin',
                            controller: finCtrl,
                            keyboardType: TextInputType.number,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'Año de fin requerido';
                              final yr = int.tryParse(v);
                              if (yr == null || v.length != 4) return 'Año inválido';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          tooltip: 'Seleccionar año',
                          icon: const Icon(Icons.calendar_today_outlined),
                          onPressed: () => _pickYear(context, finCtrl),
                        ),
                      ],
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
                        final ini = int.parse(inicioCtrl.text);
                        final fin = int.parse(finCtrl.text);
                        if (fin < ini) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('El año de fin no puede ser menor al de inicio')),
                          );
                          return;
                        }
                        setState(() => saving = true);
                        try {
                          final provider = Provider.of<UserDataProvider>(context, listen: false);
                          final idAlumno = provider.idRol;
                          if (idAlumno == null) {
                            setState(() => saving = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('No se encontró id_alumno')),
                            );
                            return;
                          }
                          final uri = Uri.parse('https://oda-talent-back-81413836179.us-central1.run.app/api/alumnos/escolaridad/agregar');
                          final body = jsonEncode({
                            'id_alumno': idAlumno,
                            'nivel': nivelValue,
                            'institucion': institucionCtrl.text.trim(),
                            'carrera': carreraCtrl.text.trim().isEmpty ? null : carreraCtrl.text.trim(),
                            'plantel': plantelCtrl.text.trim(),
                            'nota': notaValue,
                            'fecha_inicio': inicioCtrl.text.trim(),
                            'fecha_fin': finCtrl.text.trim(),
                          });
                          final headers = await provider.getAuthHeaders();
                          final resp = await http.post(
                            uri,
                            headers: headers,
                            body: body,
                          );
                          if (resp.statusCode >= 200 && resp.statusCode < 300) {
                            Navigator.pop(dialogCtx);
                            onUpdated();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Escolaridad agregada correctamente')),
                            );
                          } else {
                            setState(() => saving = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error ${resp.statusCode} al agregar')),
                            );
                          }
                        } catch (e) {
                          setState(() => saving = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Excepción: $e')),
                          );
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
            width: 182,
            child: Text('Escolaridad:', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 8),
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
          child: Text('Escolaridad:', style: TextStyle(fontWeight: FontWeight.w700)),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final e in items)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(_display(e)),
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