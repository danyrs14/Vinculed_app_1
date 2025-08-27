import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
  }

  void _onScroll() {
    final pos = _scrollCtrl.position;
    final isAtTop = pos.pixels <= 0;
    final scrollingDown = pos.userScrollDirection == ScrollDirection.reverse;
    final nextShow = !isAtTop && scrollingDown; // aparece solo al bajar
    if (nextShow != _showFooter) {
      setState(() => _showFooter = nextShow);
    }
  }

  @override
  void dispose() {
    _scrollCtrl..removeListener(_onScroll)..dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 700;

    return Scaffold(
      // ✅ Encabezado reutilizable
      appBar: EscomHeader(
        onLoginTap: () => context.go('/login'),
        onRegisterTap: () => context.go('/register'), // cámbialo si tu ruta de registro es otra
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
          // ✅ SCROLL EN TODA LA PANTALLA (mismo patrón que Dashboard)
          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final minBodyHeight =
                    constraints.maxHeight - (_showFooter ? EscomFooter.height : 0) - 24;

                return SingleChildScrollView(
                  controller: _scrollCtrl,
                  padding: EdgeInsets.only(
                    bottom: _showFooter ? EscomFooter.height + 24 : 24,
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
                              // Animación encapsulada para no invadir los inputs
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
                                  onTap: () => context.go('/register'),
                                  title: 'Registrarme como Candidato',
                                ),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                height: 44,
                                child: LargeButton(
                                  onTap: () {/* registro reclutador */},
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
                );
              },
            ),
          ),

          // ✅ FOOTER ANIMADO (reutilizable)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: AnimatedSlide(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              offset: _showFooter ? Offset.zero : const Offset(0, 1),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 250),
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
