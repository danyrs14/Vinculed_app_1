import 'package:flutter/material.dart';
import 'package:vinculed_app_1/src/core/controllers/theme_controller.dart';

class TextInput extends StatelessWidget {
  final TextEditingController? controller;
  final String title;
  final TextInputType keyboardType;
  final bool obscureText;
  final bool autofocus;
  final int? maxLength;
  final int maxLines;
  final int minLines;
  final bool enabled;
  final TextAlign textAlign;
  final Icon? icon;
  final bool required;
  final Function? onChanged;
  final bool primaryColor;

  const TextInput({
    Key? key,
    this.controller,
    this.title = "",
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.autofocus = false,
    this.maxLength,
    this.maxLines = 1,
    this.minLines = 1,
    this.enabled = true,
    this.textAlign = TextAlign.start,
    this.icon,
    this.required = false,
    this.primaryColor = true,
    this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;
    Color getTextColor() {
      return this.primaryColor
          ? ThemeController.instance.fuente()
          : ThemeController.instance.fuente(); // Cambia el color según el estado
    }

    Color getBorderColor() {

      return this.primaryColor
          ? ThemeController.instance.secundario()
          : ThemeController.instance.secundario(); // Si es obligatorio, borde rojo
    }

    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          TextField(
            controller: controller,
            obscureText: obscureText,
            cursorColor: theme.secundario(),
            keyboardType: keyboardType,
            autofocus: autofocus,
            maxLength: maxLength,
            maxLines: maxLines,
            minLines: minLines,
            enabled: enabled,
            textAlign: textAlign,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w400,
              color: getTextColor(),
              fontFamily: 'Poppins',
            ),
            onChanged: onChanged != null
                ? (value) => onChanged!(value)
                : null,
            decoration: InputDecoration(
              labelText: required ? '$title*' : title,
              labelStyle: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w400,
                color: required ? Colors.red : Colors.grey,
                fontFamily: 'Poppins',
              ),
              floatingLabelStyle: TextStyle(
                color: getTextColor(),
                fontFamily: 'Poppins',
              ),
              border: const OutlineInputBorder(),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: getBorderColor(), // Borde dinámico
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: getBorderColor(),
                  width: 1.5,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                vertical: 18.0,
                horizontal: 18.0,
              ),
              prefixIcon: icon != null
                  ? IconTheme(
                data: IconThemeData(
                  color: theme.fuente(),
                  size: 24,
                ),
                child: icon!,
              )
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}
