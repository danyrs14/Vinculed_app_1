import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:vinculed_app_1/src/ui/widgets/buttons/simple_buttons.dart';
import 'package:vinculed_app_1/src/ui/widgets/elements/footer.dart';  // EscomFooter
import 'package:vinculed_app_1/src/ui/widgets/elements/header.dart';  // EscomHeader

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  final _scrollCtrl = ScrollController();
  bool _showFooter = false;

  // === Ajustes para footer al final ===
  static const double _footerReservedSpace = EscomFooter.height; // reservar SIEMPRE el espacio
  static const double _extraBottomPadding  = 24.0;
  static const double _atEndThreshold      = 4.0; // umbral pequeño para considerar "fin"

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
    // Evalúa tras el primer frame (por si ya estás al fondo)
    WidgetsBinding.instance.addPostFrameCallback((_) => _onScroll());
  }

  void _onScroll() {
    final pos = _scrollCtrl.position;
    if (!pos.hasPixels || !pos.hasContentDimensions) return;

    // Si no hay scroll suficiente, mantenemos el footer oculto (ajusta a true si lo quieres visible)
    if (pos.maxScrollExtent <= 0) {
      if (_showFooter) setState(() => _showFooter = false);
      return;
    }

    // Mostrar footer cuando se llega al final (con un pequeño margen)
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 700;

    return Scaffold(
      appBar: EscomHeader(
        onLoginTap: () => context.go('/login'),
        onRegisterTap: () => context.go(''),
        onNotifTap: () {
          // lógica de notificaciones
        },
        onMenuSelected: (label) {
          // navegación según opción seleccionada
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

      body: Stack(
        children: [
          // CONTENIDO SCROLLEABLE CENTRADO
          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 800;

                // Reservamos SIEMPRE el espacio del footer para que el final no "salte"
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
                        constraints: const BoxConstraints(maxWidth: 1100),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: minBodyHeight > 0 ? minBodyHeight : 0,
                            ),
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
                  ),
                );
              },
            ),
          ),

          // FOOTER ANIMADO (reutilizable)
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
