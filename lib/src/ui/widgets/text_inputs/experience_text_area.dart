import 'package:flutter/material.dart';
import 'package:vinculed_app_1/src/core/controllers/theme_controller.dart';
import 'package:vinculed_app_1/src/ui/widgets/text_inputs/text_input.dart';

class ExperienceTextArea extends StatelessWidget {
  const ExperienceTextArea({
    super.key,
    required this.controller,
    this.hintText = '¿Qué nos quieres compartir?',
    this.height = 220,
  });

  final TextEditingController controller;
  final String hintText;
  final double height;

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
      child: TextInput(
        controller: controller,
        title: hintText,
        ),
    );
  }
}
