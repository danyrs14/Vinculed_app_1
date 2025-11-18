import 'package:flutter/material.dart';
import 'package:vinculed_app_1/src/core/controllers/theme_controller.dart';

class StyledTextFormField extends StatefulWidget {
  final TextEditingController? controller;
  final String title;
  final TextInputType keyboardType;
  final bool obscureText;
  final FormFieldValidator<String>? validator;
  final Icon? icon;
  final Function(String)? onChanged;
  final bool isPasswordField;
  final int? maxLines;
  final int? maxLength;
  final bool? isRequired;

  const StyledTextFormField({
    Key? key,
    this.controller,
    required this.title,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.validator,
    this.icon,
    this.onChanged,
    this.isPasswordField = false,
    this.maxLines,
    this.maxLength,
    this.isRequired,
  }) : super(key: key);

  @override
  _StyledTextFormFieldState createState() => _StyledTextFormFieldState();
}
class _StyledTextFormFieldState extends State<StyledTextFormField> {
  late bool _isObscured; // Estado para mostrar/ocultar la contraseña

  @override
  void initState() {
    super.initState();
    _isObscured = widget.obscureText;
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;
    final bool isRequired = widget.validator != null;
    final localIcon = widget.icon;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: TextFormField( 
        controller: widget.controller,
        obscureText: _isObscured,
        cursorColor: theme.secundario(),
        keyboardType: widget.keyboardType,
        maxLines: widget.maxLines ?? 1,
        maxLength: widget.maxLength,
        validator: widget.validator, 
        onChanged: widget.onChanged,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w400,
          color: theme.fuente(),
          fontFamily: 'Poppins',
        ),
        decoration: InputDecoration(
          labelText: widget.isRequired! ? '${widget.title}*' : widget.title,
          labelStyle: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w400,
            // El color del label ahora lo maneja el estado del TextFormField (error, focus, etc)
            // Pero podemos darle un color inicial.
            color: Colors.grey,
            fontFamily: 'Poppins',
          ),
          // El color del texto flotante
          floatingLabelStyle: TextStyle(
            color: theme.fuente(),
            fontFamily: 'Poppins',
          ),
          // Borde estándar
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: theme.secundario(),
            ),
          ),
          // Borde cuando el campo tiene el foco
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: theme.secundario(),
              width: 1.5,
            ),
          ),
          // Borde cuando hay un error de validación
          errorBorder: OutlineInputBorder(
            borderSide: const BorderSide(
              color: Colors.red,
              width: 1.5,
            ),
          ),
          // Borde cuando hay un error y el campo tiene el foco
          focusedErrorBorder: OutlineInputBorder(
            borderSide: const BorderSide(
              color: Colors.red,
              width: 2.0,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            vertical: 18.0,
            horizontal: 18.0,
          ),
          prefixIcon: localIcon != null
              ? IconTheme(
                  data: IconThemeData(
                    color: theme.fuente(),
                    size: 24,
                  ),
                  child: localIcon,
                )
              : null,
          suffixIcon: widget.isPasswordField
              ? IconButton(
                  icon: Icon(
                    //Cambia el icono basado en el estado de _isObscured
                    _isObscured ? Icons.visibility_off : Icons.visibility,
                    color: Colors.grey,
                  ),
                  onPressed: () {
                    setState(() {
                      _isObscured = !_isObscured;
                    });
                  },
                )
              : null,
        ),
      ),
    );
  }
}