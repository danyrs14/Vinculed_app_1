import 'package:flutter/material.dart';
import 'package:vinculed_app_1/src/core/controllers/theme_controller.dart';
import 'package:vinculed_app_1/src/ui/widgets/text_inputs/text_input.dart';

/// Panel izquierdo con la lista de conversaciones.
/// Se hizo reusable para poder montarlo en otras pantallas.
class ConversationsPanel extends StatelessWidget {
  const ConversationsPanel({super.key, required this.theme});

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

          // Lista (no scroll interno; usa el scroll del padre)
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

BoxDecoration _panelDecoration(ThemeController theme) {
  return BoxDecoration(
    color: theme.background(),
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: Colors.black12),
  );
}
