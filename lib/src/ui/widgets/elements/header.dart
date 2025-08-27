import 'package:flutter/material.dart';
import 'package:vinculed_app_1/src/core/controllers/theme_controller.dart';
import 'package:vinculed_app_1/src/ui/widgets/buttons/mini_buttons.dart';

class EscomHeader extends StatelessWidget implements PreferredSizeWidget {
  const EscomHeader({
    super.key,
    this.onMenuSelected,
    this.onLoginTap,
    this.onRegisterTap,
    this.onNotifTap,
  });

  final void Function(String label)? onMenuSelected;
  final VoidCallback? onLoginTap;
  final VoidCallback? onRegisterTap;
  final VoidCallback? onNotifTap;

  static const _menuItems = <String>[
    "Inicio",
    "Postulaciones",
    "Experiencias",
    "Mensajes",
    "Preferencias",
    "FAQ",
  ];

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;
    final isMobile = MediaQuery.of(context).size.width < 700;

    return AppBar(
      backgroundColor: theme.background(),
      elevation: 0,
      titleSpacing: 20,
      title: Row(
        children: [
          Image.asset('assets/images/escom.png', height: 40),
          const SizedBox(width: 10),
        ],
      ),
      actions: isMobile
          ? [
        PopupMenuButton<String>(
          icon: const Icon(Icons.menu),
          onSelected: (value) => onMenuSelected?.call(value),
          itemBuilder: (context) => _menuItems
              .map((e) => PopupMenuItem<String>(
            value: e,
            child: Text(e),
          ))
              .toList(),
        ),
      ]
          : [
        ..._menuItems.map(
              (label) => _navButton(label, () => onMenuSelected?.call(label)),
        ),
        TextButton(
          onPressed: onLoginTap,
          child: Text(
            "Iniciar Sesión",
            style: TextStyle(
              color: theme.secundario(),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: MiniButton(
            onTap: onRegisterTap,
            title: "Registrarse",
          ),
        ),
        IconButton(
          onPressed: onNotifTap,
          icon: const Icon(Icons.notifications),
          tooltip: 'Notificaciones',
        ),
      ],
    );
  }

  Widget _navButton(String text, VoidCallback? onTap) {
    return TextButton(
      onPressed: onTap,
      child: Text(
        text,
        style: const TextStyle(color: Colors.black87),
      ),
    );
  }
}
