import 'package:flutter/material.dart';
import 'package:vinculed_app_1/src/core/controllers/theme_controller.dart';

class Texto extends StatelessWidget {
  final String text;
  final double fontSize;
  final FontWeight fontWeight;
  final bool color;
  final TextAlign textAlign;
  final int maxLines;
  final TextOverflow overflow;

  const Texto({
    Key? key,
    required this.text,
    this.fontSize = 26.0,
    this.fontWeight = FontWeight.w600,
    this.color= true,
    this.textAlign = TextAlign.start,
    this.maxLines = 1,
    this.overflow = TextOverflow.ellipsis,
  }) : super(key: key);

  Color getColorText() {
    return this.color
        ? ThemeController.instance.fuente()
        : ThemeController.instance.fuente();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Text(
        text,
        maxLines: maxLines,
        overflow: overflow,
        textAlign: textAlign,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: getColorText(), // Usa el método para obtener el color
          fontFamily: 'Poppins', // Fuente personalizada
        ),
      ),
    );
  }
}
