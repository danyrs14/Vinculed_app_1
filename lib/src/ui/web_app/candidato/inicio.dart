import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:vinculed_app_1/src/core/controllers/theme_controller.dart';

import 'package:vinculed_app_1/src/ui/widgets/buttons/simple_buttons.dart';
import 'package:vinculed_app_1/src/ui/widgets/elements/header.dart';
import 'package:vinculed_app_1/src/ui/widgets/elements/footer.dart';
import 'package:vinculed_app_1/src/ui/widgets/elements/job_card.dart';

class HomeRegisteredPage extends StatefulWidget {
  const HomeRegisteredPage({super.key});

  @override
  State<HomeRegisteredPage> createState() => _HomeRegisteredPageState();
}

class _HomeRegisteredPageState extends State<HomeRegisteredPage> {
  final _scrollCtrl = ScrollController();
  bool _showFooter = false;

  static const double _footerReservedSpace = EscomFooter.height;
  static const double _extraBottomPadding = 24.0;
  static const double _atEndThreshold = 4.0;

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _onScroll());
  }

  void _onScroll() {
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
      ..removeListener(_onScroll)
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
      appBar: EscomHeader(
        onLoginTap: () => context.go('/login'),
        onRegisterTap: () => context.go('/signin'),
        onNotifTap: () {},
        onMenuSelected: (label) {
          switch (label) {
            case "Inicio":
              context.go('/dashboard');
              break;
          }
        },
      ),
      body: Stack(
        children: [
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
                    padding: const EdgeInsets.only(
                      bottom: _footerReservedSpace + _extraBottomPadding,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1200),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: minBodyHeight > 0 ? minBodyHeight : 0,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Saludo con avatar
                                Row(
                                  children: [
                                    const CircleAvatar(
                                      radius: 28,
                                      backgroundImage: AssetImage(
                                        'assets/images/amlo.jpg',
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Text(
                                        'Bienvenido de Nuevo -  @Usuario_Registrado',
                                        style: TextStyle(
                                          fontSize: isMobile ? 22 : 28,
                                          fontWeight: FontWeight.w800,
                                          color: const Color(0xFF22313F),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 28),

                                // Row con 3 JobCards de ejemplo
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: const [
                                    Expanded(
                                      child: Padding(
                                        padding: EdgeInsets.symmetric(horizontal: 8.0),
                                        child: JobCard(
                                          item: JobItem(
                                            title: 'Becario de QA',
                                            location: 'Ciudad de México',
                                            company: 'BBVA México',
                                          ),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Padding(
                                        padding: EdgeInsets.symmetric(horizontal: 8.0),
                                        child: JobCard(
                                          item: JobItem(
                                            title: 'Becario Scrum',
                                            location: 'Ciudad de México',
                                            company: 'IDS',
                                          ),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Padding(
                                        padding: EdgeInsets.symmetric(horizontal: 8.0),
                                        child: JobCard(
                                          item: JobItem(
                                            title: 'Becario de TI',
                                            location: 'Ciudad de México',
                                            company: 'Banorte IXE',
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 28),

                                // Botones grandes inferior (responsive)
                                LayoutBuilder(
                                  builder: (context, c) {
                                    final stackButtons = c.maxWidth < 680;
                                    if (stackButtons) {
                                      return Column(
                                        children: [
                                          SimpleButton(
                                            title: 'Buscar Vacantes',
                                            onTap: () => context.go('/busqueda_job'),
                                          ),
                                          const SizedBox(height: 16),
                                          SimpleButton(
                                            title: 'Notificaciones',
                                            onTap: () {},
                                          ),
                                        ],
                                      );
                                    }
                                    return Row(
                                      children: [
                                        Expanded(
                                          child: SimpleButton(
                                            title: 'Buscar Vacantes',
                                            onTap: () => context.go('/busqueda_job'),
                                          ),
                                        ),
                                        const SizedBox(width: 24),
                                        Expanded(
                                          child: SimpleButton(
                                            title: 'Notificaciones',
                                            onTap: () {},
                                          ),
                                        ),
                                      ],
                                    );
                                  },
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

          // Footer animado (aparece al final)
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
