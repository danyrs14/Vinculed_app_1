import 'package:flutter/material.dart';
import 'package:vinculed_app_1/src/core/controllers/theme_controller.dart';
import 'package:vinculed_app_1/src/ui/widgets/buttons/mini_buttons.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:vinculed_app_1/src/core/providers/user_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vinculed_app_1/src/core/services/notification_log_service.dart';

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
          Image.asset('assets/images/graduate.png', height: 40),
          const SizedBox(width: 10),
        ],
      ),
      actions: isMobile
          ? [
        // Campana en móvil
        _notifIcon(context),
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
            dense: true, // compacto en móvil
          ),
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.menu),
          onSelected: (value) => onMenuSelected?.call(value),
          itemBuilder: (context) => _menuItems
              .map(
                (e) => PopupMenuItem<String>(
              value: e,
              child: Text(e),
            ),
          )
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
            dense: false, // tamaño normal en desktop
          ),
        ),
        _notifIcon(context),
        const SizedBox(width: 8),
      ],
    );
  }

  /// Botón de notificaciones con badge dinámico usando Firestore
  Widget _notifIcon(BuildContext context) {
    final theme = ThemeController.instance;

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: NotificationLogService.instance.streamForCurrentUser(),
      builder: (context, snapshot) {
        int unreadCount = 0;

        if (snapshot.hasData) {
          final docs = snapshot.data!.docs;
          unreadCount = docs
              .where((d) => (d.data()['read'] ?? false) == false)
              .length;
        }

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
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        );
      },
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
        final curved =
        CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
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

class _NotificationsList extends StatelessWidget {
  const _NotificationsList({required this.onClose});
  final VoidCallback onClose;

  String _formatDate(Timestamp? ts) {
    if (ts == null) return '';
    final dt = ts.toDate();
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final y = dt.year.toString();
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '$d/$m/$y  $hh:$mm';
  }

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

        // Lista (ahora con datos reales de Firestore)
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: NotificationLogService.instance.streamForCurrentUser(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'Ocurrió un error al cargar tus notificaciones',
                      style: TextStyle(fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              final docs = snapshot.data?.docs ?? [];

              if (docs.isEmpty) {
                return const Center(
                  child: Text(
                    'Aún no tienes notificaciones',
                    style: TextStyle(fontSize: 14),
                  ),
                );
              }

              // (Opcional) ordenar por fecha aquí si fuera necesario
              docs.sort((a, b) {
                final ta = a.data()['createdAt'];
                final tb = b.data()['createdAt'];
                if (ta is Timestamp && tb is Timestamp) {
                  return tb.compareTo(ta); // desc
                }
                return 0;
              });

              return ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 6),
                itemBuilder: (context, i) {
                  final data = docs[i].data();

                  final title =
                  (data['title'] ?? 'Notificación').toString();
                  final body = (data['body'] ?? '').toString();
                  final createdAt = data['createdAt'] as Timestamp?;
                  final read = (data['read'] ?? false) as bool;

                  return ListTile(
                    leading: CircleAvatar(
                      radius: 20,
                      backgroundColor: const Color(0xFFE6F0F5),
                      child: Text(
                        _initials(title),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (body.isNotEmpty) Text(body),
                        const SizedBox(height: 2),
                        Text(
                          _formatDate(createdAt),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!read)
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
                      // De momento solo se respeta el diseño
                    },
                  );
                },
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemCount: docs.length,
              );
            },
          ),
        ),
      ],
    );
  }

  /// Iniciales simples sin dependencia de `characters`.
  static String _initials(String text) {
    final parts = text.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    final first = parts.first[0];
    final last =
    (parts.length > 1 && parts.last.isNotEmpty) ? parts.last[0] : '';
    return (first + last).toUpperCase();
  }
}
