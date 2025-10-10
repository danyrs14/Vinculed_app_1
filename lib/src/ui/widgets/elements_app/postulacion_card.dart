import 'package:flutter/material.dart';
import 'package:vinculed_app_1/src/core/controllers/theme_controller.dart';
import 'package:vinculed_app_1/src/ui/widgets/buttons/mini_buttons.dart';
import 'package:vinculed_app_1/src/ui/widgets/textos/textos.dart';

/// Tarjeta reutilizable para mostrar una postulación.
///
/// Nuevo comportamiento:
/// - **Mantén presionada** la tarjeta para abrir un AlertDialog de confirmación
///   de "Despostular". Si el usuario confirma, se ejecuta [onUnapply].
///
/// Uso típico:
/// const PostulacionCard.postulado(
///   title: 'Becario de QA',
///   company: 'BBVA Mexico',
///   city: 'Ciudad de Mexico',
///   onUnapply: () { /* quita este item de la lista */ },
/// )
class PostulacionCard extends StatelessWidget {
  const PostulacionCard({
    super.key,
    required this.title,
    required this.company,
    required this.city,
    this.statusText = 'POSTULADO',
    this.statusIcon = Icons.check_circle,
    this.statusColor,
    this.onTap,
    this.onUnapply,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
    this.borderRadius = 4.0,
    this.showBorder = true,
  });

  /// Título del puesto (ej. "Becario de QA")
  final String title;

  /// Empresa (ej. "BBVA Mexico")
  final String company;

  /// Ciudad (ej. "Ciudad de Mexico")
  final String city;

  /// Texto de estado (por defecto "POSTULADO")
  final String statusText;

  /// Ícono del estado (por defecto check)
  final IconData statusIcon;

  /// Color del estado. Si es null, se usa `theme.secundario()`
  final Color? statusColor;

  /// Callback al tocar la tarjeta (opcional)
  final VoidCallback? onTap;

  /// Callback cuando el usuario confirma "Despostular".
  /// El padre debe eliminar la tarjeta de su lista para que desaparezca.
  final VoidCallback? onUnapply;

  /// Relleno interno de la tarjeta
  final EdgeInsets padding;

  /// Radio del borde
  final double borderRadius;

  /// Mostrar borde (true por defecto)
  final bool showBorder;

  /// Constructor de conveniencia para estado "POSTULADO".
  const factory PostulacionCard.postulado({
    Key? key,
    required String title,
    required String company,
    required String city,
    VoidCallback? onTap,
    VoidCallback? onUnapply,
  }) = _PostulacionCardPostulado;

  Future<void> _handleUnapply(BuildContext context, ThemeController theme) async {
    if (onUnapply == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.background(),
        title: Text('Despostular', style: TextStyle(color: theme.fuente()),),
        content: Text('¿Quieres despostularte de esta vacante?', style: TextStyle(color: theme.fuente())),
        actions: [
          MiniButton(
            onTap: () => Navigator.pop(ctx, false),
            title: 'Cancelar',
          ),
          MiniButton(
            onTap: () => Navigator.pop(ctx, true),
            title: 'Despostular',
          ),
        ],
      ),
    );

    if (confirmed == true) {
      onUnapply!.call();
      // Feedback opcional
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Has cancelado tu postulación.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;
    final colorEstado = statusColor ?? theme.secundario();

    final content = Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.background(),
        border: showBorder
            ? Border.all(color: theme.secundario(), width: 1)
            : null,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      padding: padding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Texto(text: title, fontSize: 18),
          const SizedBox(height: 6),
          Texto(text: company, fontSize: 14),
          const SizedBox(height: 10),
          Texto(text: city, fontSize: 14),
          const SizedBox(height: 14),

          Icon(statusIcon, color: colorEstado, size: 24),
          const SizedBox(height: 10),

          Text(
            statusText.toUpperCase(),
            style: TextStyle(
              fontSize: 16,
              color: colorEstado,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
          // Ya no hay botón "Despostular"; ahora es por long press en toda la tarjeta.
        ],
      ),
    );

    // Envolvemos SIEMPRE en Material+InkWell para captar onTap y onLongPress.
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(borderRadius),
        onTap: onTap, // opcional
        onLongPress: onUnapply == null
            ? null
            : () => _handleUnapply(context, theme), // long press => diálogo
        child: content,
      ),
    );
  }
}

/// Implementación concreta del constructor de conveniencia `postulado`.
class _PostulacionCardPostulado extends PostulacionCard {
  const _PostulacionCardPostulado({
    super.key,
    required super.title,
    required super.company,
    required super.city,
    super.onTap,
    super.onUnapply,
  }) : super(
    statusText: 'POSTULADO',
    statusIcon: Icons.check_circle,
  );
}
