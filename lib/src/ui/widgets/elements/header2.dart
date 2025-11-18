import 'package:flutter/material.dart';
import 'package:vinculed_app_1/src/core/controllers/theme_controller.dart';
import 'package:vinculed_app_1/src/ui/widgets/buttons/mini_buttons.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:vinculed_app_1/src/core/providers/user_provider.dart';

class EscomHeader2 extends StatelessWidget implements PreferredSizeWidget {
  const EscomHeader2({
    super.key,
    this.onMenuSelected,
    this.onLoginTap,
    this.onNotifTap, // Se llamará DESPUÉS de abrir la bandeja
  });

  final void Function(String label)? onMenuSelected;
  final VoidCallback? onLoginTap;
  /// Se llamará después de abrir la bandeja, para métricas o side-effects.
  final VoidCallback? onNotifTap;

  static const _menuItems = <String>[
    "Inicio",
    "Postulaciones",
    "Experiencias",
    "Mensajes",
    "Explorar Puestos en TI",
    "FAQ",
  ];

  Future<void> _cerrarSesion(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      // Limpia datos cacheados del usuario (rol, id, token, etc.)
      context.read<UserDataProvider>().clearData();
    } catch (e) {
      print("Error al cerrar sesión: $e");
    }
  } 

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
        // Campana en móvil
        _notifIcon(context),
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
            "Mi Perfil",
            style: TextStyle(
              color: theme.secundario(),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: MiniButton(
            onTap: () => _cerrarSesion(context),
            title: "Cerrar Sesion",
          ),
        ),
        _notifIcon(context),
        const SizedBox(width: 8),
      ],
    );
  }

  /// Botón de notificaciones con "badge" de ejemplo.
  Widget _notifIcon(BuildContext context) {
    // Cambia este número para simular cuántas no leídas tienes.
    const int unreadCount = 3;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          tooltip: 'Notificaciones',
          onPressed: () {
            _showNotificationsPanel(context); // SIEMPRE abre
            onNotifTap?.call(); // luego, si quieres hacer algo extra
          },
          icon: const Icon(Icons.notifications),
        ),
        if (unreadCount > 0)
          Positioned(
            right: 6,
            top: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                unreadCount.toString(),
                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
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

  /// Panel tipo "drawer" del lado derecho.
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
      pageBuilder: (dialogCtx, _, __) {
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
                  onClose: () => Navigator.of(dialogCtx).maybePop(),
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

  // Notificaciones de muestra (puedes borrarlas después):
  List<_Notif> get _items => const [
    _Notif(
      name: 'Andrés Flores',
      message: 'Revisó tu perfil',
      minutesAgo: 2,
      unread: true,
    ),
    _Notif(
      name: 'Oscar Manríquez',
      message: 'Mostró interés en tu candidatura',
      minutesAgo: 6,
      unread: true,
    ),
    _Notif(
      name: 'Eduardo Pérez',
      message: 'Comentó tu publicación “Tips de entrevista”',
      minutesAgo: 15,
    ),
    _Notif(
      name: 'Ximena Castillo',
      message: 'Publicó una nueva experiencia',
      minutesAgo: 16,
    ),
    _Notif(
      name: 'Pablo López',
      message: 'Se ha unido a tu red',
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
                  // Aquí podrías navegar al detalle o marcar como leída
                  // Navigator.of(context).pop(); // si quieres cerrar
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

  /// Iniciales simples sin dependencia de `characters`.
  static String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    final first = parts.first[0];
    final last = (parts.length > 1 && parts.last.isNotEmpty) ? parts.last[0] : '';
    return (first + last).toUpperCase();
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
