import 'package:flutter/material.dart';
import 'package:vinculed_app_1/src/core/controllers/theme_controller.dart';

class MiniTextInput extends StatelessWidget {
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

  const MiniTextInput({
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
    this.onChanged, // Parámetro para manejar el cambio de texto
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          TextField(
            controller: controller,
            obscureText: obscureText,
            cursorColor: const Color(0xFF002E6D),
            keyboardType: keyboardType,
            autofocus: autofocus,
            maxLength: maxLength,
            maxLines: maxLines,
            minLines: minLines,
            enabled: enabled,
            textAlign: textAlign,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w400,
              color: Colors.black,
              fontFamily: 'Poppins',
            ),
            onChanged: onChanged != null
                ? (value) => onChanged!(value) // Si el callback es proporcionado, se ejecuta
                : null,
            decoration: InputDecoration(
              // Si el campo es obligatorio, se muestra un asterisco rojo
              labelText: required ? '$title*' : title,
              labelStyle: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w400,
                color: required
                    ? Colors.red
                    : Colors.grey, // Si es obligatorio, el color es rojo
                fontFamily: 'Poppins',
              ),
              floatingLabelStyle: const TextStyle(
                color: Color(0xFF002E6D),
                fontFamily: 'Poppins',
              ),
              filled: true, // Se habilita el fondo
              fillColor: Colors.white, // El fondo será blanco
              border: const OutlineInputBorder(),
              enabledBorder: const OutlineInputBorder(
                borderSide: BorderSide(
                  color: Color(0xFF002E6D),
                ),
              ),
              focusedBorder: const OutlineInputBorder(
                borderSide: BorderSide(
                  color: Color(0xFF002E6D),
                  width: 1.5,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                vertical: 18.0,
                horizontal: 18.0,
              ),
              prefixIcon: icon != null
                  ? IconTheme(
                data: const IconThemeData(
                  color: Color(0xFF002E6D), // Color del ícono
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
