import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vinculed_app_1/src/core/controllers/theme_controller.dart';
import 'package:vinculed_app_1/src/ui/widgets/text_inputs/text_input.dart';

class ExperienceTextArea extends StatelessWidget {
  const ExperienceTextArea({
    super.key,
    required this.controller,
    this.hintText = '¿Qué nos quieres compartir?',
    this.height = 220,
    this.maxLength = 5000, // NUEVO
  });

  final TextEditingController controller;
  final String hintText;
  final double height;
  final int maxLength;

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: theme.secundario(), width: 1.2),
        borderRadius: BorderRadius.circular(6),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      // Reemplazo interno por TextField nativo para asegurar el límite de caracteres.
      child: TextField(
        controller: controller,
        maxLength: maxLength,
        maxLines: null,
        expands: true,
        inputFormatters: [
          LengthLimitingTextInputFormatter(maxLength),
        ],
        decoration: InputDecoration(
          counterText: '', // el contador lo muestro afuera en la página
          hintText: hintText,
          border: InputBorder.none,
          isCollapsed: true,
        ),
      ),
    );
  }
}
