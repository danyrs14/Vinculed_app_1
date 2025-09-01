import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';

import 'package:vinculed_app_1/src/ui/widgets/elements/header.dart';
import 'package:vinculed_app_1/src/ui/widgets/elements/footer.dart';
import 'package:vinculed_app_1/src/ui/widgets/text_inputs/text_input.dart';
import 'package:vinculed_app_1/src/ui/widgets/buttons/large_buttons.dart';

class RegisterPageWebRec extends StatefulWidget {
  const RegisterPageWebRec({super.key});

  @override
  State<RegisterPageWebRec> createState() => _RegisterPageWebRecState();
}

class _RegisterPageWebRecState extends State<RegisterPageWebRec> {
  // Controllers
  final _nombreCtrl = TextEditingController();
  final _apPaternoCtrl = TextEditingController();
  final _apMaternoCtrl = TextEditingController();
  final _empresaNombreCtrl = TextEditingController();
  final _correoInstitucionalCtrl = TextEditingController();
  final _empresaDireccionCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _passwordConfirmCtrl = TextEditingController();

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

  @override
  void dispose() {
    _scrollCtrl
      ..removeListener(_onScroll)
      ..dispose();
    _nombreCtrl.dispose();
    _apPaternoCtrl.dispose();
    _apMaternoCtrl.dispose();
    _empresaNombreCtrl.dispose();
    _correoInstitucionalCtrl.dispose();
    _empresaDireccionCtrl.dispose();
    _passwordCtrl.dispose();
    _passwordConfirmCtrl.dispose();
    super.dispose();
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
                                TextInput(title: 'Nombre', controller: _nombreCtrl),
                                const SizedBox(height: 12),
                                TextInput(title: 'Apellido Paterno', controller: _apPaternoCtrl),
                                const SizedBox(height: 12),
                                TextInput(title: 'Apellido Materno', controller: _apMaternoCtrl),
                                const SizedBox(height: 12),
                                TextInput(
                                  title: 'Nombre de la Empresa',
                                  controller: _empresaNombreCtrl,
                                ),
                                const SizedBox(height: 12),
                                TextInput(
                                  title: 'Correo Institucional',
                                  controller: _correoInstitucionalCtrl,
                                  keyboardType: TextInputType.emailAddress,
                                ),
                                const SizedBox(height: 12),
                                TextInput(
                                  title: 'Dirección de la Empresa',
                                  controller: _empresaDireccionCtrl,
                                ),
                                const SizedBox(height: 12),
                                TextInput(
                                  title: 'Contraseña',
                                  controller: _passwordCtrl,
                                ),
                                const SizedBox(height: 12),
                                TextInput(
                                  title: 'Confirmar Contraseña',
                                  controller: _passwordConfirmCtrl,
                                ),

                                const SizedBox(height: 20),

                                LargeButton(
                                  onTap: _onRegister,
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
