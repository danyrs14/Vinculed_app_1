import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:vinculed_app_1/src/ui/widgets/buttons/simple_buttons.dart';
import 'package:vinculed_app_1/src/ui/widgets/elements/header.dart'; // EscomHeader
import 'package:vinculed_app_1/src/ui/widgets/elements/footer.dart'; // EscomFooter

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
    final w = MediaQuery.of(context).size.width;
    final isMobile = w < 700;

    return Scaffold(
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
                                        'assets/images/amlo.jpg', // pon tu imagen
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

                                // Tarjetas de vacantes (responsive)
                                _JobsGrid(
                                  items: const [
                                    JobItem(
                                      title: 'Becario de Qwert',
                                      location: 'Ciudad de México',
                                      company: 'BBVA México',
                                    ),
                                    JobItem(
                                      title: 'Becario Scrum',
                                      location: 'Ciudad de México',
                                      company: 'IDS',
                                    ),
                                    JobItem(
                                      title: 'Becario de TI',
                                      location: 'Ciudad de México',
                                      company: 'Banorte IXE',
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
                                            onTap: () {},
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
                                            onTap: () {},
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

/* =========================
 *  Widgets auxiliares
 * ========================= */

class JobItem {
  final String title;
  final String location;
  final String company;
  const JobItem({
    required this.title,
    required this.location,
    required this.company,
  });
}

class _JobsGrid extends StatelessWidget {
  const _JobsGrid({required this.items});

  final List<JobItem> items;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    // Tarjeta ~340px; con márgenes/espaciado cabe 1–3 por fila
    final cardWidth = w < 420 ? w - 48 : 340.0;

    return Wrap(
      spacing: 28,
      runSpacing: 28,
      alignment: WrapAlignment.spaceBetween,
      children: items
          .map(
            (e) => ConstrainedBox(
          constraints: BoxConstraints.tightFor(width: cardWidth),
          child: _JobCard(item: e),
        ),
      )
          .toList(),
    );
  }
}

class _JobCard extends StatelessWidget {
  const _JobCard({required this.item});

  final JobItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 22, 18, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFF6EA8C2), width: 1.4),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            item.title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            item.location,
            style: const TextStyle(color: Colors.black54),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            item.company,
            style: const TextStyle(fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 18),

          // Acciones
          Row(
            children: [
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.favorite_border),
                tooltip: 'Guardar',
              ),
              const Spacer(),
              SizedBox(
                height: 36,
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0E78A5),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    elevation: 0,
                  ),
                  child: const Text('Postularme'),
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.visibility_off_outlined),
                tooltip: 'Ocultar',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

