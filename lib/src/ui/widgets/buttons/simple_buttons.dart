//esta clase es para botones simples, el uso de ellos es para cosas poco significativas y/o repetitivas
import 'package:flutter/material.dart';
import 'package:vinculed_app_1/src/core/controllers/theme_controller.dart';

class SimpleButton extends StatelessWidget {
  final String title;
  final bool primaryColor;
  final IconData? icon;
  final Function? onTap;

  const SimpleButton({
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
        foregroundColor: getColorText(), // Color del texto
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8), // Bordes redondeados
        ),
        padding: EdgeInsets.symmetric(
            horizontal: 24.0, vertical: 16.0), // Padding del botón
        minimumSize: Size(0,
            0), // Permite que el tamaño mínimo sea dinámico según el contenido
        tapTargetSize:
        MaterialTapTargetSize.shrinkWrap, // Ajusta el tamaño al contenido
      ),
      child: Row(
        mainAxisSize:
        MainAxisSize.min, // Ajusta el Row al tamaño mínimo necesario
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              color: getColorText(), // Usa el color del texto para el ícono
              size: 24,
            ),
            SizedBox(width: 8), // Espacio entre el ícono y el texto
          ],
          Text(
            title,
            style: TextStyle(
              color: getColorText(), // Color del texto
              fontSize: 15, // Tamaño de la fuente del texto
              fontWeight: FontWeight.w600, // Peso de la fuente (SemiBold)
              fontFamily: 'Poppins', // Fuente personalizada
            ),
          ),
        ],
      ),
    );
  }
}
