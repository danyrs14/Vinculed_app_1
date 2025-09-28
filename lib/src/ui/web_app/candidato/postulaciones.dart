import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:vinculed_app_1/src/core/controllers/theme_controller.dart';
import 'package:vinculed_app_1/src/ui/widgets/elements/footer.dart';
import 'package:vinculed_app_1/src/ui/widgets/elements/header2.dart';
import 'package:vinculed_app_1/src/ui/widgets/elements/postulacion_card.dart';

class MyApplicationsPage extends StatefulWidget {
  const MyApplicationsPage({super.key});

  @override
  State<MyApplicationsPage> createState() => _MyApplicationsPageState();
}

class _MyApplicationsPageState extends State<MyApplicationsPage> {
  final _scrollCtrl = ScrollController();
  bool _showFooter = false;

  static const double _footerReservedSpace = EscomFooter.height;
  static const double _extraBottomPadding = 24.0;
  static const double _atEndThreshold = 4.0;

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_handleScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _handleScroll());
  }

  void _handleScroll() {
    final pos = _scrollCtrl.position;
    if (!pos.hasPixels || !pos.hasContentDimensions) return;

    if (pos.maxScrollExtent <= 0) {
      if (_showFooter) setState(() => _showFooter = false);
      return;
    }

    final atBottom = pos.pixels >= (pos.maxScrollExtent - _atEndThreshold);
    if (atBottom != _showFooter) setState(() => _showFooter = atBottom);
  }

  @override
  void dispose() {
    _scrollCtrl
      ..removeListener(_handleScroll)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;
    final w = MediaQuery.of(context).size.width;
    final isMobile = w < 700;

    return Scaffold(
      backgroundColor: theme.background(),
      appBar: EscomHeader2(
        onLoginTap: () => context.go('/perfil_cand'),
        onRegisterTap: () => context.go('/signin'),
        onNotifTap: () {},
        onMenuSelected: (label) {
          switch (label) {
            case "Inicio":
              context.go('/inicio_cand');
              break;

            case "Postulaciones":
              context.go('/mis_postulaciones');
              break;

            case "Mensajes":
              context.go('/messages');
              break;

            case "Experiencias":
              context.go('/experiencias');
              break;

            case "FAQ":
              context.go('/faq');
              break;

            case "Preferencias":
              context.go('/preferences');
              break;

          }
        },
      ),

      body: Stack(
        children: [
          // Scroll global con padding inferior para el footer
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
                      _handleScroll();
                    }
                    return false;
                  },
                  child: SingleChildScrollView(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.only(
                      bottom: _footerReservedSpace + _extraBottomPadding,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1100),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: minBodyHeight > 0 ? minBodyHeight : 0,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // Título fuera del Row
                                Text(
                                  'Mis Postulaciones',
                                  style: TextStyle(
                                    fontSize: isMobile ? 26 : 32,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF22313F),
                                  ),
                                ),
                                const SizedBox(height: 28),

                                // Row con cards en la misma fila
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: const [
                                    ApplicationCard(
                                      title: 'Becario de QA',
                                      company: 'BBVA Mexico',
                                      location: 'Ciudad de Mexico',
                                      statusLabel: 'POSTULADO',
                                    ),
                                    ApplicationCard(
                                      title: 'Becario Scrum',
                                      company: 'IDS',
                                      location: 'Ciudad de Mexico',
                                      statusLabel: 'POSTULADO',
                                    ),
                                    ApplicationCard(
                                      title: 'Becario de TI',
                                      company: 'Banorte IXE',
                                      location: 'Ciudad de Mexico',
                                      statusLabel: 'POSTULADO',
                                    ),
                                  ],
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

          // Footer animado (aparece al final del scroll)
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
