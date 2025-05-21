import 'package:flutter/material.dart';
import 'package:vinculed_app_1/src/ui/widgets/buttons/large_buttons.dart';
import 'package:vinculed_app_1/src/ui/widgets/text_inputs/text_input.dart';

class RecuperarPasswordScreen extends StatefulWidget {
  @override
  _RecuperarPasswordScreenState createState() => _RecuperarPasswordScreenState();
}

class _RecuperarPasswordScreenState extends State<RecuperarPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _recuperarContrasena() {
    // Aquí va la lógica para recuperar contraseña
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Por favor, ingresa tu correo institucional')),
      );
      return;
    }
    // Lógica para recuperar contraseña
    print('Recuperar contraseña para: $email');
  }

  void _iniciarSesion() {
    // Aquí va la lógica para iniciar sesión
    print('Ir a iniciar sesión');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Image.asset(
                  'assets/images/anim.png', // Asegúrate de que tu imagen esté en esta ruta
                  width: 150, // Ajusta el tamaño de la imagen
                ),
              ),
              SizedBox(height: 24),
              TextInput(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                title: "Correo Institucional",
              ),
              SizedBox(height: 16),
              LargeButton(
                title: "Recuperar Contraseña",
              ),
              SizedBox(height: 12),
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
              SizedBox(height: 12),
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
    );
  }
}
