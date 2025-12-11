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

            ]
          : [
              ..._menuItems.map(
                    (label) => _navButton(label, () => onMenuSelected?.call(label)),
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

  /// Panel tipo "drawer" del lado derecho, como en el diseño.
  void _showNotificationsPanel(BuildContext context) {
    final theme = ThemeController.instance;
    final mq = MediaQuery.of(context);
    final panelWidth = mq.size.width <= 480 ? mq.size.width : 420.0;
    final panelHeight = mq.size.height * 0.8;

    showGeneralDialog(
      context: context,
      barrierColor: Colors.black54,
      barrierDismissible: true,
      barrierLabel: 'Notificaciones',
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (ctx, _, __) {
        return SafeArea(
          child: Align(
            alignment: Alignment.topRight,
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: panelWidth,
                height: panelHeight,
                margin: const EdgeInsets.only(top: 8, right: 8, bottom: 8),
                decoration: BoxDecoration(
                  color: theme.background(),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(
                      blurRadius: 20,
                      color: Color(0x33000000),
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: _NotificationsList(
                  onClose: () => Navigator.of(ctx).maybePop(),
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (_, anim, __, child) {
        final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.15, 0), // entra desde la derecha
            end: Offset.zero,
          ).animate(curved),
          child: FadeTransition(opacity: curved, child: child),
        );
      },
    );
  }
}

/* ───────────────────────── Panel de Notificaciones ───────────────────────── */

class _NotificationsList extends StatelessWidget {
  const _NotificationsList({required this.onClose});
  final VoidCallback onClose;

  // Datos de ejemplo; sustituye por tus datos reales
  List<_Notif> get _items => const [
    _Notif(
      name: 'Andres Flores',
      message: 'Ha checado tu perfil',
      minutesAgo: 0,
      unread: true,
    ),
    _Notif(
      name: 'Oscar Manríquez',
      message: 'Mostró interés',
      minutesAgo: 6,
      unread: true,
    ),
    _Notif(
      name: 'Eduardo Perez',
      message: 'Ha comentado tu publicación',
      minutesAgo: 15,
    ),
    _Notif(
      name: 'Ximena Castillo',
      message: 'Publicó una experiencia',
      minutesAgo: 16,
    ),
    _Notif(
      name: 'Pablo Lopez',
      message: 'Se ha unido',
      minutesAgo: 18,
      unread: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header del panel
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 8, 6),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Notificaciones',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Cerrar',
                onPressed: onClose,
                icon: const Icon(Icons.close),
              ),
            ],
          ),
        ),
        const Divider(height: 1),

        // Lista
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 6),
            itemBuilder: (context, i) {
              final n = _items[i];
              return ListTile(
                leading: CircleAvatar(
                  radius: 20,
                  backgroundColor: const Color(0xFFE6F0F5),
                  child: Text(
                    _initials(n.name),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                title: Text(
                  n.name,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(n.message),
                    const SizedBox(height: 2),
                    Text(
                      '${n.minutesAgo} min',
                      style: const TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (n.unread)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: theme.secundario(),
                          shape: BoxShape.circle,
                        ),
                      ),
                    const SizedBox(width: 10),
                    const Icon(Icons.chevron_right),
                  ],
                ),
                onTap: () {
                  // Aquí podrías navegar a detalle de la notificación
                  // Navigator.of(context).pop(); // cierra el panel si quieres
                },
              );
            },
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemCount: _items.length,
          ),
        ),
      ],
    );
  }

  static String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.characters.take(2).toString().toUpperCase();
    return (parts.first.characters.first +
        parts.last.characters.first)
        .toString()
        .toUpperCase();
  }
}

class _Notif {
  final String name;
  final String message;
  final int minutesAgo;
  final bool unread;

  const _Notif({
    required this.name,
    required this.message,
    required this.minutesAgo,
    this.unread = false,
  });
}
