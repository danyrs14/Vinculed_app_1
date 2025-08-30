import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:vinculed_app_1/src/core/controllers/theme_controller.dart';
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

  final _composerCtrl = TextEditingController();

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
    _scrollCtrl..removeListener(_handleScroll)..dispose();
    _composerCtrl.dispose();
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
        Expanded(child: _ChatPanel(theme: theme)),
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
        _ChatPanel(theme: theme),
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

          // 👉 Título aparte
          const _PanelTitle('Messages'),

          // Buscador
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: TextInput(title: 'Buscar'),
          ),
          const SizedBox(height: 8),

          // Lista shrinkWrap (sin Expanded)
          ListView(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: const [
              _ConversationTile(
                avatar: 'assets/images/user_f1.png',
                name: 'Andrea Martinez',
                preview:
                "Hey there! 🤓 Did you catch the latest episode of it...",
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

/// Título reutilizable para secciones dentro de paneles (izquierda)
class _PanelTitle extends StatelessWidget {
  const _PanelTitle(this.text, {this.padding = const EdgeInsets.fromLTRB(16, 14, 16, 8)});
  final String text;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
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

/* ───────────────────────── Panel del Chat ───────────────────────── */

class _ChatPanel extends StatelessWidget {
  const _ChatPanel({required this.theme});
  final ThemeController theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _panelDecoration(theme),
      child: Column(
        children: [
          // Encabezado del chat
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            decoration: BoxDecoration(
              color: theme.secundario(),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: const [
                CircleAvatar(
                  backgroundImage: AssetImage('assets/images/user_f2.png'),
                ),
                SizedBox(width: 12),
                Text(
                  'Cristina Muñoz',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),
          const _TodayChip(),
          const SizedBox(height: 12),

          // Mensajes (demo)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: const [
                _IncomingMessage(
                  avatar: 'assets/images/user_f2.png',
                  text:
                  "Hey! 📣 Don't forget our pizza night at your place this Saturday.",
                  time: '3:17 PM',
                ),
                _OutgoingMessage(
                  text:
                  "Sounds delicious, Meera! 😋 Can’t wait for Saturday!",
                  time: '3:25 PM',
                  avatar: 'assets/images/user_m2.png',
                ),
                _IncomingMessage(
                  avatar: 'assets/images/user_f2.png',
                  text:
                  "Absolutely! ✨ I'm all in for ice cream. I'll bring my favorite flavors.",
                  time: '3:37 PM',
                ),
                _OutgoingMessage(
                  text:
                  "Awesome! 🍦 I love chocolate chip cookie dough.",
                  time: '3:28 PM',
                  avatar: 'assets/images/user_m2.png',
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Barra de redacción
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
            child: _ComposerBar(),
          ),
        ],
      ),
    );
  }
}

class _TodayChip extends StatelessWidget {
  const _TodayChip();

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      decoration: BoxDecoration(
        color: theme.secundario(),
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Text(
        'TODAY',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _IncomingMessage extends StatelessWidget {
  const _IncomingMessage({
    required this.avatar,
    required this.text,
    required this.time,
  });

  final String avatar;
  final String text;
  final String time;

  @override
  Widget build(BuildContext context) {
    return _MessageRow(
      leading: CircleAvatar(backgroundImage: AssetImage(avatar)),
      bubble: const _Bubble(text: "Hey! 📣 Don't forget our pizza night at your place this Saturday.", alignRight: false),
      time: time,
    );
  }
}

class _OutgoingMessage extends StatelessWidget {
  const _OutgoingMessage({
    required this.text,
    required this.time,
    required this.avatar,
  });

  final String text;
  final String time;
  final String avatar;

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;
    return _MessageRow(
      leading: const SizedBox(width: 36),
      bubble: _Bubble(
        text: text,
        alignRight: true,
        color: theme.secundario(),
        textColor: Colors.white,
      ),
      trailing: CircleAvatar(backgroundImage: AssetImage(avatar)),
      time: time,
      alignRight: true,
    );
  }
}

class _MessageRow extends StatelessWidget {
  const _MessageRow({
    required this.leading,
    required this.bubble,
    required this.time,
    this.trailing,
    this.alignRight = false,
  });

  final Widget leading;
  final Widget bubble;
  final Widget? trailing;
  final String time;
  final bool alignRight;

  @override
  Widget build(BuildContext context) {
    final rowChildren = <Widget>[
      leading,
      const SizedBox(width: 10),
      Expanded(child: bubble),
      const SizedBox(width: 10),
      if (trailing != null) trailing!,
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment:
        alignRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment:
            alignRight ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: alignRight ? rowChildren.reversed.toList() : rowChildren,
          ),
          const SizedBox(height: 4),
          Text(time, style: const TextStyle(fontSize: 11, color: Colors.black54)),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({
    required this.text,
    required this.alignRight,
    this.color,
    this.textColor,
  });

  final String text;
  final bool alignRight;
  final Color? color;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    final bg = color ?? Colors.white;
    final tx = textColor ?? Colors.black87;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.black12),
      ),
      child: Text(text, style: TextStyle(color: tx)),
    );
  }
}

class _ComposerBar extends StatelessWidget {
  _ComposerBar({super.key});
  final _ctrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;

    return Row(
      children: [
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.attach_file_outlined),
        ),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.black26),
              borderRadius: BorderRadius.circular(28),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _ctrl,
              decoration: const InputDecoration(
                hintText: 'Escribe un mensaje',
                border: InputBorder.none,
              ),
              minLines: 1,
              maxLines: 4,
            ),
          ),
        ),
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.sentiment_satisfied_outlined),
        ),
        const SizedBox(width: 6),
        FloatingActionButton(
          onPressed: () {},
          mini: true,
          backgroundColor: theme.secundario(),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: const CircleBorder(),
          child: const Icon(Icons.send),
        ),
      ],
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
