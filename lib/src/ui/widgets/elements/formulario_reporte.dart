import 'package:flutter/material.dart';
import 'package:vinculed_app_1/src/core/controllers/theme_controller.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:vinculed_app_1/src/core/providers/user_provider.dart';
import 'package:vinculed_app_1/src/ui/widgets/buttons/simple_buttons.dart';
import 'package:vinculed_app_1/src/ui/widgets/text_inputs/dropdown.dart';
import 'package:vinculed_app_1/src/ui/widgets/text_inputs/text_form_field.dart';

class ReportContentDialog extends StatefulWidget {
  final int idAlumno;
  final int idContenido;
  final String tipoContenidoInicial;
  const ReportContentDialog({
    required this.idAlumno,
    required this.idContenido,
    required this.tipoContenidoInicial,
  });

  @override
  State<ReportContentDialog> createState() => ReportContentDialogState();
}

class ReportContentDialogState extends State<ReportContentDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _descripcionCtrl = TextEditingController();
  String? _tipoContenido;
  String? _razon;
  bool _sending = false;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _tipoContenido = widget.tipoContenidoInicial;
  }

  @override
  void dispose() {
    _descripcionCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;
    setState(() { _sending = true; _error = ''; });
    try {
      final userProv = Provider.of<UserDataProvider>(context, listen: false);
      final headers = await userProv.getAuthHeaders();
      final descripcion = _descripcionCtrl.text.trim();
      final body = jsonEncode({
        'id_alumno': widget.idAlumno,
        'id_reclutador': null,
        'id_contenido': widget.idContenido,
        'tipo_contenido': _tipoContenido,
        'razon': _razon,
        'descripcion': descripcion.isEmpty ? null : descripcion,
      });
      final res = await http.post(
        Uri.parse('http://localhost:3000/api/experiencias_alumnos/reportar_contenido'),
        headers: headers,
        body: body,
      );
      if (res.statusCode >= 200 && res.statusCode < 300) {
        if (mounted) Navigator.of(context).pop(true);
      } else {
        setState(() { _error = 'Error ${res.statusCode}: ${res.body}'; });
      }
    } catch (e) {
      setState(() { _error = 'Error: $e'; });
    } finally {
      if (mounted) setState(() { _sending = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;
    return AlertDialog(
      title: const Text('Reportar contenido'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // TextFormField(
              //   initialValue: widget.idAlumno.toString(),
              //   readOnly: true,
              //   decoration: const InputDecoration(labelText: 'ID Alumno (reporta)'),
              // ),
              // const SizedBox(height: 8),
              // TextFormField(
              //   initialValue: widget.idContenido.toString(),
              //   readOnly: true,
              //   decoration: const InputDecoration(labelText: 'ID Contenido'),
              // ),
              // const SizedBox(height: 8),
              DropdownInput<String>(
                value: _tipoContenido,
                items: const [
                  DropdownMenuItem(value: 'Publicacion', child: Text('Publicación (Experiencia)')),
                  DropdownMenuItem(value: 'Comentario', child: Text('Comentario')),
                  DropdownMenuItem(value: 'Vacante', child: Text('Vacante')),
                ],
                onChanged: (v) => setState(() => _tipoContenido = v),
                title: 'Tipo de contenido',
                validator: (v) => (v == null || v.isEmpty) ? 'Selecciona el tipo' : null,
              ),
              const SizedBox(height: 8),
              DropdownInput<String>(
                value: _razon,
                items: const [
                  DropdownMenuItem(value: 'Contenido inapropiado', child: Text('Contenido inapropiado')),
                  DropdownMenuItem(value: 'Sin vacantes', child: Text('Sin vacantes')),
                  DropdownMenuItem(value: 'Otro', child: Text('Otro')),
                ],
                onChanged: (v) => setState(() => _razon = v),
                title: 'Motivo',
                validator: (v) => (v == null || v.isEmpty) ? 'Selecciona la razón' : null,
              ),
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 150, maxWidth: 300),
                child: StyledTextFormField(
                  controller: _descripcionCtrl,
                  maxLength: 250,
                  maxLines: 4,
                  title: 'Descripción (opcional)',
                ),
              ),
              if (_error.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(_error, style: const TextStyle(color: Colors.red)),
              ],
            ],
          ),
        ),
      ),
      actions: [
        SimpleButton(
          title: 'Cancelar',
          backgroundColor: Colors.blueGrey,
          textColor: Colors.white,
          onTap: _sending ? null : () => Navigator.of(context).pop(false),
        ),
        SimpleButton(
          title: _sending ? 'Enviando...':'Enviar reporte',
          onTap: _sending ? null : _submit,
        ),

      ],
    );
  }
}
