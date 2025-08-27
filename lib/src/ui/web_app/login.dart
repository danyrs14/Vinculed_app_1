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
      // ✅ Encabezado reutilizable
      appBar: EscomHeader(
        onLoginTap: () => context.go('/login'),
        onRegisterTap: () {
          // cambia esta ruta si tienes pantalla de registro distinta
          context.go('/login');
        },
        onNotifTap: () {
          // lógica para notificaciones (si aplica)
        },
        onMenuSelected: (label) {
          // navegación por menú
          switch (label) {
            case "Inicio":
              context.go('/dashboard');
              break;
            case "Postulaciones":
            // context.go('/postulaciones');
              break;
            case "Experiencias":
            // context.go('/experiencias');
              break;
            case "Mensajes":
            // context.go('/mensajes');
              break;
            case "Preferencias":
            // context.go('/preferencias');
              break;
            case "FAQ":
            // context.go('/faq');
              break;
          }
        },
      ),

      // Stack para superponer footer animado
      body: Stack(
        children: [
          // CONTENIDO SCROLLEABLE
          Positioned.fill(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: SingleChildScrollView(
                  controller: _scrollCtrl,
                  padding: EdgeInsets.fromLTRB(
                    24, 32, 24, _showFooter ? EscomFooter.height + 24 : 24,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Animación
                      Lottie.asset(
                        'assets/images/logen.json', // verifica que exista en pubspec.yaml
                        width: 400,
                        height: 300,
                        fit: BoxFit.cover,
                      ),
                      const SizedBox(height: 24),

                      // Correo institucional
                      TextInput(
                        title: 'Correo institucional',
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 5),

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
                          onTap: () {/* registro candidato */},
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

                      // Relleno para permitir scroll en pantallas altas
                      const SizedBox(height: 300),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // FOOTER ANIMADO (llamando al widget reutilizable)
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
