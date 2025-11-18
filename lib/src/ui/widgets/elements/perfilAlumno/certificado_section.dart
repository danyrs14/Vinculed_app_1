import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:vinculed_app_1/src/core/providers/user_provider.dart';
import 'package:vinculed_app_1/src/ui/widgets/buttons/simple_buttons.dart';
import 'package:vinculed_app_1/src/ui/widgets/text_inputs/text_form_field.dart';
import 'package:vinculed_app_1/src/ui/widgets/text_inputs/habilidades_multi_dropdown.dart';
import 'package:vinculed_app_1/src/ui/widgets/elements/perfilAlumno/habilidad_clase.dart';

class CertificadoItem {
  final int idCertificado;
  final int idAlumno;
  final String nombre;
  final String institucion;
  final String fechaExpedicion;
  final String? fechaCaducidad;
  final String? idCredencial;
  final String? urlCertificado;
  final List<HabilidadItem> habilidadesDesarrolladas;
  CertificadoItem({
    required this.idCertificado,
    required this.idAlumno,
    required this.nombre,
    required this.institucion,
    required this.fechaExpedicion,
    required this.fechaCaducidad,
    required this.idCredencial,
    required this.urlCertificado,
    required this.habilidadesDesarrolladas,
  });
  factory CertificadoItem.fromJson(Map<String, dynamic> j) => CertificadoItem(
        idCertificado: j['id_certificado'] ?? 0,
        idAlumno: j['id_alumno'] ?? 0,
        nombre: j['nombre'],
        institucion: j['institucion'],
        fechaExpedicion: j['fecha_expedicion'],
        fechaCaducidad: j['fecha_caducidad'],
        idCredencial: j['id_credencial'],
        urlCertificado: j['url_certificado'],
        habilidadesDesarrolladas: (j['habilidades_desarrolladas'] as List? ?? [])
            .map((e) => HabilidadItem.fromJson(e))
            .toList(),
      );
}


class CertificadosSection extends StatelessWidget {
  const CertificadosSection({super.key, required this.items, required this.emptyText, required this.onUpdated});
  final List<CertificadoItem> items;
  final String emptyText;
  final VoidCallback onUpdated;

  String _display(CertificadoItem e) {
    final exp = e.fechaExpedicion.length >= 10 ? e.fechaExpedicion.substring(0,10) : e.fechaExpedicion;
    final cad = (e.fechaCaducidad != null && e.fechaCaducidad!.isNotEmpty)
        ? (e.fechaCaducidad!.length >= 10 ? e.fechaCaducidad!.substring(0,10) : e.fechaCaducidad!)
        : null;
    final cadTxt = cad != null ? 'Caducidad: $cad' : 'Sin caducidad';
    return '${e.nombre}\n${e.institucion}.  Expedición: $exp. $cadTxt';
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
    if (picked != null) {
      controller.text = _fmtDate(picked);
    }
  }

  String _fmtDate(DateTime d) => '${d.year.toString().padLeft(4,'0')}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';

  bool _isValidUrl(String v) {
    final uri = Uri.tryParse(v);
    return uri != null && (uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https')) && uri.host.isNotEmpty;
  }

  void _openEditSelection(BuildContext context) async {
    if (items.isEmpty) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Editar Certificados'),
          content: Text('No hay elementos en "Certificados" todavía.'),
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
        title: const Text('Selecciona un certificado'),
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

  void _openEditForm(BuildContext context, CertificadoItem item) {
    final formKey = GlobalKey<FormState>();
    final nombreCtrl = TextEditingController(text: item.nombre);
    final institucionCtrl = TextEditingController(text: item.institucion);
    final expedicionCtrl = TextEditingController(text: item.fechaExpedicion.substring(0,10));
    final caducidadCtrl = TextEditingController(text: (item.fechaCaducidad ?? '').isNotEmpty ? item.fechaCaducidad!.substring(0,10) : '');
    final credencialCtrl = TextEditingController(text: item.idCredencial ?? '');
    final urlCtrl = TextEditingController(text: item.urlCertificado ?? '');

    List<HabilidadOption> selectedHabOptions = [];
    final initialHabIds = item.habilidadesDesarrolladas.map((h) => h.idHabilidad).toList();

    showDialog(
      context: context,
      builder: (dialogCtx) {
        bool saving = false;
        return StatefulBuilder(
          builder: (ctx, setState) => AlertDialog(
            title: const Text('Editar Certificado'),
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
                            title: 'Fecha expedición (YYYY-MM-DD)',
                            controller: expedicionCtrl,
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
                          onPressed: () => _pickDate(context, expedicionCtrl),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: StyledTextFormField(
                            isRequired: false,
                            title: 'Fecha caducidad (opcional)',
                            controller: caducidadCtrl,
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
                          onPressed: () => _pickDate(context, caducidadCtrl),
                        ),
                      ],
                    ),
                    StyledTextFormField(
                      isRequired: false,
                      title: 'ID credencial (opcional)',
                      controller: credencialCtrl,
                    ),
                    StyledTextFormField(
                      isRequired: false,
                      title: 'URL certificado (opcional)',
                      controller: urlCtrl,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return null;
                        return _isValidUrl(v.trim()) ? null : 'Ingresa una URL válida (http/https)';
                      },
                    ),
                    const SizedBox(height: 8),
                    HabilidadesMultiDropdown(
                      label: 'Habilidades desarrolladas (opcional)'
                          ,
                      initialSelectedIds: initialHabIds,
                      onChanged: (opts) {
                        selectedHabOptions = opts;
                      },
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
                            content: const Text('¿Eliminar este certificado? Esta acción no se puede deshacer.'),
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
                          final uri = Uri.parse('https://oda-talent-back-81413836179.us-central1.run.app/api/alumnos/certificado/eliminar');
                          final payload = jsonEncode({
                            'id_certificado': item.idCertificado,
                            'id_alumno': item.idAlumno,
                          });
                          final headers = await context.read<UserDataProvider>().getAuthHeaders();
                          final resp = await http.delete(
                            uri,
                            headers: headers,
                            body: payload,
                          );
                          if (resp.statusCode >= 200 && resp.statusCode < 300) {
                            Navigator.pop(dialogCtx);
                            onUpdated();
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Certificado eliminado')));
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
                        // Validaciones extra entre fechas
                        if (caducidadCtrl.text.trim().isNotEmpty) {
                          final exp = DateTime.tryParse(expedicionCtrl.text.trim());
                          final cad = DateTime.tryParse(caducidadCtrl.text.trim());
                          if (exp == null || cad == null) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fechas inválidas')));
                            return;
                          }
                          if (cad.isBefore(exp)) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Caducidad no puede ser antes de expedición')));
                            return;
                          }
                        }
                        setState(() => saving = true);
                        try {
                          final provider = Provider.of<UserDataProvider>(context, listen: false);
                          final uri = Uri.parse('https://oda-talent-back-81413836179.us-central1.run.app/api/alumnos/certificado/actualizar');
                          final habs = selectedHabOptions.isEmpty
                              ? <Map<String, dynamic>>[]
                              : selectedHabOptions.map((h) => {'id_habilidad': h.id}).toList();
                          final Map<String, dynamic> payload = {
                            'id_certificado': item.idCertificado,
                            'id_alumno': item.idAlumno,
                            'nombre': nombreCtrl.text.trim(),
                            'institucion': institucionCtrl.text.trim(),
                            'fecha_expedicion': expedicionCtrl.text.trim(),
                            'habilidades_desarrolladas': habs,
                          };
                          final cadTxt = caducidadCtrl.text.trim();
                          if (cadTxt.isNotEmpty) payload['fecha_caducidad'] = cadTxt;
                          final cred = credencialCtrl.text.trim();
                          if (cred.isNotEmpty) payload['id_credencial'] = cred;
                          final urlTxt = urlCtrl.text.trim();
                          if (urlTxt.isNotEmpty) payload['url_certificado'] = urlTxt;

                          final headers = await context.read<UserDataProvider>().getAuthHeaders();
                          final resp = await http.put(
                            uri,
                            headers: headers,
                            body: jsonEncode(payload),
                          );
                          if (resp.statusCode == 200) {
                            Navigator.pop(dialogCtx);
                            onUpdated();
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Certificado actualizado')));
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
    final nombreCtrl = TextEditingController();
    final institucionCtrl = TextEditingController();
    final expedicionCtrl = TextEditingController();
    final caducidadCtrl = TextEditingController();
    final idCredCtrl = TextEditingController();
    final urlCtrl = TextEditingController();

    List<HabilidadOption> selectedHabOptions = [];

    showDialog(
      context: context,
      builder: (dialogCtx) {
        bool saving = false;
        return StatefulBuilder(
          builder: (ctx, setState) => AlertDialog(
            title: const Text('Agregar Certificado'),
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
                            title: 'Fecha expedición (YYYY-MM-DD)',
                            controller: expedicionCtrl,
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
                          onPressed: () => _pickDate(context, expedicionCtrl),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: StyledTextFormField(
                            isRequired: false,
                            title: 'Fecha caducidad (opcional)',
                            controller: caducidadCtrl,
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
                          onPressed: () => _pickDate(context, caducidadCtrl),
                        ),
                      ],
                    ),
                    StyledTextFormField(
                      isRequired: false,
                      title: 'ID de credencial (opcional)',
                      controller: idCredCtrl,
                    ),
                    StyledTextFormField(
                      isRequired: false,
                      title: 'URL del certificado (opcional)',
                      controller: urlCtrl,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return null;
                        final url = v.trim();
                        final ok = Uri.tryParse(url);
                        if (ok == null || !(ok.isScheme('http') || ok.isScheme('https'))) return 'URL inválida';
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),
                    HabilidadesMultiDropdown(
                      label: 'Habilidades desarrolladas (opcional)',
                      initialSelectedIds: const [],
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
                        if (caducidadCtrl.text.trim().isNotEmpty) {
                          final exp = DateTime.tryParse(expedicionCtrl.text.trim());
                          final cad = DateTime.tryParse(caducidadCtrl.text.trim());
                          if (exp == null || cad == null) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fechas inválidas')));
                            return;
                          }
                          if (cad.isBefore(exp)) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Caducidad antes de expedición')));
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
                          final uri = Uri.parse('https://oda-talent-back-81413836179.us-central1.run.app/api/alumnos/certificado/agregar');
                          final habs = selectedHabOptions.isEmpty
                              ? <Map<String, dynamic>>[]
                              : selectedHabOptions.map((h) => {'id_habilidad': h.id}).toList();
                          final Map<String, dynamic> payload = {
                            'id_alumno': idAlumno,
                            'nombre': nombreCtrl.text.trim(),
                            'institucion': institucionCtrl.text.trim(),
                            'fecha_expedicion': expedicionCtrl.text.trim(),
                            'habilidades_desarrolladas': habs,
                          };
                          final cadTxt = caducidadCtrl.text.trim();
                          if (cadTxt.isNotEmpty) payload['fecha_caducidad'] = cadTxt;
                          final idc = idCredCtrl.text.trim();
                          if (idc.isNotEmpty) payload['id_credencial'] = idc;
                          final urlTxt = urlCtrl.text.trim();
                          if (urlTxt.isNotEmpty) payload['url_certificado'] = urlTxt;

                          final headers = await context.read<UserDataProvider>().getAuthHeaders();
                          final resp = await http.post(
                            uri,
                            headers: headers,
                            body: jsonEncode(payload),
                          );
                          if (resp.statusCode >= 200 && resp.statusCode < 300) {
                            Navigator.pop(dialogCtx);
                            onUpdated();
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Certificado agregado')));
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
            child: Text('Certificados:', style: TextStyle(fontWeight: FontWeight.w700)),
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
          child: Text('Certificados:', style: TextStyle(fontWeight: FontWeight.w700)),
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