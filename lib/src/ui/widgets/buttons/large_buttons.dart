//esta clase es para botones largos, es decir para aquellos botones que son muy importantes y/o que solo aparecen por una sola vez
import 'package:flutter/material.dart';
import 'package:vinculed_app_1/src/core/controllers/theme_controller.dart';

class LargeButton extends StatelessWidget {
  final String title;
  final bool primaryColor;
  final IconData? icon;
  final Function? onTap;

  const LargeButton({
    Key? key,
    this.title = "",
    this.primaryColor = true,
    this.icon,
    this.onTap,
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
        foregroundColor: getColorText(), // Color del texto del botón
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8), // Bordes redondeados
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 24,
              color: getColorText(),
            ),
            const SizedBox(width: 10),
          ],
          Flexible(
            child: Text(
              title,
              textAlign: TextAlign.center,
              softWrap: true,
              maxLines: 2,
              overflow: TextOverflow.visible,
              style: const TextStyle(
                fontSize: 17, // ligeramente menor para evitar cortes
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
