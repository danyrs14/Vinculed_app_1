import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:vinculed_app_1/src/core/controllers/theme_controller.dart';
import 'package:vinculed_app_1/src/ui/widgets/buttons/simple_buttons.dart';
import 'package:vinculed_app_1/src/ui/widgets/elements/footer.dart';
import 'package:vinculed_app_1/src/ui/widgets/elements/header3.dart';

class VacancyDetailPage extends StatefulWidget {
  const VacancyDetailPage({super.key});

  @override
  State<VacancyDetailPage> createState() => _VacancyDetailPageState();
}

class _VacancyDetailPageState extends State<VacancyDetailPage> {
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
    final isMobile = w < 880;

    return Scaffold(
      backgroundColor: theme.background(),
      appBar: EscomHeader3(
        onLoginTap: () => context.go('/perfil_rec'),
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
            case "Postulaciones":
              context.go('/postulaciones');
              break;
            case "FAQ":
              context.go('/faq_rec');
              break;
            case "Mensajes":
              context.go('/msg_rec');
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
                            constraints: BoxConstraints(minHeight: minBodyHeight > 0 ? minBodyHeight : 0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // ───────── Barra superior de acciones ─────────
                                if (isMobile)
                                  Column(
                                    children: [
                                      SimpleButton(
                                        title: 'Cerrar Vacante',
                                        onTap: () {},
                                      ),
                                    ],
                                  )
                                else
                                  Row(
                                    children: [
                                      SizedBox(
                                        width: 220,
                                        child: SimpleButton(title: 'Cerrar Vacante', onTap: () {}),
                                      ),
                                    ],
                                  ),

                                const SizedBox(height: 26),

                                // ───────── Encabezado de la vacante ─────────
                                Text(
                                  'Becario de TI',
                                  style: TextStyle(
                                    fontSize: isMobile ? 26 : 34,
                                    fontWeight: FontWeight.w900,
                                    color: const Color(0xFF22313F),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  '\$7500 Mensuales',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Banorte IXE S.A de C.V',
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 16),
                                const _AddressBlock(
                                  lines: [
                                    'Av. Miguel Othón de Mendizábal Ote. 343-Locales',
                                    '2-5, Industrial Vallejo, Gustavo A. Madero, 07700',
                                    'Ciudad de México, CDMX',
                                  ],
                                ),
                                const SizedBox(height: 14),
                                SizedBox(
                                  width: isMobile ? double.infinity : 200,
                                  height: 44,
                                  child: SimpleButton(
                                    title: 'Editar Vacante',
                                    onTap: () => context.go('/edit_vacancy'),
                                  ),
                                ),

                                const SizedBox(height: 24),

                                // ───────── Postulados / Cumple el Perfil ─────────
                                if (isMobile)
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _CandidatesRow(
                                        title: 'Postulados',
                                        people: const [
                                          _Person('assets/images/candidate_fernando.jpg', 'Fernando Torres Juarez'),
                                          _Person('assets/images/candidate_edgar.jpg', 'Edgar Gomez Martinez'),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      _CandidatesRow(
                                        title: 'Cumple el Perfil',
                                        people: const [
                                          _Person('assets/images/candidate_fernando.jpg', 'Fernando Torres Juarez'),
                                        ],
                                      ),
                                    ],
                                  )
                                else
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: _CandidatesRow(
                                          title: 'Postulados',
                                          people: const [
                                            _Person('assets/images/candidate_fernando.jpg', 'Fernando Torres Juarez'),
                                            _Person('assets/images/candidate_edgar.jpg', 'Edgar Gomez Martinez'),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 18),
                                      Expanded(
                                        child: _CandidatesRow(
                                          title: 'Cumple el Perfil',
                                          people: const [
                                            _Person('assets/images/candidate_fernando.jpg', 'Fernando Torres Juarez'),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),

                                const SizedBox(height: 12),
                                const Divider(thickness: 1),
                                const SizedBox(height: 8),

                                // ───────── REQUISITOS ─────────
                                const _SectionTitle('REQUISITOS'),
                                const SizedBox(height: 8),
                                const _BulletLines(
                                  lines: [
                                    'Informatica, Ing Sistemas, o Afín',
                                    'Universitarios sin Título',
                                  ],
                                ),

                                const SizedBox(height: 14),
                                const Divider(thickness: 1),
                                const SizedBox(height: 8),

                                // ───────── DESCRIPCION ─────────
                                const _SectionTitle('DESCRIPCION'),
                                const SizedBox(height: 8),
                                const Text(
                                  'El puesto de Becario de TI está dirigido a estudiantes que desean adquirir experiencia práctica en el área de Tecnologías de la Información dentro de una empresa de tecnología o en el departamento de TI de una organización. El becario trabajará bajo la supervisión de profesionales experimentados en el campo, participando en proyectos tecnológicos y colaborando en tareas de soporte y mantenimiento de sistemas, redes, y aplicaciones de la empresa.',
                                  textAlign: TextAlign.left,
                                  style: TextStyle(height: 1.5),
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

          // Footer animado
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

/* ───────────────────────── Widgets auxiliares de la vista ───────────────────────── */

class _AddressBlock extends StatelessWidget {
  const _AddressBlock({required this.lines});
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines.map((l) => Text(l, style: const TextStyle(fontSize: 14))).toList(),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final color = Colors.black.withOpacity(.25);
    return Row(
      children: [
        Expanded(child: Divider(color: color)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            text,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              letterSpacing: .6,
              color: Colors.black54,
            ),
          ),
        ),
        Expanded(child: Divider(color: color)),
      ],
    );
  }
}

class _BulletLines extends StatelessWidget {
  const _BulletLines({required this.lines});
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: lines
          .map(
            (t) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('•  ', style: TextStyle(fontSize: 18, height: 1.1)),
              Expanded(child: Text(t)),
            ],
          ),
        ),
      )
          .toList(),
    );
  }
}

class _CandidatesRow extends StatelessWidget {
  const _CandidatesRow({required this.title, required this.people});
  final String title;
  final List<_Person> people;

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 880;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Wrap(
          spacing: isMobile ? 18 : 28,
          runSpacing: 14,
          children: people
              .map(
                (p) => SizedBox(
              width: 160,
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundImage: AssetImage(p.image),
                    onBackgroundImageError: (_, __) {},
                    child: Image.asset(
                      p.image,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(Icons.person, size: 36),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    p.name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          )
              .toList(),
        ),
      ],
    );
  }
}

class _Person {
  final String image;
  final String name;
  const _Person(this.image, this.name);
}
