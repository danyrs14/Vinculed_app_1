import 'package:flutter/material.dart';
import 'package:vinculed_app_1/src/core/controllers/theme_controller.dart';
import 'package:vinculed_app_1/src/ui/widgets/buttons/mini_buttons.dart';

class EscomHeader3 extends StatelessWidget implements PreferredSizeWidget {
  const EscomHeader3({
    super.key,
    this.onMenuSelected,
    this.onLoginTap,
    this.onRegisterTap,
    this.onNotifTap,
  });

  /// Se llama cuando el usuario selecciona una opción del menú superior.
  final void Function(String label)? onMenuSelected;

  /// Tap en "Iniciar sesión"
  final VoidCallback? onLoginTap;

  /// Tap en "Crear cuenta"
  final VoidCallback? onRegisterTap;

  /// Si lo dejas null, el header abrirá su panel de notificaciones integrado.
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
    final theme = Theme.of(context);
    final color = theme.colorScheme;
    final isSmall = MediaQuery.of(context).size.width < 900;

    return Material(
      color: color.surface,
      elevation: 0,
      child: SafeArea(
        bottom: false,
        child: Container(
          height: kToolbarHeight,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: color.surface,
            border: Border(
              bottom: BorderSide(
                color: color.outlineVariant.withOpacity(0.5),
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [

              const SizedBox(width: 16),

              // Menú centrado (en desktop) o colapsado (en móvil)
              if (!isSmall)
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: _DesktopMenu(
                      items: _menuItems,
                      onTap: (label) => onMenuSelected?.call(label),
                    ),
                  ),
                )
              else
                const Spacer(),

              // Acciones a la derecha
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Notificaciones
                  _NotificationBell(
                    onTap: onNotifTap ?? () => _showNotifications(context),
                  ),
                  const SizedBox(width: 8),

                  // Botones de sesión
                  MiniButton(
                    title: 'Iniciar sesión',
                    onTap: onLoginTap,
                  ),
                  const SizedBox(width: 8),
                  MiniButton(
                    title: 'Crear cuenta',
                    onTap: onRegisterTap,
                  ),

                  // Menú hamburguesa (solo móvil)
                  if (isSmall) ...[
                    const SizedBox(width: 8),
                    _MobileMenuButton(
                      items: _menuItems,
                      onSelected: (label) => onMenuSelected?.call(label),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Future<void> _showNotifications(BuildContext context) async {
    final theme = Theme.of(context);
    final color = theme.colorScheme;

    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SizedBox(
          height: MediaQuery.of(ctx).size.height * 0.5,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Título
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text(
                  'Notificaciones',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Divider(height: 1),
              // Lista mock (puedes conectar aquí tu provider/bloc)
              Expanded(
                child: ListView.separated(
                  itemCount: 5,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: color.primary.withOpacity(0.1),
                        child: Icon(Icons.notifications, color: color.primary),
                      ),
                      title: Text('Nueva actualización #$i'),
                      subtitle: const Text('Revisa los nuevos cambios.'),
                      onTap: () => Navigator.of(ctx).pop(),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.hub_outlined,
          size: 28,
          color: color.primary,
        ),
        const SizedBox(width: 8),
        Text(
          'Vinculed',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          height: 22,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isDark ? color.primaryContainer : color.secondaryContainer,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            'BETA',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _DesktopMenu extends StatelessWidget {
  const _DesktopMenu({
    required this.items,
    required this.onTap,
  });

  final List<String> items;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme;

    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: items.map((label) {
        return InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => onTap(label),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Text(
              label,
              style: theme.textTheme.labelLarge?.copyWith(
                color: color.onSurface.withOpacity(0.9),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _MobileMenuButton extends StatelessWidget {
  const _MobileMenuButton({
    required this.items,
    required this.onSelected,
  });

  final List<String> items;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;

    return PopupMenuButton<String>(
      tooltip: 'Menú',
      position: PopupMenuPosition.under,
      onSelected: onSelected,
      itemBuilder: (ctx) => items
          .map(
            (e) => PopupMenuItem<String>(
          value: e,
          child: Text(e),
        ),
      )
          .toList(),
      child: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border.all(color: color.outlineVariant),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(Icons.menu, color: color.onSurface),
      ),
    );
  }
}

class _NotificationBell extends StatelessWidget {
  const _NotificationBell({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border.all(color: color.outlineVariant),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.notifications_none_rounded, color: color.onSurface),
          ),
          // Badge (mock). Sustituye por tu indicador real si tienes conteo.
          Positioned(
            right: -2,
            top: -2,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: color.error,
                shape: BoxShape.circle,
                border: Border.all(color: color.surface, width: 2),
              ),
              child: const SizedBox(width: 4, height: 4),
            ),
          ),
        ],
      ),
    );
  }
}
