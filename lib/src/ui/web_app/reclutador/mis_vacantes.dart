import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:vinculed_app_1/src/core/controllers/theme_controller.dart';
import 'package:vinculed_app_1/src/ui/widgets/elements/footer.dart';
import 'package:vinculed_app_1/src/ui/widgets/elements/header3.dart';

class MyVacanciesPage extends StatefulWidget {
  const MyVacanciesPage({super.key});

  @override
  State<MyVacanciesPage> createState() => _MyVacanciesPageState();
}

class _MyVacanciesPageState extends State<MyVacanciesPage> {
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
      appBar: EscomHeader3(
        onLoginTap: () => context.go('/perfil_cand'),
        onRegisterTap: () => context.go('/signin'),
        onNotifTap: () {},
        onMenuSelected: (label) {
          switch (label) {
            case "Inicio":
              context.go('/inicio_rec');
              break;
            case "Crear Vacante":
              context.go('/new_vacancy');
              break;
            case "Mis Vacantes":
              context.go('/my_vacancy');
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
                        constraints: const BoxConstraints(maxWidth: 1100),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: (constraints.maxHeight -
                                  _footerReservedSpace -
                                  _extraBottomPadding)
                                  .clamp(0, double.infinity),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // Título centrado
                                Text(
                                  'Mis Vacantes',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: isMobile ? 26 : 32,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF22313F),
                                  ),
                                ),
                                const SizedBox(height: 28),

                                // Tarjeta centrada (como en la imagen)
                                ConstrainedBox(
                                  constraints: const BoxConstraints(maxWidth: 520),
                                  child: _VacancyCard(
                                    title: 'Becario de QA',
                                    company: 'BBVA Mexico',
                                    location: 'Ciudad de Mexico',
                                    statusText: 'PUBLICADA',
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

/*──────────────────────────── Tarjeta de Vacante ───────────────────────────*/

class _VacancyCard extends StatelessWidget {
  const _VacancyCard({
    required this.title,
    required this.company,
    required this.location,
    required this.statusText,
  });

  final String title;
  final String company;
  final String location;
  final String statusText;

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 22),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black54, width: 1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 18,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            company,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            location,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),

          // Ícono centrado (círculo)
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.black54, width: 1.6),
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.expand_more, size: 18, color: Colors.black87),
          ),

          const SizedBox(height: 16),
          Text(
            statusText.toUpperCase(),
            style: TextStyle(
              color: theme.secundario(),
              fontWeight: FontWeight.w800,
              letterSpacing: .2,
            ),
          ),
        ],
      ),
    );
  }
}
