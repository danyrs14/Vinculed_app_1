import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:vinculed_app_1/src/core/controllers/theme_controller.dart';
import 'package:vinculed_app_1/src/ui/widgets/buttons/mini_buttons.dart';
import 'package:vinculed_app_1/src/ui/widgets/buttons/simple_buttons.dart';
import 'package:vinculed_app_1/src/ui/widgets/elements/footer.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  final _scrollCtrl = ScrollController();
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
    _scrollCtrl
      ..removeListener(_onScroll)
      ..dispose();
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
            onPressed: () {
              context.go('/login');
            },
            child: Text(
              "Iniciar Sesión",
              style: TextStyle(color: theme.secundario(), fontWeight: FontWeight.bold),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: MiniButton(
              onTap: () {
                context.go('/login');
              },
              title: "Registrarse",
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications),
          ),
        ],
      ),

      body: Stack(
        children: [
          // CONTENIDO SCROLLEABLE CENTRADO
          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 800;
                final minBodyHeight =
                    constraints.maxHeight - (_showFooter ? EscomFooter.height : 0) - 24;

                return SingleChildScrollView(
                  controller: _scrollCtrl,
                  padding: EdgeInsets.only(
                    bottom: _showFooter ? EscomFooter.height + 24 : 24,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1100),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                        child: ConstrainedBox(
                          constraints:
                          BoxConstraints(minHeight: minBodyHeight > 0 ? minBodyHeight : 0),
                          child: isNarrow
                              ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const SizedBox(height: 8),
                              const Text(
                                "¡Mejores\nOportunidades nos\nesperan!",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 20),
                              SizedBox(
                                width: 220,
                                child: SimpleButton(
                                  onTap: () {},
                                  title: "Postularse",
                                ),
                              ),
                              const SizedBox(height: 24),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.asset(
                                  'assets/images/illustration.png',
                                  height: 220,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              const SizedBox(height: 24),
                            ],
                          )
                              : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Flexible(
                                flex: 5,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      "¡Mejores\nOportunidades nos\nesperan!",
                                      style: TextStyle(
                                        fontSize: 44,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                        height: 1.1,
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    SizedBox(
                                      width: 240,
                                      child: SimpleButton(
                                        onTap: () {},
                                        title: "Postularse",
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 48),
                              Flexible(
                                flex: 5,
                                child: Center(
                                  child: Lottie.asset(
                                    'assets/images/dashboard.json',
                                    width: 400,
                                    height: 300,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
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

          // FOOTER ANIMADO LLAMANDO AL NUEVO WIDGET
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

  Widget _navButton(String text) {
    return TextButton(
      onPressed: () {},
      child: Text(text, style: const TextStyle(color: Colors.black87)),
    );
  }
}
