import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:vinculed_app_1/src/core/controllers/theme_controller.dart';
import 'package:vinculed_app_1/src/ui/pages/candidato/comentarios.dart';
import 'package:vinculed_app_1/src/ui/pages/reclutador/ayuda.dart';
import 'package:vinculed_app_1/src/ui/pages/reclutador/preferecnias.dart';
import 'package:vinculed_app_1/src/ui/widgets/textos/textos.dart';

class AjustesRec extends StatelessWidget {
  const AjustesRec({super.key});

  @override
  Widget build(BuildContext context) {
    final usuario = FirebaseAuth.instance.currentUser!;
    final theme = ThemeController.instance;

    return Scaffold(
      backgroundColor: theme.background(),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Título centrado (tal cual lo pediste)
              Row(
                children: const [
                  SizedBox(width: 4),
                  Expanded(
                    child: Center(
                      child: Texto(text: 'Ajustes', fontSize: 22),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Tarjeta con usuario y opciones
              Material(
                elevation: 3,
                borderRadius: BorderRadius.circular(16),
                color: theme.background(),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: theme.background(),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Encabezado de la tarjeta: avatar + @usuario
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: Colors.blue[50],
                              backgroundImage: usuario.photoURL != null ? NetworkImage(usuario.photoURL!) : null,
                              child: usuario.photoURL == null ? const Icon(Icons.person, size: 18, color: Colors.blueGrey) : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                usuario.displayName ?? 'Reclutador',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: theme.primario(), // azul del user
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),

                      // Items
                      _SettingsItem(
                        title: 'Obtener Ayuda',
                        onTap: () {
                          // Navega a tu pantalla de ayuda/comentarios si la tienes
                          // Si no quieres navegar, cambia por un SnackBar.
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => AyudaRec(),
                            ),
                          );
                        },
                      ),
                      _SettingsItem(
                        title: 'Preferencias',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => PreferenciasRec(),
                            ),
                          );
                        },
                      ),
                      _SettingsItem(
                        title: 'Cerrar Sesion',
                        isDestructive: true,
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Cerrando sesión...'),
                            ),
                          );
                          // Aquí conecta tu lógica de signOut cuando la tengas
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),
              // espacio flexible para que la tarjeta no quede pegada al borde inferior
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

/// ---- Item de ajustes (texto + chevron) ----
class _SettingsItem extends StatelessWidget {
  const _SettingsItem({
    required this.title,
    this.onTap,
    this.isDestructive = false,
  });

  final String title;
  final VoidCallback? onTap;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight:
                  isDestructive ? FontWeight.w700 : FontWeight.w600,
                  color: isDestructive ? Colors.red : theme.fuente(),
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              size: 24,
              color: Color(0xFF0D1B2A), // similar al chevron oscuro de la imagen
            ),
          ],
        ),
      ),
    );
  }
}

/// Dummy de comentarios para el ejemplo.
/// Asegúrate que el import apunte a la clase correcta de tu proyecto.
/// Si tu clase se llama distinto, cambia `ComentariosPage` arriba.
class ComentariosPage extends StatelessWidget {
  const ComentariosPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Obtener Ayuda')),
      body: const Center(child: Text('Pantalla de ayuda/comentarios')),
    );
  }
}
