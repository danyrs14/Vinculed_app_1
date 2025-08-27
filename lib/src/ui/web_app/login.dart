import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';

import 'package:vinculed_app_1/src/ui/widgets/buttons/large_buttons.dart';
import 'package:vinculed_app_1/src/ui/widgets/elements/footer.dart';
import 'package:vinculed_app_1/src/ui/widgets/elements/header.dart';
import 'package:vinculed_app_1/src/ui/widgets/text_inputs/text_input.dart';

class LoginPageWeb extends StatefulWidget {
  const LoginPageWeb({super.key});

  @override
  State<LoginPageWeb> createState() => _LoginPageWebState();
}

class _LoginPageWebState extends State<LoginPageWeb> {
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();

  final ScrollController _scrollCtrl = ScrollController();
  bool _showFooter = false;

  // Reservamos SIEMPRE espacio para el footer
  static const double _footerReservedSpace = EscomFooter.height;
  static const double _extraBottomPadding  = 24.0;

  // Umbral pequeño para considerar “fin de scroll”
  static const double _atEndThreshold = 4.0;

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
    // Evalúa también tras el primer frame (por si ya estás al final)
    WidgetsBinding.instance.addPostFrameCallback((_) => _onScroll());
  }

  void _onScroll() {
    final pos = _scrollCtrl.position;
    if (!pos.hasPixels || !pos.hasContentDimensions) return;

    // Si no hay scroll, mantenemos oculto el footer (cámbialo a true si lo quieres visible siempre)
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
      // Encabezado reutilizable
      appBar: EscomHeader(
        onLoginTap: () => context.go('/login'),
        onRegisterTap: () => context.go('/register'), // cambia si tu ruta es distinta
        onNotifTap: () {},
        onMenuSelected: (label) {
          switch (label) {
            case "Inicio":
              context.go('/dashboard');
              break;
          // agrega otras rutas si las usas
          }
        },
      ),

      body: Stack(
        children: [
          // SCROLL GLOBAL con espacio del footer reservado
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
                        constraints: const BoxConstraints(maxWidth: 520),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: minBodyHeight > 0 ? minBodyHeight : 0,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Animación encapsulada
                                Align(
                                  alignment: Alignment.center,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: SizedBox(
                                      height: 180,
                                      width: 280,
                                      child: Lottie.asset(
                                        'assets/images/logen.json', // asegúrate de declararlo en pubspec.yaml
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 28),

                                // Correo institucional
                                TextInput(
                                  title: 'Correo institucional',
                                  controller: _emailCtrl,
                                  keyboardType: TextInputType.emailAddress,
                                ),
                                const SizedBox(height: 12),

                                // Contraseña
                                TextInput(
                                  controller: _passCtrl,
                                  title: 'Contraseña',
                                ),

                                // "Se me olvidó la contraseña"
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: () {/* recuperar contraseña */},
                                    child: const Text('Se me olvidó la contraseña'),
                                  ),
                                ),

                                // Botón Iniciar Sesión
                                LargeButton(
                                  onTap: () {/* login */},
                                  title: 'Iniciar Sesión',
                                ),

                                const SizedBox(height: 24),

                                // Separador OR
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

                                // Botones de registro
                                SizedBox(
                                  height: 44,
                                  child: LargeButton(
                                    onTap: () => context.go('/signin'),
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
                );
              },
            ),
          ),

          // Footer (aparece inmediatamente al llegar al final)
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
