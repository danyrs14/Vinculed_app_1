import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:vinculed_app_1/src/ui/widgets/elements/header.dart';
import 'package:vinculed_app_1/src/ui/widgets/elements/footer.dart';
import 'package:vinculed_app_1/src/ui/widgets/text_inputs/text_input.dart';
import 'package:vinculed_app_1/src/ui/widgets/buttons/large_buttons.dart';
import 'package:vinculed_app_1/src/ui/widgets/text_inputs/text_form_field.dart'; // Cambiado de TextInput a TextFormField
import 'package:vinculed_app_1/src/ui/widgets/text_inputs/dropdown.dart';

class RegisterPageWebRec extends StatefulWidget {
  const RegisterPageWebRec({super.key});

  @override
  State<RegisterPageWebRec> createState() => _RegisterPageWebRecState();
}

class _RegisterPageWebRecState extends State<RegisterPageWebRec> {
  final _registroFormKey = GlobalKey<FormState>();
  // Controllers
  final _nombreCtrl = TextEditingController();
  final _apPaternoCtrl = TextEditingController();
  final _apMaternoCtrl = TextEditingController();
  final _empresaNombreCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _genderController = TextEditingController();
  final _empresaDireccionCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  String? _nombreCompleto;

  List<DropdownMenuItem<String>> _empresasItems = [];
  String? _empresaSeleccionada;

  bool _isLoading = true;

  final ScrollController _scrollCtrl = ScrollController();
  bool _showFooter = false;

  // Reservamos SIEMPRE espacio para el footer en el padding inferior
  static const double _footerReservedSpace = EscomFooter.height;
  static const double _extraBottomPadding = 24.0;

  // Umbral mínimo para considerar que se llegó al final
  static const double _atEndThreshold = 4.0;

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
    // tras el primer frame, intentamos evaluar por si el contenido ya es largo
    WidgetsBinding.instance.addPostFrameCallback((_) => _onScroll());
     _fetchEmpresas();
  }

  void _onScroll() {
    final pos = _scrollCtrl.position;
    if (!pos.hasPixels || !pos.hasContentDimensions) return;

    // Si no hay scroll suficiente, puedes decidir:
    // - Mostrar footer inmediatamente (true), o
    // - Mantenerlo oculto (false).
    // Aquí lo mantenemos oculto si no hay scroll.
    if (pos.maxScrollExtent <= 0) {
      if (_showFooter) setState(() => _showFooter = false);
      return;
    }

    final atBottom = pos.pixels >= (pos.maxScrollExtent - _atEndThreshold);
    if (atBottom != _showFooter) {
      setState(() => _showFooter = atBottom);
    }
  }

  Future<void> _encolarReclutador() async {
    // Validar el formulario antes de continuar
    if (!_registroFormKey.currentState!.validate()) {
      return;
    }

    try {
      _nombreCompleto = '${_nombreCtrl.text.trim()} ${_apPaternoCtrl.text.trim()} ${_apMaternoCtrl.text.trim()}';
      // NOTA: Para web, usa 'localhost' en lugar de '10.0.2.2'
      final response = await http.post(
        Uri.parse('https://oda-talent-back-81413836179.us-central1.run.app/api/usuarios/encolar_reclutador'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'nombre': _nombreCompleto,
          'email': _emailCtrl.text.trim(),
          'genero': _genderController.text.trim(),
          'id_empresa' : _empresaNombreCtrl.text.trim()
        }),
      );

      if ((response.statusCode == 201 || response.statusCode == 200) ) {
        // Navegación con go_router. Asegúrate de tener esta ruta configurada.
        if (mounted) context.go('/dashboard');
      } else {
        throw Exception("Error del servidor: ${response.body}");
      }
    } catch (e) {
      _showError('Error al solicitar registro: $e');
    }
  }

  void _showError(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.red),
      );
    }
  }

  void _cargarEmpresasItemsDeJson(List<dynamic> jsonList) {
    final items = jsonList.map<DropdownMenuItem<String>>((e) {
      final id = (e['id'] ?? '').toString();
      final label = (e['nombre'] ?? id).toString();
      return DropdownMenuItem(value: id, child: Text(label));
    }).toList();

    //items.add(const DropdownMenuItem(value: 'agregar', child: Text('Agregar empresa')));

    setState(() {_empresasItems = items; _isLoading = false;});
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
        throw Exception("Error al cargar empresas");
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          // Aquí puedes guardar el error en otra variable de estado si quieres
        });
      }
      _showError(e.toString());

    }
  }

  @override
  void dispose() {
    _scrollCtrl
      ..removeListener(_onScroll)
      ..dispose();
    _nombreCtrl.dispose();
    _apPaternoCtrl.dispose();
    _apMaternoCtrl.dispose();
    _empresaNombreCtrl.dispose();
    _emailCtrl.dispose();
    _empresaDireccionCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 700;

    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: EscomHeader(
        onLoginTap: () => context.go('/login'),
        onRegisterTap: () => context.go('/register'),
        onNotifTap: () {},
        onMenuSelected: (label) {
          switch (label) {
            case "Inicio":
              context.go('/dashboard');
              break;
          }
        },
      ),
      body: Stack(
        children: [
          // SCROLL GLOBAL, reservando SIEMPRE el espacio del footer
          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Al reservar siempre el espacio del footer, el final del contenido
                // no “se mueve” cuando se muestra el footer.
                final minBodyHeight = constraints.maxHeight
                    - _footerReservedSpace
                    - _extraBottomPadding;

                return NotificationListener<ScrollNotification>(
                  // redundancia útil: además del listener del controller,
                  // capturamos notificaciones para responder más rápido
                  onNotification: (n) {
                    // Disparamos el cálculo cuando se actualizan métricas
                    if (n is ScrollEndNotification ||
                        n is UserScrollNotification ||
                        n is ScrollUpdateNotification) {
                      _onScroll();
                    }
                    return false;
                  },
                  child: SingleChildScrollView(
                    controller: _scrollCtrl,
                    physics: const ClampingScrollPhysics(),
                    padding: const EdgeInsets.only(
                      bottom: _footerReservedSpace + _extraBottomPadding,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 620),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: minBodyHeight > 0 ? minBodyHeight : 0,
                            ),
                            child: Form(
                              key: _registroFormKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Lottie/Ilustración
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
                              
                                  // Formulario
                                  StyledTextFormField(title: 'Nombre(s)', controller: _nombreCtrl,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'El nombre es obligatorio.';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                  StyledTextFormField(title: 'Apellido Paterno', controller: _apPaternoCtrl,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'El apellido paterno es obligatorio.';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                  StyledTextFormField(title: 'Apellido Materno', controller: _apMaternoCtrl,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'El apellido materno es obligatorio.';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                  DropdownInput<String>(
                                    title: "Género",
                                    required: true,
                                    items: const [
                                      DropdownMenuItem(value: "masculino", child: Text("Masculino")),
                                      DropdownMenuItem(value: "femenino", child: Text("Femenino")),
                                      DropdownMenuItem(value: "otro", child: Text("Otro")),
                                    ],
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'El género es obligatorio.';
                                      }
                                      return null;
                                    },
                                    onChanged: (valor) {
                                      setState(() {
                                        _genderController.text = valor ?? "";
                                      });
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                  DropdownInput<String>(
                                    title: "Empresa",
                                    required: true,
                                    items: _empresasItems,
                                    value: _empresaSeleccionada,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) return 'La empresa es obligatoria.';
                                      return null;
                                    },
                                    onChanged: (valor) {
                                      if (valor == null) return;
                                      if (valor == 'agregar') {
                                        if (mounted) context.go('/agregar_empresa');
                                        return;
                                      }
                                      setState(() {
                                        _empresaSeleccionada = valor;
                                        _empresaNombreCtrl.text = valor;
                                      });
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                  StyledTextFormField(
                                    controller: _emailCtrl,
                                    title: "Correo electrónico",
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
                              
                                  LargeButton(
                                    onTap: _encolarReclutador,
                                    title: 'Solicitar Registro',
                                  ),
                              
                                  const SizedBox(height: 24),
                              
                                  const Row(
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
                                    onTap: () => context.go('/login'),
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
                  ),
                );
              },
            ),
          ),

          // FOOTER (aparece inmediatamente al llegar al final)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: AnimatedSlide(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              offset: _showFooter ? Offset.zero : const Offset(0, 1),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 220),
                opacity: _showFooter ? 1 : 0,
                child: EscomFooter(isMobile: isMobile),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onRegister() {
    // TODO: validación/envío de formulario
  }
}
