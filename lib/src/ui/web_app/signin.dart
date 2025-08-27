import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';

import 'package:vinculed_app_1/src/ui/widgets/elements/header.dart';
import 'package:vinculed_app_1/src/ui/widgets/elements/footer.dart';
import 'package:vinculed_app_1/src/ui/widgets/text_inputs/text_input.dart';
import 'package:vinculed_app_1/src/ui/widgets/buttons/large_buttons.dart';

class RegisterPageWeb extends StatefulWidget {
  const RegisterPageWeb({super.key});

  @override
  State<RegisterPageWeb> createState() => _RegisterPageWebState();
}

class _RegisterPageWebState extends State<RegisterPageWeb> {
  // Controllers
  final _nombreCtrl = TextEditingController();
  final _apPaternoCtrl = TextEditingController();
  final _apMaternoCtrl = TextEditingController();
  final _correoCtrl = TextEditingController();
  final _carreraCtrl = TextEditingController();
  final _edadCtrl = TextEditingController();
  final _semestreCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

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
    final nextShow = !isAtTop && scrollingDown;
    if (nextShow != _showFooter) {
      setState(() => _showFooter = nextShow);
    }
  }

  @override
  void dispose() {
    _scrollCtrl..removeListener(_onScroll)..dispose();
    _nombreCtrl.dispose();
    _apPaternoCtrl.dispose();
    _apMaternoCtrl.dispose();
    _correoCtrl.dispose();
    _carreraCtrl.dispose();
    _edadCtrl.dispose();
    _semestreCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 700;

    return Scaffold(
      // Encabezado reutilizable
      appBar: EscomHeader(
        onLoginTap: () => context.go('/login'),
        onRegisterTap: () => context.go('/register'),
        onNotifTap: () {},
        onMenuSelected: (label) {
          switch (label) {
            case "Inicio":
              context.go('/dashboard');
              break;
          // Agrega aquí tus rutas reales
          }
        },
      ),

      // Contenido + footer animado
      body: Stack(
        children: [
          Positioned.fill(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 620),
                child: SingleChildScrollView(
                  controller: _scrollCtrl,
                  padding: EdgeInsets.fromLTRB(
                    24, 32, 24, _showFooter ? EscomFooter.height + 24 : 24,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Ilustración superior
                      Lottie.asset(
                        'assets/images/logen.json', // verifica que exista en pubspec.yaml
                        width: 400,
                        height: 300,
                        fit: BoxFit.cover,
                      ),
                      const SizedBox(height: 50),

                      // Inputs
                      TextInput(title: 'Nombre', controller: _nombreCtrl),
                      const SizedBox(height: 12),
                      TextInput(title: 'Apellido Paterno', controller: _apPaternoCtrl),
                      const SizedBox(height: 12),
                      TextInput(title: 'Apellido Materno', controller: _apMaternoCtrl),
                      const SizedBox(height: 12),
                      TextInput(
                        title: 'Correo Institucional',
                        controller: _correoCtrl,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 12),
                      TextInput(title: 'Carrera', controller: _carreraCtrl),
                      const SizedBox(height: 12),
                      TextInput(
                        title: 'Edad',
                        controller: _edadCtrl,
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 12),
                      TextInput(
                        title: 'Semestre',
                        controller: _semestreCtrl,
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 12),
                      TextInput(title: 'Contraseña', controller: _passCtrl),

                      const SizedBox(height: 20),

                      // Botón Registrarme
                      LargeButton(
                        onTap: _onRegister,
                        title: 'Registrarme',
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

                      // Botón Iniciar Sesión
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

          // Footer animado
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

  void _onRegister() {
    // Aquí validas y envías tu formulario.
    // Por ahora solo ejemplo:
    // print('Enviar registro con: ${_pngbreCtrl.text} ...');
  }
}
