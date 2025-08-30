import 'package:flutter/material.dart';
import 'package:vinculed_app_1/src/core/controllers/theme_controller.dart';

/// Panel de chat reutilizable
class ChatPanel extends StatelessWidget {
  const ChatPanel({super.key, required this.theme});

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
                  text: "Hey! 📣 Don't forget our pizza night at your place this Saturday.",
                  time: '3:17 PM',
                ),
                _OutgoingMessage(
                  text: "Sounds delicious, Meera! 😋 Can’t wait for Saturday!",
                  time: '3:25 PM',
                  avatar: 'assets/images/user_m2.png',
                ),
                _IncomingMessage(
                  avatar: 'assets/images/user_f2.png',
                  text: "Absolutely! ✨ I'm all in for ice cream. I'll bring my favorite flavors.",
                  time: '3:37 PM',
                ),
                _OutgoingMessage(
                  text: "Awesome! 🍦 I love chocolate chip cookie dough.",
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

/* ───────────────────────── Internos del panel ───────────────────────── */

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
      bubble: _Bubble(text: text, alignRight: false),
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

BoxDecoration _panelDecoration(ThemeController theme) {
  return BoxDecoration(
    color: theme.background(),
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: Colors.black12),
  );
}
