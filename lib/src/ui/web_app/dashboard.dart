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
    WidgetsBinding.instance.addPostFrameCallback((_) => _onScroll());
  }

  void _onScroll() {
    if (!_scrollCtrl.hasClients) return;
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
  void dispose() {
    _scrollCtrl
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    // Breakpoints simples
    final isMobile = width < 700;
    final isTablet = width >= 700 && width < 1100;

    // Tipografías responsivas
    final titleStyle = TextStyle(
      fontSize: isMobile ? 30 : (isTablet ? 38 : 44),
      fontWeight: FontWeight.bold,
      color: Colors.black87,
      height: 1.1,
    );

    // Tamaños responsivos para Lottie
    double lottieW;
    double lottieH;
    if (isMobile) {
      lottieW = width.clamp(260, 420);
      lottieH = lottieW * 0.7;
    } else if (isTablet) {
      lottieW = 460;
      lottieH = 340;
    } else {
      lottieW = 520;
      lottieH = 380;
    }

    return Scaffold(
      appBar: const EscomHeader(
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
                            // ======= LAYOUT MÓVIL/TABLET (COLUMN) =======
                                ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const SizedBox(height: 8),
                                Text(
                                  "¡Mejores\nOportunidades nos\nesperan!",
                                  textAlign: TextAlign.center,
                                  style: titleStyle,
                                ),
                                const SizedBox(height: 20),

                                // >>> Aquí van los botones en lugar de "Postularse" (solo móvil/tablet)
                                _AuthActionsRowMobile(
                                  onLogin: () => context.go('/login'),
                                  onRegister: () => context.go('/lector_qr'),
                                ),

                                const SizedBox(height: 24),
                                // Lottie centrado
                                Align(
                                  alignment: Alignment.center,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: SizedBox(
                                      width: lottieW,
                                      height: lottieH,
                                      child: Lottie.asset(
                                        'assets/images/dashboard.json',
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),
                              ],
                            )
                            // ======= LAYOUT DESKTOP (ROW) =======
                                : Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // Columna izquierda (texto + CTA)
                                Expanded(
                                  flex: 1,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "¡Mejores\nOportunidades nos\nesperan!",
                                        style: titleStyle,
                                      ),
                                      const SizedBox(height: 24),
                                      SizedBox(
                                        width: 240,
                                        child: SimpleButton(
                                          onTap: () {
                                            context.go('/login');
                                          },
                                          title: "Empecemos",
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 24),
                                // Lottie centrado en su mitad
                                Expanded(
                                  flex: 1,
                                  child: Align(
                                    alignment: Alignment.center,
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(16),
                                      child: SizedBox(
                                        width: lottieW,
                                        height: lottieH,
                                        child: Lottie.asset(
                                          'assets/images/dashboard.json',
                                          fit: BoxFit.contain,
                                        ),
                                      ),
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

class _AuthActionsRowMobile extends StatelessWidget {
  const _AuthActionsRowMobile({
    required this.onLogin,
    required this.onRegister,
  });

  final VoidCallback onLogin;
  final VoidCallback onRegister;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, c) {
        final maxW = c.maxWidth;
        final isTight = maxW < 360;
        return Wrap(
          alignment: WrapAlignment.center,
          spacing: 12,
          runSpacing: 8,
          children: [
            SimpleButton(
              onTap: () {
                context.go('/login');
              },
              title: 'Empecemos',
            ),
          ],
        );
      },
    );
  }
}
