import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:vinculed_app_1/src/ui/widgets/buttons/large_buttons.dart';
import 'package:vinculed_app_1/src/ui/widgets/text_inputs/text_form_field.dart';

class RecuperarPasswordScreen extends StatefulWidget {
  @override
  _RecuperarPasswordScreenState createState() => _RecuperarPasswordScreenState();
}

class _RecuperarPasswordScreenState extends State<RecuperarPasswordScreen> {
  final _recPassFormKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future <void> _recuperarContrasena() async {
    if (!_recPassFormKey.currentState!.validate()) {
      return;
    }
    // Lógica para recuperar contraseña
    //print('Recuperar contraseña para: $email');
    await FirebaseAuth.instance.sendPasswordResetEmail(email: _emailController.text.trim())
        .then((value) => _showError("Si estás registrado, se te ha enviado un correo para restablecer tu contraseña. Revisa tu bandeja de entrada."))
        .catchError((error) => _showError("Ocurrió un error, intenta de nuevo"));
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 4),),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _recPassFormKey,
            child: Column(
              children: [
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Image.asset(
                    'assets/images/anim.png', // Asegúrate de que tu imagen esté en esta ruta
                    width: 150, // Ajusta el tamaño de la imagen
                  ),
                ),
                const SizedBox(height: 24),
                StyledTextFormField(
                  isRequired: true,
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  title: "Correo electrónico",
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, ingresa tu correo electrónico';
                    }
                    // Expresión regular simple para validar el formato del correo electrónico
                    final emailRegex = RegExp(r'/^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/');
                    if (!emailRegex.hasMatch(value)) {
                      return 'Ingresa un correo electrónico válido';
                    }
                    return null; // Retorna null si la validación es exitosa
                  },
                ),
                const SizedBox(height: 16),
                LargeButton(
                  title: "Recuperar Contraseña",
                  onTap: _recuperarContrasena,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Divider(color: Colors.grey.shade300, thickness: 2),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        '¿Todo esta en orden?',
                        style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                      ),
                    ),
                    Expanded(
                      child: Divider(color: Colors.grey.shade300, thickness: 2),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                LargeButton(
                  title: "Iniciar Sesión",
                  onTap: (){
                    Navigator.pop(context);
                  },
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
