import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:vinculed_app_1/src/core/controllers/theme_controller.dart';
import 'package:vinculed_app_1/src/ui/widgets/buttons/large_buttons.dart';
import 'package:vinculed_app_1/src/ui/widgets/buttons/mini_buttons.dart';
import 'package:vinculed_app_1/src/ui/widgets/elements/footer.dart';
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
    final theme = ThemeController.instance;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 700;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.background(),
        elevation: 0,
        titleSpacing: 20,
        title: Row(
          children: [
            Image.asset('assets/images/escom.png', height: 40),
            const SizedBox(width: 10),
          ],
        ),
        actions: isMobile
            ? [
          PopupMenuButton<String>(
            icon: const Icon(Icons.menu),
            onSelected: (value) {},
            itemBuilder: (context) => const [
              PopupMenuItem(value: "Inicio", child: Text("Inicio")),
              PopupMenuItem(value: "Postulaciones", child: Text("Postulaciones")),
              PopupMenuItem(value: "Experiencias", child: Text("Experiencias")),
              PopupMenuItem(value: "Mensajes", child: Text("Mensajes")),
              PopupMenuItem(value: "Preferencias", child: Text("Preferencias")),
              PopupMenuItem(value: "FAQ", child: Text("FAQ")),
            ],
          )
        ]
            : [
          _navButton("Inicio"),
          _navButton("Postulaciones"),
          _navButton("Experiencias"),
          _navButton("Mensajes"),
          _navButton("Preferencias"),
          _navButton("FAQ"),
          TextButton(
            onPressed: () => context.go('/login'),
            child: Text(
              "Iniciar Sesión",
              style: TextStyle(color: theme.secundario(), fontWeight: FontWeight.bold),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: MiniButton(
              onTap: () {/* ir a registro */},
              title: "Registrarse",
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications),
          ),
        ],
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
                        'assets/images/logen.json', // Asegúrate de que exista y esté en pubspec.yaml
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

  // ====== Helpers de UI ======
  Widget _navButton(String text) {
    return TextButton(
      onPressed: () {},
      child: Text(text, style: const TextStyle(color: Colors.black87)),
    );
  }
}
