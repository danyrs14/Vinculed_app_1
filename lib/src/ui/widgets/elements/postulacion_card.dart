import 'package:flutter/material.dart';
import 'package:vinculed_app_1/src/core/controllers/theme_controller.dart';

class ApplicationCard extends StatelessWidget {
  const ApplicationCard({
    super.key,
    required this.title,
    required this.company,
    required this.location,
    required this.statusLabel,
    this.statusIcon = Icons.check_circle_outline,
    this.onTap,
    this.maxWidth = 850,
  });

  final String title;
  final String company;
  final String location;
  final String statusLabel;
  final IconData statusIcon;
  final VoidCallback? onTap;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;
    // Calculamos el ancho disponible en pantalla restando un padding horizontal estimado
    // (en la vista padre se usan 24 px a cada lado). Así las tarjetas ocupan el ancho
    // disponible hasta alcanzar el maxWidth configurado.
    final screenWidth = MediaQuery.of(context).size.width;
    double availableWidth = screenWidth - 48; // padding 24 * 2 utilizado en la página padre
    if (availableWidth > maxWidth) availableWidth = maxWidth; // respetar maxWidth
    if (availableWidth < 0) availableWidth = screenWidth; // fallback por seguridad

    final card = Container(
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 18),
      decoration: BoxDecoration(
        color: theme.background(),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.secundario(), width: 1.3),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800), // un poquito más grande
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            company,
            style: const TextStyle(color: Colors.black87, fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            location,
            style: const TextStyle(color: Colors.black54, fontSize: 15),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),
          Icon(statusIcon, color: theme.secundario(), size: 28),
          const SizedBox(height: 10),
          Text(
            statusLabel,
            style: TextStyle(
              color: theme.secundario(),
              fontWeight: FontWeight.w800,
              letterSpacing: .4,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );

    return Center(
      child: SizedBox(
        width: availableWidth,
        child: onTap == null
            ? card
            : Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: onTap,
                  child: card,
                ),
              ),
      ),
    );
  }
}
