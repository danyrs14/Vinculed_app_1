import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:go_router/go_router.dart';
import 'package:vinculed_app_1/src/core/controllers/theme_controller.dart';
import 'package:vinculed_app_1/src/ui/widgets/buttons/mini_buttons.dart';
import 'package:vinculed_app_1/src/ui/widgets/buttons/simple_buttons.dart';

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
  static const double _footerHeight = 240;

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
                    24, 32, 24, _showFooter ? _footerHeight + 24 : 24,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Ilustración con bordes redondeados
                      ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Image.asset(
                          'assets/illustration.png',
                          height: 200,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Correo institucional
                      _input(
                        controller: _emailCtrl,
                        hint: 'Correo Institucional',
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 16),

                      // Contraseña
                      _input(
                        controller: _passCtrl,
                        hint: 'Contraseña',
                        isPassword: true,
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
                      SimpleButton(
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
                        child: ElevatedButton(
                          onPressed: () {/* registro candidato */},
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('Registrarme como Candidato'),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 44,
                        child: ElevatedButton(
                          onPressed: () {/* registro reclutador */},
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('Registrarme como Reclutador'),
                        ),
                      ),

                      // Contenido extra para permitir scroll en pantallas altas
                      const SizedBox(height: 400),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // FOOTER ANIMADO
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
                child: _footer(screenWidth < 700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ====== Helpers de UI ======

  Widget _input({
    required TextEditingController controller,
    required String hint,
    bool isPassword = false,
    TextInputType? keyboardType,
  }) {
    return SizedBox(
      height: 48,
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          hintText: hint,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(width: 1.6, color: Color(0xFF64B5F6)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(width: 1.6, color: Color(0xFF64B5F6)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(width: 2, color: Color(0xFF1E88E5)),
          ),
        ),
      ),
    );
  }

  Widget _navButton(String text) {
    return TextButton(
      onPressed: () {},
      child: Text(text, style: const TextStyle(color: Colors.black87)),
    );
  }


  Widget _footer(bool isMobile) {
    return Container(
      height: _footerHeight,
      color: const Color(0xFF2B2F33),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
      child: isMobile
          ? Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("ESCOM", style: TextStyle(color: Colors.white, fontSize: 20)),
          const SizedBox(height: 10),
          const Text(
            "Copyright © 2025\nDerechos Reservados",
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 20),
          _footerColumn("Equipo TT", ["Acerca de", "Blog", "Contactanos", "Pricing", "Testimonials"]),
          const SizedBox(height: 20),
          _footerColumn("Soporte", ["Emergencias", "Ayuda", "Ubicacion", "Privacy policy", "Status"]),
          const SizedBox(height: 20),
          _footerSubscribe(),
        ],
      )
          : Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("ESCOM", style: TextStyle(color: Colors.white, fontSize: 20)),
              SizedBox(height: 10),
              Text(
                "Copyright © 2025\nDerechos Reservados",
                style: TextStyle(color: Colors.white70),
              )
            ],
          ),
          const Spacer(),
          _footerColumn("Equipo TT", ["Acerca de", "Blog", "Contactanos", "Pricing", "Testimonials"]),
          const SizedBox(width: 60),
          _footerColumn("Soporte", ["Emergencias", "Ayuda", "Ubicacion", "Privacy policy", "Status"]),
          const SizedBox(width: 60),
          _footerSubscribe(),
        ],
      ),
    );
  }

  static Widget _footerSubscribe() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Conócenos", style: TextStyle(color: Colors.white, fontSize: 16)),
        const SizedBox(height: 10),
        SizedBox(
          width: 200,
          child: TextField(
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: "Correo Electrónico",
              hintStyle: const TextStyle(color: Colors.white70),
              filled: true,
              fillColor: Colors.grey,
              suffixIcon: const Icon(Icons.send, color: Colors.white70),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        )
      ],
    );
  }

  static Widget _footerColumn(String title, List<String> links) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: Colors.white, fontSize: 16)),
        const SizedBox(height: 5),
        for (var link in links)
          TextButton(
            onPressed: () {},
            style: TextButton.styleFrom(padding: EdgeInsets.zero),
            child: Text(link, style: const TextStyle(color: Colors.white70)),
          ),
      ],
    );
  }
}
