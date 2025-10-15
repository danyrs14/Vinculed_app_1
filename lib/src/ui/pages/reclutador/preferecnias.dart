import 'package:flutter/material.dart';
import 'package:vinculed_app_1/src/core/controllers/theme_controller.dart';
import 'package:vinculed_app_1/src/ui/widgets/buttons/mini_buttons.dart';
import 'package:vinculed_app_1/src/ui/widgets/textos/textos.dart';

class PreferenciasRec extends StatelessWidget {
  const PreferenciasRec({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;

    // Scaffold da el ancestro Material que requiere InkWell
    return Scaffold(
      backgroundColor: theme.background(),
      body: SafeArea(
        // Scroll para evitar overflow del Column
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Encabezado sin AppBar: back a la izquierda y título centrado
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                    color: Colors.black87,
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  const Expanded(
                    child: Center(
                      child: Texto(
                        text: 'Preferencias',
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  // Espaciador del ancho del IconButton para mantener el título centrado
                  const SizedBox(width: 48),
                ],
              ),
              const SizedBox(height: 14),

              // Opciones
              _PrefItem(
                title: 'Activar Notificaciones',
                onTap: () => _showNotifDialog(context),
              ),
              _PrefItem(
                title: 'Modo Oscuro',
                onTap: () => _showDarkModeDialog(context),
              ),
              _PrefItem(
                title: 'Ubicacion',
                onTap: () => _showLocationDialog(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static void _snack(BuildContext context, String msg) {
    final theme = ThemeController.instance;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: theme.primario()),
    );
  }

  static Future<void> _showNotifDialog(BuildContext context) async {
    final theme = ThemeController.instance;
    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: theme.background(),
        title: const Text('Activar Notificaciones'),
        content: const Text('¿Deseas permitir notificaciones para recibir novedades?'),
        actions: [
          MiniButton(
            onTap: () => Navigator.pop(context),
            title: 'Denegar',
          ),
          MiniButton(
            onTap: () {
              Navigator.pop(context);
              _snack(context, 'Notificaciones activadas');
            },
            title: 'Aceptar',
          ),
        ],
      ),
    );
  }

  static Future<void> _showDarkModeDialog(BuildContext context) async {
    final theme = ThemeController.instance;
    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: theme.background(),
        title: const Text('Modo Oscuro'),
        content: const Text('Activa el modo oscuro para una mejor experiencia nocturna.'),
        actions: [
          MiniButton(
            onTap: () => Navigator.pop(context),
            title: 'Cancelar',
          ),
          MiniButton(
            onTap: () {
              Navigator.pop(context);
              _snack(context, 'Modo oscuro activado');
              // Aquí podrías llamar a ThemeController para alternar el tema.
            },
            title: 'Activar',
          ),
        ],
      ),
    );
  }

  static Future<void> _showLocationDialog(BuildContext context) async {
    final theme = ThemeController.instance;
    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: theme.background(),
        title: const Text('Permitir Ubicación'),
        content: const Text('¿Autorizar el acceso a tu ubicación para mejorar recomendaciones?'),
        actions: [
          MiniButton(
            onTap: () => Navigator.pop(context),
            title: 'Denegar',
          ),
          MiniButton(
            onTap: () {
              Navigator.pop(context);
              _snack(context, 'Ubicación autorizada');
            },
            title: 'Aceptar',
          ),
        ],
      ),
    );
  }
}

/// Item simple (texto + chevron) con InkWell
class _PrefItem extends StatelessWidget {
  const _PrefItem({required this.title, this.onTap});

  final String title;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
            const Icon(Icons.chevron_right_rounded, size: 24, color: Colors.black87),
          ],
        ),
      ),
    );
  }
}
