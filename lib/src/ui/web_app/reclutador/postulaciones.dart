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

  // ───── Datos demo: listado de vacantes y candidatos ─────
  final List<_Vacancy> _vacancies = [
    _Vacancy(
      title: 'Becario de TI',
      salaryText: '\$7,500 Mensuales',
      company: 'Banorte IXE S.A de C.V',
      addressLines: const [
        'Av. Miguel Othón de Mendizábal Ote. 343-Locales',
        '2-5, Industrial Vallejo, Gustavo A. Madero, 07700',
        'Ciudad de México, CDMX',
      ],
      requisitos: const [
        'Informática, Ing. en Sistemas o afín',
        'Universitario sin título',
      ],
      description:
      'El puesto de Becario de TI está dirigido a estudiantes que desean adquirir experiencia práctica en Tecnologías de la Información. Colaborará en soporte y mantenimiento de sistemas, redes y aplicaciones, bajo la supervisión de profesionales.',
      candidates: const [
        _Person('assets/images/candidate_fernando.jpg', 'Fernando Torres Juarez'),
        _Person('assets/images/candidate_edgar.jpg', 'Edgar Gomez Martinez'),
      ],
    ),
    _Vacancy(
      title: 'Jr. QA Tester',
      salaryText: '\$12,000 Mensuales',
      company: 'TechLabs México',
      addressLines: const [
        'Av. Reforma 123',
        'Centro, Cuauhtémoc, 06000',
        'Ciudad de México, CDMX',
      ],
      requisitos: const [
        'Ing. Sistemas o afín',
        'Conocimientos básicos en pruebas manuales',
      ],
      description:
      'Apoyo en ejecución de casos de prueba, reporte de bugs y verificación de criterios de aceptación en aplicaciones web y móviles. Trabajo con squads ágiles.',
      candidates: const [
        _Person('assets/images/candidate_fernando.jpg', 'Fernando Torres Juarez'),
      ],
    ),
  ];

  int? _selectedIndex; // null => vista de listado; idx => detalle

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
        onLoginTap: () => context.go('/reclutador/perfil_rec'),
        onNotifTap: () {},
        onMenuSelected: (label) {
          switch (label) {
            case "Inicio":
              context.go('/inicio');
              break;
            case "Crear Vacante":
              context.go('/reclutador/new_vacancy');
              break;
            case "Mis Vacantes":
              context.go('/reclutador/my_vacancy');
              break;
            case "Postulaciones":
              context.go('/reclutador/postulaciones');
              break;
            case "FAQ":
              context.go('/reclutador/faq_rec');
              break;
            case "Mensajes":
              context.go('/reclutador/msg_rec');
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
                              minHeight: minBodyHeight > 0 ? minBodyHeight : 0,
                            ),
                            child: (_selectedIndex == null)
                                ? _VacancyListView(
                              vacancies: _vacancies,
                              onOpen: (i) {
                                setState(() => _selectedIndex = i);
                                _scrollCtrl.animateTo(
                                  0,
                                  duration: const Duration(milliseconds: 280),
                                  curve: Curves.easeOut,
                                );
                              },
                            )
                                : _VacancyDetailView(
                              vacancy: _vacancies[_selectedIndex!],
                              isMobile: isMobile,
                              onEdit: () => context.go('/edit_vacancy'),
                              onBackToList: () => setState(() => _selectedIndex = null),
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

/* ───────────────────────── Vista: Listado de Vacantes ───────────────────────── */

class _VacancyListView extends StatelessWidget {
  const _VacancyListView({
    required this.vacancies,
    required this.onOpen,
  });

  final List<_Vacancy> vacancies;
  final void Function(int index) onOpen;

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 880;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Encabezado
        Row(
          children: const [
            _HeaderAvatar(),
            SizedBox(width: 12),
            Text(
              'Vacantes',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: Color(0xFF22313F),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Grid o lista de tarjetas
        LayoutBuilder(
          builder: (_, c) {
            final crossAxisCount = isMobile ? 1 : 2;
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: vacancies.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: isMobile ? 1.4 : 1.8,
              ),
              itemBuilder: (_, i) {
                final v = vacancies[i];
                return _CardBox(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        v.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF22313F),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(v.salaryText, style: const TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Text(v.company, style: const TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 10),
                      Text(
                        v.description,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(height: 1.35),
                      ),
                      const Spacer(),
                      Align(
                        alignment: Alignment.centerRight,
                        child: SizedBox(
                          height: 40,
                          child: SimpleButton(
                            title: 'Ver detalle',
                            onTap: () => onOpen(i),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}

/* ───────────────────────── Vista: Detalle de Vacante ───────────────────────── */

class _VacancyDetailView extends StatelessWidget {
  const _VacancyDetailView({
    required this.vacancy,
    required this.isMobile,
    required this.onEdit,
    required this.onBackToList,
  });

  final _Vacancy vacancy;
  final bool isMobile;
  final VoidCallback onEdit;
  final VoidCallback onBackToList;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ───────── Barra superior de acciones ─────────
        if (isMobile)
          Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: SimpleButton(
                      title: 'Regresar',
                      onTap: onBackToList,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SimpleButton(title: 'Cerrar Vacante', onTap: () {}),
            ],
          )
        else
          Row(
            children: [
              SizedBox(width: 220, child: SimpleButton(title: 'Regresar', onTap: onBackToList)),
              const SizedBox(width: 12),
              SizedBox(width: 220, child: SimpleButton(title: 'Cerrar Vacante', onTap: () {})),
            ],
          ),

        const SizedBox(height: 26),

        // ───────── Encabezado de la vacante ─────────
        Text(
          vacancy.title,
          style: TextStyle(
            fontSize: isMobile ? 26 : 34,
            fontWeight: FontWeight.w900,
            color: const Color(0xFF22313F),
          ),
        ),
        const SizedBox(height: 6),
        Text(vacancy.salaryText, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text(vacancy.company, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 16),
        _AddressBlock(lines: vacancy.addressLines),
        const SizedBox(height: 14),
        SizedBox(
          width: isMobile ? double.infinity : 200,
          height: 44,
          child: SimpleButton(title: 'Editar Vacante', onTap: onEdit),
        ),

        const SizedBox(height: 24),

        // ───────── REQUISITOS ─────────
        const _SectionTitle('REQUISITOS'),
        const SizedBox(height: 8),
        _BulletLines(lines: vacancy.requisitos),

        const SizedBox(height: 14),
        const Divider(thickness: 1),
        const SizedBox(height: 8),

        // ───────── DESCRIPCION ─────────
        const _SectionTitle('DESCRIPCION'),
        const SizedBox(height: 8),
        Text(
          vacancy.description,
          textAlign: TextAlign.left,
          style: const TextStyle(height: 1.5),
        ),

        const SizedBox(height: 18),
        const Divider(thickness: 1),
        const SizedBox(height: 8),

        // ───────── POSTULADOS (debajo de la descripción, SIN "Cumple el perfil") ─────────
        const _SectionTitle('POSTULADOS'),
        const SizedBox(height: 10),
        _CandidatesGrid(
          people: vacancy.candidates,
          isMobile: isMobile,
        ),
      ],
    );
  }
}

/* ───────────────────────── Widgets auxiliares ───────────────────────── */

class _Vacancy {
  final String title;
  final String salaryText;
  final String company;
  final List<String> addressLines;
  final List<String> requisitos;
  final String description;
  final List<_Person> candidates;

  const _Vacancy({
    required this.title,
    required this.salaryText,
    required this.company,
    required this.addressLines,
    required this.requisitos,
    required this.description,
    required this.candidates,
  });
}

class _HeaderAvatar extends StatelessWidget {
  const _HeaderAvatar();

  @override
  Widget build(BuildContext context) {
    return const CircleAvatar(
      radius: 18,
      backgroundImage: AssetImage('assets/images/escom.png'),
      backgroundColor: Colors.transparent,
    );
  }
}

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

class _CandidatesGrid extends StatelessWidget {
  const _CandidatesGrid({required this.people, required this.isMobile});
  final List<_Person> people;
  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    final columns = isMobile ? 1 : 3;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: people.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: isMobile ? 3.0 : 3.6,
      ),
      itemBuilder: (_, i) {
        final p = people[i];
        return _CardBox(
          child: Row(
            children: [
              _SafeAvatar(assetPath: p.image, size: 56),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  p.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                height: 40,
                child: SimpleButton(
                  title: 'Ver perfil',
                  onTap: () {
                    // Ajusta esta ruta a la que uses para perfil de candidato
                    context.go('/reclutador/perfil_candidato');
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CardBox extends StatelessWidget {
  const _CardBox({super.key, this.child});
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x11000000)),
        boxShadow: const [
          BoxShadow(
            blurRadius: 10,
            spreadRadius: 0,
            offset: Offset(0, 2),
            color: Color(0x0F000000),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SafeAvatar extends StatelessWidget {
  const _SafeAvatar({required this.assetPath, this.size = 36});
  final String assetPath;
  final double size;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: Colors.transparent,
      child: ClipOval(
        child: Image.asset(
          assetPath,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) {
            return Icon(Icons.person, size: size * .8, color: const Color(0xFF22313F));
          },
        ),
      ),
    );
  }
}

class _Person {
  final String image;
  final String name;
  const _Person(this.image, this.name);
}
