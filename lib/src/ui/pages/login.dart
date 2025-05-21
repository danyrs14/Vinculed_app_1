import 'package:flutter/material.dart';
import 'package:vinculed_app_1/src/ui/pages/modulo_candidato/menu.dart';
import 'package:vinculed_app_1/src/ui/pages/recpass.dart';
import 'package:vinculed_app_1/src/ui/widgets/buttons/large_buttons.dart';
import 'package:vinculed_app_1/src/ui/widgets/text_inputs/text_input.dart';
import 'package:vinculed_app_1/src/ui/widgets/textos/textos.dart'; // Para el texto de bienvenida

class LoginPage extends StatelessWidget {
  // Controladores para los campos de texto
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Fondo blanco
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0), // Espaciado de todo el contenido
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center, // Centra el contenido verticalmente
            crossAxisAlignment: CrossAxisAlignment.center, // Centra horizontalmente
            children: [
              // Logo en la parte superior
              Image.asset(
                'assets/images/anim.png', // Asegúrate de que tu imagen esté en esta ruta
                width: 150, // Ajusta el tamaño de la imagen
              ), // Espacio entre el logo y el formulario de inicio de sesión

              SizedBox(height: 10), // Espacio entre el título y los campos de entrada

              // Campo de texto para el email
              TextInput(
                controller: emailController,
                title: "Correo Institucional",
                keyboardType: TextInputType.emailAddress,
              ),

              SizedBox(height: 5), // Espacio entre los campos de texto

              // Campo de texto para la contraseña
              TextInput(
                controller: passwordController,
                title: "Contraseña",
                obscureText: true,

              ),

              SizedBox(height: 10), // Espacio entre los campos de texto y el botón

              // Botón de inicio de sesión
              LargeButton(
                title: "Iniciar Sesión",
                primaryColor: true,
                onTap: () {
                  // Lógica de inicio de sesión
                  String email = emailController.text;
                  String password = passwordController.text;
                  // Aquí iría tu lógica de autenticación
                  print("Email: $email, Password: $password");

                  // Navegar a la siguiente pantalla después de la autenticación
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => MenuPage()),
                  );
                },
              ),

              SizedBox(height: 20), // Espacio entre el botón y el texto de "olvidé mi contraseña"

              // Texto de "Se me olvidó mi contraseña"
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RecuperarPasswordScreen(),
                    ),
                  );
                  print("Recuperar contraseña");
                },
                child: Text(
                  '¿Se me olvidó mi contraseña?',
                  style: TextStyle(
                    color: Colors.blue,
                    fontSize: 16,
                    fontFamily: "Poppins",
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              SizedBox(height: 20), // Espacio entre los campos de texto y el botón

              // Botón de inicio de sesión
              LargeButton(
                title: "Registrarme como alumno",
                primaryColor: true,
                onTap: () {
                  // Lógica de inicio de sesión
                  String email = emailController.text;
                  String password = passwordController.text;
                  // Aquí iría tu lógica de autenticación
                  print("Email: $email, Password: $password");

                  // Navegar a la siguiente pantalla después de la autenticación
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => MenuPage()),
                  );
                },
              ),

              SizedBox(height: 10),

              // Botón de inicio de sesión
              LargeButton(
                title: "Registrarme como Recluta",
                primaryColor: true,
                onTap: () {
                  // Lógica de inicio de sesión
                  String email = emailController.text;
                  String password = passwordController.text;
                  // Aquí iría tu lógica de autenticación
                  print("Email: $email, Password: $password");

                  // Navegar a la siguiente pantalla después de la autenticación
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => MenuPage()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
