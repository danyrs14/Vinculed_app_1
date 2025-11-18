import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';

import 'package:vinculed_app_1/src/ui/widgets/buttons/large_buttons.dart';
import 'package:vinculed_app_1/src/ui/widgets/elements/footer.dart';
import 'package:vinculed_app_1/src/ui/widgets/elements/header.dart';
// Se cambia a TextFormField para usar validadores
import 'package:vinculed_app_1/src/ui/widgets/text_inputs/text_form_field.dart';

class LoginPageWeb extends StatefulWidget {
  const LoginPageWeb({super.key});

  @override
  State<LoginPageWeb> createState() => _LoginPageWebState();
}

class _LoginPageWebState extends State<LoginPageWeb> {
  // Key y controllers para el formulario
  final _loginFormKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  
  // Estado para la carga
  bool _isLoading = false;

  // Lógica para el footer (sin cambios)
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
  }
  
  // --- Lógica de Inicio de Sesión (adaptada de la vista móvil) ---
  
  Future<void> _login() async {
    if (_isLoading) return; // Prevenir múltiples clics
    
    // Validar el formulario antes de proceder
    if (!_loginFormKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text.trim(),
      );
      // Si el login es exitoso, Firebase Auth notifica a su listener y
      // la app redirigirá automáticamente. Si no, puedes forzar la navegación:
      // if (mounted) context.go('/dashboard');
      
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
          errorMessage = "No se encontró un usuario con ese correo.";
          break;
        case 'invalid-credential':
           errorMessage = "El correo electrónico o la contraseña no son válidos.";
          break;
        default:
          errorMessage = "Error de autenticación: Verifique sus credenciales.";
      }
      _showError(errorMessage);
    } catch (e) {
      _showError("Ocurrió un error inesperado, intenta de nuevo.");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
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
    _emailCtrl.dispose();
    _passCtrl.dispose();
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
                    _onScroll();
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
                        constraints: const BoxConstraints(maxWidth: 520),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: minBodyHeight > 0 ? minBodyHeight : 0,
                            ),
                            child: Form( // Envolvemos en un Form
                              key: _loginFormKey,
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

                                  // Campo de Correo con validación
                                  StyledTextFormField(
                                    isRequired: true,
                                    title: 'Correo institucional',
                                    controller: _emailCtrl,
                                    keyboardType: TextInputType.emailAddress,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Por favor, ingresa tu correo.';
                                      }
                                      final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                                      if (!emailRegex.hasMatch(value)) {
                                        return 'Ingresa un correo válido.';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 12),

                                  // Campo de Contraseña con validación
                                  StyledTextFormField(
                                    isRequired: true,
                                    controller: _passCtrl,
                                    title: 'Contraseña',
                                    obscureText: true,
                                    isPasswordField: true,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Por favor, ingresa tu contraseña.';
                                      }
                                      return null;
                                    },
                                  ),

                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton(
                                      onPressed: () => context.go('/recover_password'), // Navegación con go_router
                                      child: const Text('Se me olvidó la contraseña'),
                                    ),
                                  ),

                                  // Botón de Iniciar Sesión con estado de carga
                                  LargeButton(
                                    onTap: _isLoading ? null : _login,
                                    title: _isLoading ? 'Iniciando...' : 'Iniciar Sesión',
                                  ),

                                  const SizedBox(height: 24),
                                  
                                  // --- Resto de la UI sin cambios ---
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
                                  SizedBox(
                                    height: 44,
                                    child: LargeButton(
                                      onTap: () => context.go('/lector_qr'),
                                      title: 'Registrarme como Candidato',
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    height: 44,
                                    child: LargeButton(
                                      onTap: () => context.go('/signin_rec'),
                                      title: 'Registrarme como Reclutador',
                                    ),
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

          // Footer animado
          Positioned(
            left: 0, right: 0, bottom: 0,
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
          
          // Indicador de carga superpuesto
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }
}