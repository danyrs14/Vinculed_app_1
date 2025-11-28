import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:lottie/lottie.dart';
import 'package:vinculed_app_1/src/ui/pages/reclutador/agregar_empresa.dart';

import 'package:vinculed_app_1/src/ui/widgets/text_inputs/dropdown.dart';
import 'package:vinculed_app_1/src/ui/widgets/text_inputs/text_form_field.dart';
import 'package:vinculed_app_1/src/ui/widgets/buttons/large_buttons.dart';

class RegistrarReclutadorPage extends StatefulWidget {
  const RegistrarReclutadorPage({super.key});

  @override
  State<RegistrarReclutadorPage> createState() => _RegistrarReclutadorPageState();
}

class _RegistrarReclutadorPageState extends State<RegistrarReclutadorPage> {
  final _registroFormKey = GlobalKey<FormState>();

  // Controllers
  final _nombreCtrl = TextEditingController();
  final _apPaternoCtrl = TextEditingController();
  final _apMaternoCtrl = TextEditingController();
  final _empresaNombreCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _genderController = TextEditingController();

  // Opciones de empresas
  List<DropdownMenuItem<String>> _empresasItems = [];
  String? _empresaSeleccionada;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchEmpresas();
  }

  Future<void> _fetchEmpresas() async {
    try {
      final response = await http.get(
        Uri.parse('https://oda-talent-back-81413836179.us-central1.run.app/api/empresas/obtener_empresas'),
      );

      if (response.statusCode == 200 && mounted) {
        final List<dynamic> data = jsonDecode(response.body);
        _cargarEmpresasItemsDeJson(data);
      } else {
        throw Exception('Error al cargar empresas');
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      _showError(e.toString());
    }
  }

  void _cargarEmpresasItemsDeJson(List<dynamic> jsonList) {
    final items = jsonList.map<DropdownMenuItem<String>>((e) {
      final id = (e['id'] ?? '').toString();
      final label = (e['nombre'] ?? id).toString();
      return DropdownMenuItem(value: id, child: Text(label));
    }).toList();

    items.add(const DropdownMenuItem(value: 'agregar', child: Text('Agregar empresa')));

    setState(() {
      _empresasItems = items;
      _isLoading = false;
    });
  }

  Future<void> _encolarReclutador() async {
    if (!_registroFormKey.currentState!.validate()) return;

    try {
      final nombreCompleto = '${_nombreCtrl.text.trim()} ${_apPaternoCtrl.text.trim()} ${_apMaternoCtrl.text.trim()}';

      final response = await http.post(
        Uri.parse('https://oda-talent-back-81413836179.us-central1.run.app/api/usuarios/encolar_reclutador'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'nombre': nombreCompleto,
          'email': _emailCtrl.text.trim(),
          'genero': _genderController.text.trim(),
          'id_empresa': _empresaNombreCtrl.text.trim(),
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gracias por registrarse. Revisaremos su registro y nos pondremos en contacto con usted.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 5),
          ),
        );
        context.go('/dashboard');
      } else {
        throw Exception('Error del servidor: ${response.body}');
      }
    } catch (e) {
      _showError('Error al solicitar registro: $e');
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _apPaternoCtrl.dispose();
    _apMaternoCtrl.dispose();
    _empresaNombreCtrl.dispose();
    _emailCtrl.dispose();
    _genderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: Form(
                key: _registroFormKey,
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
                          child: Lottie.asset(
                            'assets/images/logen.json',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Nombre(s)
                    StyledTextFormField(
                      isRequired: true,
                      title: 'Nombre(s)',
                      controller: _nombreCtrl,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'El nombre es obligatorio.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    // Apellido paterno
                    StyledTextFormField(
                      isRequired: true,
                      title: 'Apellido Paterno',
                      controller: _apPaternoCtrl,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'El apellido paterno es obligatorio.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    // Apellido materno
                    StyledTextFormField(
                      isRequired: true,
                      title: 'Apellido Materno',
                      controller: _apMaternoCtrl,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'El apellido materno es obligatorio.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    // Género
                    DropdownInput<String>(
                      title: 'Género',
                      required: true,
                      items: const [
                        DropdownMenuItem(value: 'masculino', child: Text('Masculino')),
                        DropdownMenuItem(value: 'femenino', child: Text('Femenino')),
                        DropdownMenuItem(value: 'otro', child: Text('Otro')),
                      ],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'El género es obligatorio.';
                        }
                        return null;
                      },
                      onChanged: (valor) {
                        setState(() {
                          _genderController.text = valor ?? '';
                        });
                      },
                    ),
                    const SizedBox(height: 12),

                    // Empresa
                    DropdownInput<String>(
                      title: 'Empresa',
                      required: true,
                      items: _empresasItems,
                      value: _empresaSeleccionada,
                      validator: (value) {
                        if (value == null || value.isEmpty || value == 'agregar') {
                          return 'La empresa es obligatoria.';
                        }
                        return null;
                      },
                      onChanged: (valor) {
                        if (valor == null) return;
                        if (valor == 'agregar') {
                          if (mounted){
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => AgregarEmpresaPage()),
                            );
                          }
                          return;
                        }
                        setState(() {
                          _empresaSeleccionada = valor;
                          _empresaNombreCtrl.text = valor;
                        });
                      },
                    ),
                    const SizedBox(height: 12),

                    // Correo
                    StyledTextFormField(
                      isRequired: true,
                      controller: _emailCtrl,
                      title: 'Correo electrónico',
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'El correo es obligatorio.';
                        }
                        final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                        if (!emailRegex.hasMatch(value)) {
                          return 'Ingrese un correo válido.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Botón solicitar registro
                    LargeButton(
                      onTap: _encolarReclutador,
                      title: 'Solicitar Registro',
                    ),

                    const SizedBox(height: 24),

                    Row(
                      children: const [
                        Expanded(child: Divider(thickness: 1)),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12.0),
                          child: Text('OR'),
                        ),
                        Expanded(child: Divider(thickness: 1)),
                      ],
                    ),

                    const SizedBox(height: 16),

                    LargeButton(
                      onTap: () => Navigator.pop( context),
                      title: 'Iniciar Sesión',
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
