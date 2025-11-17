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
  final FormFieldValidator<T>? validator;
  final Icon? icon; // nuevo icono visual

  const DropdownInput({
    Key? key,
    this.title = "",
    this.required = false,
    this.enabled = true,
    this.primaryColor = true,
    required this.items,
    this.value,
    this.onChanged,
    this.validator,
    this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;

    Color getTextColor() => primaryColor ? theme.fuente() : theme.fuente();
    Color getBorderColor() => primaryColor ? theme.secundario() : theme.secundario();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 4.0),
      child: DropdownButtonFormField<T>(
        value: value,
        items: items,
        onChanged: enabled ? onChanged : null,
        validator: validator,
        decoration: InputDecoration(
          isDense: true,
            labelText: required ? '$title*' : title,
            labelStyle: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Colors.grey,
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
              borderSide: BorderSide(color: getBorderColor(), width: 1.4),
            ),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 14.0,
              horizontal: 12.0,
            ),
            prefixIcon: icon != null
                ? IconTheme(
                    data: IconThemeData(
                      color: theme.fuente(),
                      size: 20,
                    ),
                    child: icon!,
                  )
                : null,
        ),
        style: TextStyle(
          fontSize: 14,
          color: getTextColor(),
          fontFamily: 'Poppins',
        ),
        iconEnabledColor: getTextColor(),
        dropdownColor: Colors.white,
      ),
    );
  }
}
