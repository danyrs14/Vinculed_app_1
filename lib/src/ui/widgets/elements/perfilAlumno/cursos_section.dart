import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:vinculed_app_1/src/core/providers/user_provider.dart';
import 'package:vinculed_app_1/src/ui/widgets/buttons/simple_buttons.dart';
import 'package:vinculed_app_1/src/ui/widgets/text_inputs/text_form_field.dart';

class CursoItem {
  final int idCurso;
  final int idAlumno;
  final String nombre;
  final String institucion;
  final String fechaInicio;
  final String fechaFin;
  CursoItem({
    required this.idCurso,
    required this.idAlumno,
    required this.nombre,
    required this.institucion,
    required this.fechaInicio,
    required this.fechaFin,
  });
  factory CursoItem.fromJson(Map<String, dynamic> j) => CursoItem(
        idCurso: j['id_curso'] ?? 0,
        idAlumno: j['id_alumno'] ?? 0,
        nombre: j['nombre'],
        institucion: j['institucion'],
        fechaInicio: j['fecha_inicio'],
        fechaFin: j['fecha_fin'],
      );
}

class CursosSection extends StatelessWidget {
  const CursosSection({super.key, required this.items, required this.emptyText, required this.onUpdated, this.readOnly = false});
  final List<CursoItem> items;
  final String emptyText;
  final VoidCallback onUpdated;
  final bool readOnly;

  String _display(CursoItem c) => '${c.nombre}\n${c.institucion}. ${c.fechaInicio.substring(0, 10)} - ${c.fechaFin.substring(0, 10)}';

  Future<void> _pickDate(BuildContext context, TextEditingController controller) async {
    DateTime initial = DateTime.now();
    final txt = controller.text.trim();
    if (RegExp(r'^\d{4}-\d{2}-\d{2}').hasMatch(txt)) {
      try {
        initial = DateTime.parse(txt);
      } catch (_) {}
    }
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1950, 1, 1),
      lastDate: DateTime(2100, 12, 31),
    );
    if (picked != null) {
      controller.text = _fmtDate(picked);
    }
  }

  String _fmtDate(DateTime d) => '${d.year.toString().padLeft(4,'0')}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}'
  ;

  void _openEditSelection(BuildContext context) async {
    if (items.isEmpty) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Editar Cursos'),
          content: Text('No hay elementos en "Cursos" todavía.'),
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
        title: const Text('Selecciona un curso'),
        content: SizedBox(
          width: 460,
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

  void _openViewSelection(BuildContext context) async {
    if (items.isEmpty) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Visualizar Cursos'),
          content: const Text('No hay elementos en "Cursos" todavía.'),
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
        title: const Text('Selecciona un curso'),
        content: SizedBox(
          width: 460,
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
            title: 'Cerrar',
            backgroundColor: Colors.blueGrey,
            textColor: Colors.white,
            onTap: () => Navigator.pop(context),
          ),
        ],
      ),
    );
    if (idx != null) _openViewDetails(context, items[idx]);
  }

  void _openViewDetails(BuildContext context, CursoItem c) {
    Widget row(String k, String v) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 130, child: Text('$k:', style: const TextStyle(fontWeight: FontWeight.w700))),
          const SizedBox(width: 8),
          Expanded(child: Text(v.isEmpty ? '-' : v)),
        ],
      ),
    );

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Detalle de Curso'),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              row('Nombre', c.nombre),
              row('Institución', c.institucion),
              row('Inicio', c.fechaInicio.substring(0,10)),
              row('Fin', c.fechaFin.substring(0,10)),
            ],
          ),
        ),
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
  }

  void _openEditForm(BuildContext context, CursoItem item) {
    final formKey = GlobalKey<FormState>();
    final nombreCtrl = TextEditingController(text: item.nombre);
    final institucionCtrl = TextEditingController(text: item.institucion);
    final inicioCtrl = TextEditingController(text: item.fechaInicio.substring(0,10));
    final finCtrl = TextEditingController(text: item.fechaFin.substring(0,10));

    showDialog(
      context: context,
      builder: (dialogCtx) {
        bool saving = false;
        return StatefulBuilder(
          builder: (ctx, setState) => AlertDialog(
            title: const Text('Editar Curso'),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    StyledTextFormField(
                      isRequired: true,
                      title: 'Nombre',
                      controller: nombreCtrl,
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Nombre requerido' : null,
                    ),
                    StyledTextFormField(
                      isRequired: true,
                      title: 'Institución',
                      controller: institucionCtrl,
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Institución requerida' : null,
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: StyledTextFormField(
                            isRequired: true,
                            title: 'Fecha inicio (YYYY-MM-DD)',
                            controller: inicioCtrl,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'Requerido';
                              if (!RegExp(r'^\d{4}-\d{2}-\d{2}').hasMatch(v)) return 'Formato inválido';
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
                            isRequired: true,
                            title: 'Fecha fin (YYYY-MM-DD)',
                            controller: finCtrl,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'Requerido';
                              if (!RegExp(r'^\d{4}-\d{2}-\d{2}').hasMatch(v)) return 'Formato inválido';
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
                  ],
                ),
              ),
            ),
            actions: (() {
              final isMobile = MediaQuery.of(ctx).size.width < 700;
              final buttons = <Widget>[
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
                              content: const Text('¿Eliminar este curso? Esta acción no se puede deshacer.'),
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
                            final uri = Uri.parse('https://oda-talent-back-81413836179.us-central1.run.app/api/alumnos/curso/eliminar');
                            final payload = jsonEncode({
                              'id_curso': item.idCurso,
                              'id_alumno': item.idAlumno,
                            });
                            final headers = await provider.getAuthHeaders();
                            final resp = await http.delete(
                              uri,
                              headers: headers,
                              body: payload,
                            );
                            if (resp.statusCode >= 200 && resp.statusCode < 300) {
                              Navigator.pop(dialogCtx);
                              onUpdated();
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Curso eliminado')));
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
                          final ini = DateTime.tryParse(inicioCtrl.text);
                          final fin = DateTime.tryParse(finCtrl.text);
                          if (ini == null || fin == null) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fechas inválidas')));
                            return;
                          }
                          if (fin.isBefore(ini)) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fecha fin antes de inicio')));
                            return;
                          }
                          setState(() => saving = true);
                          try {
                            final provider = Provider.of<UserDataProvider>(context, listen: false);
                            final uri = Uri.parse('https://oda-talent-back-81413836179.us-central1.run.app/api/alumnos/curso/actualizar');
                            final body = jsonEncode({
                              'id_curso': item.idCurso,
                              'id_alumno': item.idAlumno,
                              'nombre': nombreCtrl.text.trim(),
                              'institucion': institucionCtrl.text.trim(),
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
                              Navigator.pop(dialogCtx);
                              onUpdated();
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Curso actualizado')));
                            } else {
                              setState(() => saving = false);
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error ${resp.statusCode}')));
                            }
                          } catch (e) {
                            setState(() => saving = false);
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Excepción: $e')));
                          }
                        },
                ),
              ];
              if (isMobile) {
                return [
                  Center(
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 12,
                      runSpacing: 8,
                      children: buttons,
                    ),
                  ),
                ];
              }
              return buttons;
            })(),
          ),
        );
      },
    );
  }

  void _openAddForm(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final nombreCtrl = TextEditingController();
    final institucionCtrl = TextEditingController();
    final inicioCtrl = TextEditingController();
    final finCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogCtx) {
        bool saving = false;
        return StatefulBuilder(
          builder: (ctx, setState) => AlertDialog(
            title: const Text('Agregar Curso'),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    StyledTextFormField(
                      isRequired: true,
                      title: 'Nombre',
                      controller: nombreCtrl,
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Nombre requerido' : null,
                    ),
                    StyledTextFormField(
                      isRequired: true,
                      title: 'Institución',
                      controller: institucionCtrl,
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Institución requerida' : null,
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: StyledTextFormField(
                            isRequired: true,
                            title: 'Fecha inicio (YYYY-MM-DD)',
                            controller: inicioCtrl,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'Requerida';
                              if (!RegExp(r'^\\d{4}-\\d{2}-\\d{2}').hasMatch(v)) return 'Formato inválido';
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
                            isRequired: true,
                            title: 'Fecha fin (YYYY-MM-DD)',
                            controller: finCtrl,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'Requerida';
                              if (!RegExp(r'^\\d{4}-\\d{2}-\\d{2}').hasMatch(v)) return 'Formato inválido';
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
                  ],
                ),
              ),
            ),
            actions: (() {
              final isMobile = MediaQuery.of(ctx).size.width < 700;
              final buttons = <Widget>[
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
                          setState(() => saving = true);
                          try {
                            final provider = Provider.of<UserDataProvider>(context, listen: false);
                            final idAlumno = provider.idRol;
                            if (idAlumno == null) {
                              setState(() => saving = false);
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No se encontró id_alumno')));
                              return;
                            }
                            final uri = Uri.parse('https://oda-talent-back-81413836179.us-central1.run.app/api/alumnos/curso/agregar');
                            final payload = jsonEncode({
                              'id_alumno': idAlumno,
                              'nombre': nombreCtrl.text.trim(),
                              'institucion': institucionCtrl.text.trim(),
                              'fecha_inicio': inicioCtrl.text.trim(),
                              'fecha_fin': finCtrl.text.trim(),
                            });
                            final headers = await provider.getAuthHeaders();
                            final resp = await http.post(
                              uri,
                              headers: headers,
                              body: payload,
                            );
                            if (resp.statusCode >= 200 && resp.statusCode < 300) {
                              Navigator.pop(dialogCtx);
                              onUpdated();
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Curso agregado')));
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
              ];
              if (isMobile) {
                return [
                  Center(
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 12,
                      runSpacing: 8,
                      children: buttons,
                    ),
                  ),
                ];
              }
              return buttons;
            })(),
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
            child: Text('Cursos:', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
          Expanded(
            child: Text(emptyText, style: const TextStyle(color: Colors.black54)),
          ),
          const SizedBox(width: 8),
          if (readOnly)
            IconButton(
              tooltip: 'Visualizar',
              icon: const Icon(Icons.visibility_outlined, size: 18, color: Colors.black54),
              onPressed: () => _openViewSelection(context),
            )
          else ...[
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
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(
          width: 190,
          child: Text('Cursos:', style: TextStyle(fontWeight: FontWeight.w700)),
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
        if (readOnly)
          IconButton(
            tooltip: 'Visualizar',
            icon: const Icon(Icons.visibility_outlined, size: 18, color: Colors.black54),
            onPressed: () => _openViewSelection(context),
          )
        else ...[
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
      ],
    );
  }
}