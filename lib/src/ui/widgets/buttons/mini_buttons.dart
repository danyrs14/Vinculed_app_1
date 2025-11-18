import 'package:flutter/material.dart';
import 'package:vinculed_app_1/src/core/controllers/theme_controller.dart';

class MiniButton extends StatelessWidget {
  final String title;
  final bool primaryColor;
  final IconData? icon;
  final Function? onTap;
  // New: compact style for tight spaces (e.g., mobile headers)
  final bool dense;

  const MiniButton({
    Key? key,
    this.title = "",
    this.primaryColor = true,
    this.icon,
    this.onTap,
    this.dense = false,
  }) : super(key: key);

  Color getColor() {
    return this.primaryColor
        ? ThemeController.instance.secundario()
        : ThemeController.instance.secundario();
  }

  Color getColorText() {
    return this.primaryColor
        ? ThemeController.instance.primario()
        : ThemeController.instance.primario();
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        if (onTap != null) {
          onTap!(); // Llama a la función onTap si está definida
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: getColor(), // Fondo del botón
        foregroundColor: getColorText(), // Color del texto
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(dense ? 6 : 8), // Bordes
        ),
        padding: EdgeInsets.symmetric(
          horizontal: dense ? 12.0 : 21.0,
          vertical: dense ? 8.0 : 13.0,
        ), // Padding del botón
        minimumSize: const Size(0, 0),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              color: getColorText(),
              size: dense ? 18 : 20,
            ),
            const SizedBox(width: 6),
          ],
          Text(
            title,
            style: TextStyle(
              color: getColorText(),
              fontSize: dense ? 12 : 13,
              fontWeight: FontWeight.w600,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }
}
