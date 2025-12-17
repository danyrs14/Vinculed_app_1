import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// Widgets personalizados (asegúrate de que las rutas de importación sean correctas)
import 'package:vinculed_app_1/src/ui/widgets/elements/header.dart';
import 'package:vinculed_app_1/src/ui/widgets/elements/footer.dart';
import 'package:vinculed_app_1/src/ui/widgets/text_inputs/text_form_field.dart'; // Cambiado de TextInput a TextFormField
import 'package:vinculed_app_1/src/ui/widgets/text_inputs/dropdown.dart';
import 'package:vinculed_app_1/src/ui/widgets/buttons/large_buttons.dart';
// Asegúrate de tener una página para verificar email en tus rutas de go_router
// import 'package:vinculed_app_1/src/ui/pages/verificarEmail.dart';

class RegisterPageWeb extends StatefulWidget {
  final String? nombre; 
  
  const RegisterPageWeb({super.key, this.nombre});

  @override
  State<RegisterPageWeb> createState() => _RegisterPageWebState();
}

class _RegisterPageWebState extends State<RegisterPageWeb> {
  // Key para el formulario
  final _registroFormKey = GlobalKey<FormState>();

  // Controllers del formulario (unificados con la versión móvil)
  final _nameController = TextEditingController();
  final _genderController = TextEditingController();
  final _emailController = TextEditingController();
  final _confirmEmailController = TextEditingController();
  final _passwordController = TextEditingController();

  // Estado de carga y validación
  bool _loading = false;
  bool _hasMinLength = false;
  bool _hasLetterM = false;
  bool _hasLetterm = false;
  bool _hasNumber = false;
  bool _hasSpecialChar = false;

  // Lógica para mostrar/ocultar el footer (se mantiene)
  final ScrollController _scrollCtrl = ScrollController();
  bool _showFooter = false;
  static const double _footerReservedSpace = EscomFooter.height;
  static const double _extraBottomPadding = 24.0;
  static const double _atEndThreshold = 4.0;

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _onScroll());
    if (widget.nombre != null) {
      _nameController.text = widget.nombre!;
    }
  }

  Future<void> _registerUser() async {
    // Validar el formulario antes de continuar
    if (!_registroFormKey.currentState!.validate()) {
      return;
    }

    setState(() => _loading = true);

    try {
      final auth = FirebaseAuth.instance;
      final credential = await auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      final user = credential.user!;
      final idToken = await user.getIdToken();
      await user.updateDisplayName(_nameController.text.trim());

      // NOTA: Para web, usa 'localhost' en lugar de '10.0.2.2'
      final response = await http.post(
        Uri.parse('https://oda-talent-back-81413836179.us-central1.run.app/api/usuarios/registrar'),
        headers: {
          'Authorization': 'Bearer $idToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'nombre': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'rol': 'alumno',
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
      _hasLetterM = RegExp(r'[A-Z]').hasMatch(value);
      _hasLetterm = RegExp(r'[a-z]').hasMatch(value);
      _hasNumber = RegExp(r'\d').hasMatch(value);
      _hasSpecialChar = RegExp(r'''[~`!@#$%\^&*()\-_+=|}\]{["':;?/>.<,]''').hasMatch(value);
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

  // --- Lógica del Footer (sin cambios) ---
  void _onScroll() {
    final pos = _scrollCtrl.position;
    if (!pos.hasPixels || !pos.hasContentDimensions) return;

    if (pos.maxScrollExtent <= 0) {
      if (_showFooter) setState(() => _showFooter = false);
      return;
    }

    final atBottom = pos.pixels >= (pos.maxScrollExtent - _atEndThreshold);
    if (atBottom != _showFooter) {
      setState(() => _showFooter = atBottom);
    }
  }

  @override
  void dispose() {
    _scrollCtrl
      ..removeListener(_onScroll)
      ..dispose();
    _nameController.dispose();
    _genderController.dispose();
    _emailController.dispose();
    _confirmEmailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 700;

    return Scaffold(
      appBar: EscomHeader(
        onLoginTap: () => context.go('/login'),
        onRegisterTap: () => context.go('/lector_qr'),
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
          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final minBodyHeight =
                    constraints.maxHeight - _footerReservedSpace - _extraBottomPadding;

                return NotificationListener<ScrollNotification>(
                  onNotification: (n) {
                    if (n is ScrollUpdateNotification ||
                        n is UserScrollNotification ||
                        n is ScrollEndNotification) {
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
                            child: Form( // Envolvemos el Column en un Form
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

                                  // --- Formulario unificado ---
                                  StyledTextFormField(
                                    isRequired: true,
                                    controller: _nameController,
                                    title: "Nombre completo",
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'El nombre es obligatorio.';
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
                                  StyledTextFormField(
                                    isRequired: true,
                                    controller: _emailController,
                                    title: "Correo institucional",
                                    keyboardType: TextInputType.emailAddress,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'El correo es obligatorio.';
                                      }
                                      final emailRegex = RegExp(r'^[^@]+@alumno.ipn.mx$');
                                      if (!emailRegex.hasMatch(value)) {
                                        return 'Ingrese un correo válido.';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                  StyledTextFormField(
                                    isRequired: true,
                                    controller: _confirmEmailController,
                                    title: "Confirma el correo",
                                    keyboardType: TextInputType.emailAddress,
                                    validator: (value) {
                                      if (value == null || value.isEmpty || 
                                      !identical(value.trim(), _emailController.text.trim())) {
                                        return 'El correo debe coincidir con el proporcionado anteriormente.';
                                      }
                                      final emailRegex = RegExp(r'^[^@]+@alumno.ipn.mx$');
                                      if (!emailRegex.hasMatch(value)) {
                                        return 'Ingrese un correo válido.';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                  StyledTextFormField(
                                    isRequired: true,
                                    controller: _passwordController,
                                    title: "Contraseña",
                                    obscureText: true,
                                    isPasswordField: true,
                                    onChanged: _validatePassword,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'La contraseña es obligatoria.';
                                      }
                                      if (!_hasMinLength || !_hasLetterM || !_hasLetterm || !_hasNumber || !_hasSpecialChar) {
                                        return 'La contraseña no cumple con los requisitos.';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 10),

                                  // --- Requisitos de la contraseña ---
                                  Padding(
                                    padding: const EdgeInsets.only(left: 4.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text("Requisitos de la contraseña:", style: TextStyle(fontWeight: FontWeight.bold)),
                                        SizedBox(height: 8),
                                        _buildValidationRow("Al menos 8 caracteres", _hasMinLength),
                                        const SizedBox(height: 4),
                                        _buildValidationRow("Al menos una letra mayúscula", _hasLetterM),
                                        const SizedBox(height: 4),
                                        _buildValidationRow("Al menos una letra minúscula", _hasLetterm),
                                        const SizedBox(height: 4),
                                        _buildValidationRow("Al menos un número", _hasNumber),
                                        const SizedBox(height: 4),
                                        _buildValidationRow("Al menos un carácter especial", _hasSpecialChar),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(height: 20),

                                  LargeButton(
                                    onTap: _loading ? null : _registerUser,
                                    title: _loading ? 'Registrando...' : 'Registrarme',
                                  ),
                                  const SizedBox(height: 24),

                                  const Row(
                                    children: [
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
                                    onTap: () => context.go('/login'), // Cambiado a login
                                    title: 'Ya tengo una cuenta',
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
}