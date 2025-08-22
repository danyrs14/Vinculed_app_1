import 'package:flutter/material.dart';
import 'package:vinculed_app_1/src/core/controllers/theme_controller.dart';

class DropdownInput<T> extends StatelessWidget {
  final String title;
  final bool required;
  final bool enabled;
  final bool primaryColor;
  final List<DropdownMenuItem<T>> items;
  final T? value;
  final void Function(T?)? onChanged;

  const DropdownInput({
    Key? key,
    this.title = "",
    this.required = false,
    this.enabled = true,
    this.primaryColor = true,
    required this.items,
    this.value,
    this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;

    Color getTextColor() =>
        primaryColor ? theme.fuente() : theme.fuente();

    Color getBorderColor() =>
        primaryColor ? theme.secundario() : theme.secundario();

    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: DropdownButtonFormField<T>(
        value: value,
        items: items,
        onChanged: enabled ? onChanged : null,
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
            borderSide: BorderSide(color: getBorderColor()),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: getBorderColor(), width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(
            vertical: 18.0,
            horizontal: 18.0,
          ),
        ),
        style: TextStyle(
          fontSize: 18,
          color: getTextColor(),
          fontFamily: 'Poppins',
        ),
        iconEnabledColor: getTextColor(),
        dropdownColor: Theme.of(context).scaffoldBackgroundColor,
      ),
    );
  }
}
