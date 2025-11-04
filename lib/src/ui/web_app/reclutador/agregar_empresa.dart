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

class AgregarEmpresaPageWebRec extends StatefulWidget {
  const AgregarEmpresaPageWebRec({super.key});

  @override
  State<AgregarEmpresaPageWebRec> createState() => _AgregarEmpresaPageWebRecState();
}

class _AgregarEmpresaPageWebRecState extends State<AgregarEmpresaPageWebRec> {
  final _agregarEmpresaFormKey = GlobalKey<FormState>();
  // Controllers
  final _nombreCtrl = TextEditingController();
  final _descripcionCtrl = TextEditingController();
  final _sitioWebCtrl = TextEditingController();

  List<DropdownMenuItem<String>> _empresasItems = [];
  String? _empresaSeleccionada;

  // Estado de carga y validación
  bool _loading = false;
  bool _hasMinLength = false;
  bool _hasLetter = false;
  bool _hasNumber = false;
  bool _hasSpecialChar = false;

  final ScrollController _scrollCtrl = ScrollController();
  bool _showFooter = false;

  // Reservamos SIEMPRE espacio para el footer en el padding inferior
  static const double _footerReservedSpace = EscomFooter.height;
  static const double _extraBottomPadding = 24.0;

  // Umbral mínimo para considerar que se llegó al final
  static const double _atEndThreshold = 4.0;

  @override
  Future<void> initState() async {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
    // tras el primer frame, intentamos evaluar por si el contenido ya es largo
    WidgetsBinding.instance.addPostFrameCallback((_) => _onScroll());
    await _fetchEmpresas();
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

  Future<void> _registerUser() async {
    // Validar el formulario antes de continuar
    if (!_agregarEmpresaFormKey.currentState!.validate()) {
      return;
    }

    setState(() => _loading = true);

    try {
      final auth = FirebaseAuth.instance;
      final credential = await auth.createUserWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text.trim(),
      );
      final user = credential.user!;
      final idToken = await user.getIdToken();
      _nombreCompleto ='${_nombreCtrl.text.trim()} ${_apPaternoCtrl.text.trim()} ${_apMaternoCtrl.text.trim()}';
      await user.updateDisplayName(_nombreCompleto);

      // NOTA: Para web, usa 'localhost' en lugar de '10.0.2.2'
      final response = await http.post(
        Uri.parse('https://oda-talent-back-81413836179.us-central1.run.app/api/usuarios/registrar'),
        headers: {
          'Authorization': 'Bearer $idToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'nombre': _nombreCompleto,
          'email': _emailCtrl.text.trim(),
          'rol': 'reclutador',
          'genero': _genderController.text.trim(),
          'uid_firebase': user.uid,
        }),
      );

      if ((response.statusCode == 201 || response.statusCode == 200) && (!user.emailVerified)) {
        await credential.user!.sendEmailVerification();
        // Navegación con go_router. Asegúrate de tener esta ruta configurada.
        if (mounted) context.go('/verificar-email');
      } else {
        throw Exception("Error del servidor: ${response.body}");
      }
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'email-already-in-use':
          _showError("El correo ya está en uso.");
          break;
        case 'invalid-email':
          _showError("El correo no es válido.");
          break;
        case 'weak-password':
          _showError("La contraseña es muy débil.");
          break;
        default:
          _showError("Error de autenticación: ${e.message}");
      }
    } on Exception catch (e) {
      await FirebaseAuth.instance.currentUser?.delete();
      _showError("Error inesperado: ${e.toString()}");
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _showError(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.red),
      );
    }
  }

  void _validatePassword(String value) {
    setState(() {
      _hasMinLength = value.length >= 8;
      _hasLetter = RegExp(r'[A-Za-z]').hasMatch(value);
      _hasNumber = RegExp(r'\d').hasMatch(value);
      _hasSpecialChar = RegExp(r'[@$!%*?&.,;:_\-]').hasMatch(value);
    });
  }

  Widget _buildValidationRow(String text, bool isValid) {
    return Row(
      children: [
        Icon(
          isValid ? Icons.check_circle : Icons.radio_button_unchecked,
          color: isValid ? Colors.blue : Colors.grey,
          size: 20,
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            color: isValid ? Colors.blue : Colors.grey,
            fontWeight: isValid ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  void _cargarEmpresasItemsDeJson(List<dynamic> jsonList) {
    final items = jsonList.map<DropdownMenuItem<String>>((e) {
      final id = (e['id'] ?? '').toString();
      final label = (e['nombre'] ?? id).toString();
      return DropdownMenuItem(value: id, child: Text(label));
    }).toList();

    // Opcional: añadir opción para ir a "agregar" al final
    items.add(const DropdownMenuItem(value: 'agregar', child: Text('Agregar empresa')));

    setState(() => _empresasItems = items);
  }

  Future<void> _fetchEmpresas() async {
    try {
      final response = await http.get(
        Uri.parse('http://localhost:3000/api/empresas/obtener_empresas'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _cargarEmpresasItemsDeJson(data);
      } else {
        throw Exception("Error al cargar empresas");
      }
    } catch (e) {
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

    return Scaffold(
      appBar: EscomHeader(
        onLoginTap: () => context.go('/login'),
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
                              key: _agregarEmpresaFormKey,
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
                                        // Con go_router
                                        if (mounted) context.go('/agregar_empresa'); // ruta que definas
                                        // Alternativa con Navigator:
                                        // Navigator.of(context).pushNamed('/agregar-genero');
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
                                    title: 'Correo Electrónico',
                                    controller: _emailCtrl,
                                    keyboardType: TextInputType.emailAddress,
                                  ),
                                  const SizedBox(height: 12),
                                  const SizedBox(height: 12),
                                  StyledTextFormField(
                                    controller: _passwordCtrl,
                                    title: "Contraseña",
                                    obscureText: true,
                                    isPasswordField: true,
                                    onChanged: _validatePassword,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'La contraseña es obligatoria.';
                                      }
                                      if (!_hasMinLength || !_hasLetter || !_hasNumber || !_hasSpecialChar) {
                                        return 'La contraseña no cumple con los requisitos.';
                                      }
                                      return null;
                                    },
                                  ),
                              
                                  const SizedBox(height: 20),

                                  Padding(
                                    padding: const EdgeInsets.only(left: 4.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text("Requisitos de la contraseña:", style: TextStyle(fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 8),
                                        _buildValidationRow("Al menos 8 caracteres", _hasMinLength),
                                        const SizedBox(height: 4),
                                        _buildValidationRow("Al menos una letra", _hasLetter),
                                        const SizedBox(height: 4),
                                        _buildValidationRow("Al menos un número", _hasNumber),
                                        const SizedBox(height: 4),
                                        _buildValidationRow("Al menos un carácter especial", _hasSpecialChar),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 24), 
                              
                                  LargeButton(
                                    onTap: _registerUser,
                                    title: 'Registrarme',
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
                                    onTap: () => context.go('/inicio_rec'),
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
