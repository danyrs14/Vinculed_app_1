import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';

import 'package:vinculed_app_1/src/ui/widgets/buttons/large_buttons.dart';
import 'package:vinculed_app_1/src/ui/widgets/elements/footer.dart';
import 'package:vinculed_app_1/src/ui/widgets/elements/header.dart';
import 'package:vinculed_app_1/src/ui/widgets/text_inputs/text_form_field.dart';

class RecuperarPasswordPageWeb extends StatefulWidget {
  const RecuperarPasswordPageWeb({super.key});

  @override
  State<RecuperarPasswordPageWeb> createState() => _RecuperarPasswordPageWebState();
}

class _RecuperarPasswordPageWebState extends State<RecuperarPasswordPageWeb> {
  final _recPassFormKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;

  // Lógica para el footer
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

  @override
  void dispose() {
    _emailController.dispose();
    _scrollCtrl.removeListener(_onScroll);
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _recuperarContrasena() async {
    if (!_recPassFormKey.currentState!.validate() || _isLoading) {
      return;
    }
    setState(() => _isLoading = true);

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: _emailController.text.trim());
      _showMessage("Si estás registrado, se te ha enviado un correo para restablecer tu contraseña. Revisa tu bandeja de entrada.", isError: false);
    } on FirebaseAuthException catch (e) {
      // Manejar errores específicos de Firebase si es necesario
      _showMessage("No se pudo enviar el correo. Verifica que el correo sea correcto y esté registrado.");
    } catch (e) {
      _showMessage("Ocurrió un error inesperado. Por favor, intenta de nuevo.");
    } finally {
      if(mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showMessage(String msg, {bool isError = true}) {
    if(mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: isError ? Colors.redAccent : Colors.green,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

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
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 700;

    return Scaffold(
      appBar: EscomHeader(
        onLoginTap: () => context.go('/login'),
        onRegisterTap: () => context.go('/register'),
        onNotifTap: () {},
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final minBodyHeight =
                    constraints.maxHeight - _footerReservedSpace - _extraBottomPadding;

                return SingleChildScrollView(
                  controller: _scrollCtrl,
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
                          child: Form(
                            key: _recPassFormKey,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Lottie.asset(
                                  'assets/images/logen.json',
                                  height: 180,
                                ),
                                const SizedBox(height: 24),
                                const Text(
                                  'Recupera tu Acceso',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'Ingresa tu correo electrónico y te enviaremos un enlace para que puedas restablecer tu contraseña.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 15, color: Colors.black54),
                                ),
                                const SizedBox(height: 24),
                                StyledTextFormField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  title: "Correo electrónico registrado",
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Por favor, ingresa tu correo electrónico';
                                    }
                                    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
                                    if (!emailRegex.hasMatch(value)) {
                                      return 'Ingresa un correo electrónico válido';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 20),
                                LargeButton(
                                  title: _isLoading ? "Enviando..." : "Enviar Correo",
                                  onTap: _recuperarContrasena,
                                ),
                                const SizedBox(height: 16),
                                LargeButton(
                                  title: "Volver a Iniciar Sesión",
                                  onTap: () => context.go('/login'),
                                ),
                              ],
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
            left: 0, right: 0, bottom: 0,
            child: AnimatedSlide(
              duration: const Duration(milliseconds: 220),
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