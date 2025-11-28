import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:lottie/lottie.dart';

import 'package:vinculed_app_1/src/ui/widgets/text_inputs/text_form_field.dart';
import 'package:vinculed_app_1/src/ui/widgets/buttons/large_buttons.dart';

class AgregarEmpresaPage extends StatefulWidget {
  const AgregarEmpresaPage({super.key});

  @override
  State<AgregarEmpresaPage> createState() => _AgregarEmpresaPageState();
}

class _AgregarEmpresaPageState extends State<AgregarEmpresaPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _nombreCtrl = TextEditingController();
  final _descripcionCtrl = TextEditingController();
  final _sitioWebCtrl = TextEditingController();

  bool _sending = false;

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _descripcionCtrl.dispose();
    _sitioWebCtrl.dispose();
    super.dispose();
  }

  Future<void> _enviarEmpresa() async {
    if (!_formKey.currentState!.validate()) return;
    if (_sending) return;

    setState(() => _sending = true);

    try {
      final Map<String, dynamic> body = {
        'nombre': _nombreCtrl.text.trim(),
        'descripcion': _descripcionCtrl.text.trim(),
      };
      final sitio = _sitioWebCtrl.text.trim();
      if (sitio.isNotEmpty) body['sitio_web'] = sitio;

      final response = await http.post(
        Uri.parse('https://oda-talent-back-81413836179.us-central1.run.app/api/empresas/agregar_empresa'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (!mounted) return;

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Empresa agregada correctamente'), backgroundColor: Colors.green),
        );
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/signin_rec');
        }
      } else {
        String msg = 'Error del servidor (${response.statusCode})';
        try {
          final data = jsonDecode(response.body);
          if (data is Map && data['message'] != null) msg = data['message'].toString();
        } catch (_) {}
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al agregar empresa: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  String? _validarNombre(String? v) {
    if (v == null || v.trim().isEmpty) return 'El nombre es obligatorio.';
    return null;
  }

  String? _validarDescripcion(String? v) {
    if (v == null || v.trim().isEmpty) return 'La descripción es obligatoria.';
    if (v.length > 2000) return 'La descripción no debe exceder 2000 caracteres.';
    return null;
  }

  String? _validarSitioWeb(String? v) {
    if (v == null || v.trim().isEmpty) return null; // opcional
    final value = v.trim();
    final uri = Uri.tryParse(value);
    if (uri == null || !uri.hasScheme || !(uri.scheme == 'http' || uri.scheme == 'https') || uri.host.isEmpty) {
      return 'URL inválida. Use http(s)://';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: Alignment.center,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: SizedBox(
                          height: 180,
                          width: 280,
                          child: Lottie.asset('assets/images/logen.json', fit: BoxFit.contain),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    StyledTextFormField(
                      isRequired: true,
                      title: 'Nombre de la empresa',
                      controller: _nombreCtrl,
                      validator: _validarNombre,
                    ),
                    const SizedBox(height: 12),
                    StyledTextFormField(
                      isRequired: true,
                      title: 'Descripción (máx. 2000 caracteres)',
                      controller: _descripcionCtrl,
                      keyboardType: TextInputType.multiline,
                      maxLines: 6,
                      maxLength: 2000,
                      validator: _validarDescripcion,
                    ),
                    const SizedBox(height: 12),
                    StyledTextFormField(
                      isRequired: false,
                      title: 'Sitio web (opcional)',
                      controller: _sitioWebCtrl,
                      keyboardType: TextInputType.url,
                      validator: _validarSitioWeb,
                    ),
                    const SizedBox(height: 24),
                    LargeButton(
                      onTap: _sending ? null : _enviarEmpresa,
                      title: _sending ? 'Enviando...' : 'Guardar empresa',
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: const [
                        Expanded(child: Divider(thickness: 1)),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12.0),
                          child: Text('O'),
                        ),
                        Expanded(child: Divider(thickness: 1)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    LargeButton(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      title: 'Volver al registro de reclutador',
                    ),
                    const SizedBox(height: 40),
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
