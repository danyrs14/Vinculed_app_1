import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:vinculed_app_1/src/core/controllers/theme_controller.dart';
import 'package:vinculed_app_1/src/ui/widgets/elements/chat_panel.dart';
import 'package:vinculed_app_1/src/ui/widgets/elements/header.dart';
import 'package:vinculed_app_1/src/ui/widgets/elements/footer.dart';
import 'package:vinculed_app_1/src/ui/widgets/text_inputs/text_input.dart'; 

class MessagesPage extends StatefulWidget {
  const MessagesPage({super.key});

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
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
          child: _ConversationsPanel(theme: theme),
        ),
        const SizedBox(width: 16),
        Expanded(
          // ⬇️ Ahora usamos el ChatPanel reutilizable
          child: ChatPanel(theme: theme),
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
        _ConversationsPanel(theme: theme),
        const SizedBox(height: 16),
        ChatPanel(theme: theme), // ⬅️ también en móvil
      ],
    );
  }
}

/* ───────────────────────── Panel de Conversaciones ───────────────────────── */

class _ConversationsPanel extends StatelessWidget {
  const _ConversationsPanel({required this.theme});
  final ThemeController theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _panelDecoration(theme),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Encabezado usuario
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(
              children: const [
                CircleAvatar(
                  radius: 22,
                  backgroundImage: AssetImage('assets/images/amlo.jpg'),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Usuario Registrado',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Título + búsqueda
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Text(
              'Messages',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: TextInput(title: 'Buscar'),
          ),
          const SizedBox(height: 8),

          // Lista shrinkWrap (no scroll interno)
          ListView(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: const [
              _ConversationTile(
                avatar: 'assets/images/user_f1.png',
                name: 'Andrea Martinez',
                preview: "Hey there! 🤓 Did you catch the latest episode of it...",
                time: '5s',
                unread: true,
              ),
              _ConversationTile(
                avatar: 'assets/images/user_m1.png',
                name: 'Ian Gonzalez',
                preview: "When will the work be ready???",
                time: '5m',
              ),
              _ConversationTile(
                avatar: 'assets/images/user_f2.png',
                name: 'Cristina Muñoz',
                preview:
                "Awesome! 🍦 I love chocolate chip cookie dough. Looking forward...",
                time: '1h',
                active: true,
              ),
              _ConversationTile(
                avatar: 'assets/images/user_f3.png',
                name: 'Andrea Velazquez',
                preview:
                "Just wanted to share the awesome pics from our hiking...",
                time: '2h',
              ),
              _ConversationTile(
                avatar: 'assets/images/user_m2.png',
                name: 'Maximiliano Vega',
                preview:
                "That is a good idea. I will try to communicate this with the team.",
                time: '1d',
              ),
            ],
          ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({
    required this.avatar,
    required this.name,
    required this.preview,
    required this.time,
    this.unread = false,
    this.active = false,
  });

  final String avatar;
  final String name;
  final String preview;
  final String time;
  final bool unread;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: active ? theme.background() : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: active ? theme.secundario().withOpacity(.5) : Colors.grey.shade300,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        leading: CircleAvatar(backgroundImage: AssetImage(avatar)),
        title: Row(
          children: [
            Expanded(
              child: Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
            Text(time, style: const TextStyle(fontSize: 12, color: Colors.black54)),
          ],
        ),
        subtitle: Row(
          children: [
            Expanded(
              child: Text(
                preview,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (unread)
              Container(
                width: 18,
                height: 18,
                alignment: Alignment.center,
                margin: const EdgeInsets.only(left: 6),
                decoration: BoxDecoration(
                  color: theme.secundario(),
                  shape: BoxShape.circle,
                ),
                child: const Text(
                  '4',
                  style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/* ───────────────────────── Util ───────────────────────── */

BoxDecoration _panelDecoration(ThemeController theme) {
  return BoxDecoration(
    color: theme.background(),
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: Colors.black12),
  );
}
