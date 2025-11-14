import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:vinculed_app_1/src/core/providers/user_provider.dart';
import 'package:vinculed_app_1/src/ui/widgets/text_inputs/text_form_field.dart';
import 'package:vinculed_app_1/src/ui/widgets/buttons/simple_buttons.dart';
import 'package:vinculed_app_1/src/ui/widgets/text_inputs/dropdown.dart';

class UrlItem {
  final int idUrl;
  final int idAlumno;
  final String tipo;
  final String url;

  UrlItem({
    required this.idUrl,
    required this.idAlumno,
    required this.tipo,
    required this.url,
  });

  factory UrlItem.fromJson(Map<String, dynamic> j) => UrlItem(
        idUrl: j['id_url'] ?? 0,
        idAlumno: j['id_alumno'] ?? 0,
        tipo: j['tipo'] ?? '',
        url: j['url'] ?? '',
      );
}

class UrlsSection extends StatelessWidget {
  const UrlsSection({super.key, required this.items, required this.emptyText, required this.onUpdated});
  final List<UrlItem> items;
  final String emptyText;
  final VoidCallback onUpdated;

  static const List<String> _tipos = ['LinkedIn', 'GitHub', 'Blog', 'Portafolio', 'Otro'];

  String _display(UrlItem u) => '${u.tipo}: ${u.url}';

  void _openEditSelection(BuildContext context) async {
    if (items.isEmpty) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Editar URLs externas'),
          content: Text('No hay elementos en "URLs externas" todavía.'),
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
        title: const Text('Selecciona una URL'),
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

  void _openEditForm(BuildContext context, UrlItem item) {
    final formKey = GlobalKey<FormState>();
    String? tipoSel = item.tipo;
    final urlCtrl = TextEditingController(text: item.url);

    showDialog(
      context: context,
      builder: (dialogCtx) {
        bool saving = false;
        return StatefulBuilder(
          builder: (ctx, setState) => AlertDialog(
            title: const Text('Editar URL externa'),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DropdownInput<String>(
                      title: 'Tipo',
                      required: true,
                      value: tipoSel,
                      items: _tipos.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                      onChanged: (v) => setState(() => tipoSel = v),
                      validator: (v) => (v == null || v.isEmpty) ? 'Tipo requerido' : null,
                    ),
                    StyledTextFormField(
                      title: 'URL',
                      controller: urlCtrl,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'URL requerida';
                        final vt = v.trim();
                        if (!vt.startsWith('http://') && !vt.startsWith('https://')) return 'URL inválida (debe iniciar con http/https)';
                        return null;
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
                          final uri = Uri.parse('http://localhost:3000/api/alumnos/url_externa/eliminar');
                          final payload = jsonEncode({
                            'id_url': item.idUrl,
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
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('URL eliminada')));
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
                        setState(() => saving = true);
                        try {
                          final provider = Provider.of<UserDataProvider>(context, listen: false);
                          final uri = Uri.parse('http://localhost:3000/api/alumnos/url_externa/actualizar');
                          final payload = jsonEncode({
                            'id_alumno': item.idAlumno,
                            'id_url': item.idUrl,
                            'tipo': tipoSel,
                            'url': urlCtrl.text.trim(),
                          });
                          final resp = await http.put(
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
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('URL actualizada')));
                          } else {
                            setState(() => saving = false);
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error ${resp.statusCode} al guardar')));
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
    String? tipoSel;
    final urlCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogCtx) {
        bool saving = false;
        return StatefulBuilder(
          builder: (ctx, setState) => AlertDialog(
            title: const Text('Agregar URL externa'),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DropdownInput<String>(
                      title: 'Tipo',
                      required: true,
                      value: tipoSel,
                      items: _tipos.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                      onChanged: (v) => setState(() => tipoSel = v),
                      validator: (v) => (v == null || v.isEmpty) ? 'Tipo requerido' : null,
                    ),
                    StyledTextFormField(
                      title: 'URL',
                      controller: urlCtrl,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'URL requerida';
                        final vt = v.trim();
                        if (!vt.startsWith('http://') && !vt.startsWith('https://')) return 'URL inválida (debe iniciar con http/https)';
                        return null;
                      },
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
                        setState(() => saving = true);
                        try {
                          final provider = Provider.of<UserDataProvider>(context, listen: false);
                          final idAlumno = provider.idRol;
                          if (idAlumno == null) {
                            setState(() => saving = false);
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No hay id_alumno')));
                            return;
                          }
                          final uri = Uri.parse('http://localhost:3000/api/alumnos/url_externa/agregar');
                          final payload = jsonEncode({
                            'id_alumno': idAlumno,
                            'tipo': tipoSel,
                            'url': urlCtrl.text.trim(),
                          });
                          final resp = await http.post(
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
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('URL agregada')));
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
            child: Text('URLs Externas:', style: TextStyle(fontWeight: FontWeight.w700)),
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
          child: Text('URLs Externas:', style: TextStyle(fontWeight: FontWeight.w700)),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final u in items)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(_display(u)),
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
