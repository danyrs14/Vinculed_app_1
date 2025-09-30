import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:vinculed_app_1/src/core/controllers/theme_controller.dart';
import 'package:vinculed_app_1/src/ui/widgets/elements/chat_panel.dart';
import 'package:vinculed_app_1/src/ui/widgets/elements/conversation_panel.dart';
import 'package:vinculed_app_1/src/ui/widgets/elements/header.dart';
import 'package:vinculed_app_1/src/ui/widgets/elements/footer.dart';
import 'package:vinculed_app_1/src/ui/widgets/elements/header2.dart';
import 'package:vinculed_app_1/src/ui/widgets/elements/header3.dart';

class MessagesPageRec extends StatefulWidget {
  const MessagesPageRec({super.key});

  @override
  State<MessagesPageRec> createState() => _MessagesPageRecState();
}

class _MessagesPageRecState extends State<MessagesPageRec> {
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
    final isNarrow = w < 1050;
    final isMobile = w < 700;

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
                        constraints: const BoxConstraints(maxWidth: 1200),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: minBodyHeight > 0 ? minBodyHeight : 0,
                            ),
                            child: isNarrow
                                ? _MobileStack(theme: theme)
                                : _DesktopRow(theme: theme),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Footer animado (aparece al llegar al final del contenido)
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

/* ───────────────────────── Desktop ───────────────────────── */

class _DesktopRow extends StatelessWidget {
  const _DesktopRow({required this.theme});
  final ThemeController theme;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 340,
          child: ConversationsPanel(theme: theme), // ⬅️ Reutilizable
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ChatPanel(theme: theme), // ⬅️ Reutilizable
        ),
      ],
    );
  }
}

/* ───────────────────────── Mobile ───────────────────────── */

class _MobileStack extends StatelessWidget {
  const _MobileStack({required this.theme});
  final ThemeController theme;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ConversationsPanel(theme: theme),
        const SizedBox(height: 16),
        ChatPanel(theme: theme),
      ],
    );
  }
}
