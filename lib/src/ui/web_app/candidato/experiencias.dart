import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:vinculed_app_1/src/core/controllers/theme_controller.dart';
import 'package:vinculed_app_1/src/ui/widgets/elements/header.dart';
import 'package:vinculed_app_1/src/ui/widgets/elements/footer.dart';
import 'package:vinculed_app_1/src/ui/widgets/buttons/simple_buttons.dart';

class ExperiencesPage extends StatefulWidget {
  const ExperiencesPage({super.key});

  @override
  State<ExperiencesPage> createState() => _ExperiencesPageState();
}

class _ExperiencesPageState extends State<ExperiencesPage> {
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
    final isMobile = w < 720;

    return Scaffold(
      backgroundColor: theme.background(),
      appBar: EscomHeader(
        onLoginTap: () => context.go('/login'),
        onRegisterTap: () => context.go('/signin'),
        onNotifTap: () {},
        onMenuSelected: (label) {
          if (label == "Inicio") context.go('/dashboard');
        },
      ),
      body: Stack(
        children: [
          // Contenido scrolleable con padding para el footer
          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final minBodyHeight =
                    constraints.maxHeight - _footerReservedSpace - _extraBottomPadding;

                return SingleChildScrollView(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.only(
                    bottom: _footerReservedSpace + _extraBottomPadding,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1100),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: minBodyHeight > 0 ? minBodyHeight : 0,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Título
                              Padding(
                                padding: const EdgeInsets.only(top: 8, bottom: 8),
                                child: Text(
                                  'Experiencias',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: isMobile ? 28 : 34,
                                    fontWeight: FontWeight.w900,
                                    color: const Color(0xFF22313F),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),

                              // Contenido principal: post + botón "Crear"
                              LayoutBuilder(
                                builder: (context, c) {
                                  final stack = c.maxWidth < 900;
                                  final post = const _ExperiencePost();
                                  final createBtn = SizedBox(
                                    width: stack ? double.infinity : 220,
                                    child: SimpleButton(
                                      title: 'Crear',
                                      onTap: () {
                                        // navega a tu pantalla de creación si ya tienes ruta
                                        // context.go('/crear_experiencia');
                                      },
                                    ),
                                  );

                                  if (stack) {
                                    return Column(
                                      children: [
                                        post,
                                        const SizedBox(height: 18),
                                        Align(
                                          alignment: Alignment.centerRight,
                                          child: createBtn,
                                        ),
                                      ],
                                    );
                                  }
                                  return Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // centra el post en el contenedor
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.center,
                                          children: [
                                            Align(
                                              alignment: Alignment.center,
                                              child: ConstrainedBox(
                                                constraints: const BoxConstraints(maxWidth: 520),
                                                child: post,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 28),
                                      // botón a la derecha
                                      SizedBox(width: 260, child: createBtn),
                                    ],
                                  );
                                },
                              ),

                              const SizedBox(height: 40),
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

/* ───────────────────────── Post de experiencia (demo) ───────────────────────── */

class _ExperiencePost extends StatelessWidget {
  const _ExperiencePost();

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;

    return Container(
      decoration: BoxDecoration(
        color: theme.background(),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Header del post
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CircleAvatar(
                radius: 20,
                backgroundImage: AssetImage('assets/images/amlo.jpg'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Andres Manuel Lopez',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Estudiante · 20 h',
                      style: TextStyle(color: Colors.black54, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.more_horiz, color: Colors.black54),
            ],
          ),
          const SizedBox(height: 12),

          // Texto del post
          const Text(
            'Mi experiencia como becaria en el departamento de desarrollo '
                'de software fue increíblemente enriquecedora. Durante mi tiempo '
                'en la empresa, participé activamente en varios proyectos relacionados '
                'con la creación y mejora de aplicaciones móviles.',
            textAlign: TextAlign.left,
          ),

          const SizedBox(height: 12),
          const Divider(height: 1),

          // Acciones del post
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: const [
                _ActionIcon(icon: Icons.favorite_border, label: 'Me gusta'),
                SizedBox(width: 16),
                _ActionIcon(icon: Icons.mode_comment_outlined, label: 'Comentar'),
                Spacer(),
                Text('1 Comentario', style: TextStyle(color: Colors.black54, fontSize: 12)),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Comentario destacado (como en el mock)
          _CommentBubble(
            avatar: 'assets/images/user_m1.png',
            name: 'Alejandro Yañez Sanchez',
            text: 'Muy buena reseña, me encanta!',
            footer: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                _ActionIcon(icon: Icons.favorite_border, label: 'Me gusta', dense: true),
                SizedBox(width: 12),
                _ActionIcon(icon: Icons.reply_outlined, label: 'Responder', dense: true),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/* ───────────────────────── Widgets pequeños ───────────────────────── */

class _ActionIcon extends StatelessWidget {
  const _ActionIcon({
    required this.icon,
    required this.label,
    this.dense = false,
  });

  final IconData icon;
  final String label;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontSize: dense ? 12 : 13.5,
      color: Colors.black87,
      fontWeight: dense ? FontWeight.w500 : FontWeight.w600,
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: dense ? 16 : 20, color: Colors.black87),
        const SizedBox(width: 6),
        Text(label, style: style),
      ],
    );
  }
}

class _CommentBubble extends StatelessWidget {
  const _CommentBubble({
    required this.avatar,
    required this.name,
    required this.text,
    this.footer,
  });

  final String avatar;
  final String name;
  final String text;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // avatar alineado a la izquierda
        Padding(
          padding: const EdgeInsets.only(left: 8, right: 8),
          child: CircleAvatar(
            radius: 18,
            backgroundImage: AssetImage(avatar),
          ),
        ),
        // burbuja
        Flexible(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black12.withOpacity(.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.black12),
            ),
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(text),
                if (footer != null) ...[
                  const SizedBox(height: 6),
                  DefaultTextStyle(
                    style: const TextStyle(fontSize: 12, color: Colors.black87),
                    child: footer!,
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
