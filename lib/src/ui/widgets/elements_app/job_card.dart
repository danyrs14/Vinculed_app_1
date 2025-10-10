import 'package:flutter/material.dart';
import 'package:vinculed_app_1/src/core/controllers/theme_controller.dart';
import 'package:vinculed_app_1/src/ui/widgets/buttons/mini_buttons.dart';
import 'package:vinculed_app_1/src/ui/widgets/textos/textos.dart';

/// Modelo de datos de una vacante.
class JobData {
  final String title;
  final String city;
  final String company;

  const JobData({
    required this.title,
    required this.city,
    required this.company,
  });
}

/// Tarjeta visual de la vacante.
/// - Usa [onApply], [onFavoriteTap] y [onHide] para inyectar lógica.
/// - Si las callbacks van null, muestra SnackBars por defecto.
class JobCard extends StatelessWidget {
  const JobCard({
    super.key,
    required this.data,
    this.onApply,
    this.onFavoriteTap,
    this.onHide,
    this.isFavorite = false,
  });

  final JobData data;
  final VoidCallback? onApply;
  final VoidCallback? onFavoriteTap;
  final VoidCallback? onHide;

  /// Solo para pintar el icono lleno/vacío si lo manejas externamente.
  final bool isFavorite;

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;

    return Card(
      color: theme.background(),
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: theme.secundario(), width: 1.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Título
            Texto(text: data.title, fontSize: 18),
            const SizedBox(height: 6),

            // Ciudad
            Texto(text: data.city, fontSize: 14),
            const SizedBox(height: 16),

            // Empresa
            Texto(text: data.company, fontSize: 14),
            const SizedBox(height: 18),

            // Acciones: corazón | Postularme | ocultar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: onFavoriteTap ?? () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Guardado en favoritos')),
                    );
                  },
                  icon: Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: theme.secundario(),
                  ),
                  tooltip: isFavorite ? 'Quitar de favoritos' : 'Guardar',
                ),

                SizedBox(
                  width: 160,
                  height: 38,
                  child: MiniButton(
                    onTap: onApply ?? () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Postulación enviada a ${data.company}')),
                      );
                    },
                    title: 'Postularme',
                  ),
                ),

                IconButton(
                  onPressed: onHide ?? () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Vacante ocultada')),
                    );
                  },
                  icon: Icon(Icons.visibility_off, color: theme.secundario()),
                  tooltip: 'Ocultar',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
