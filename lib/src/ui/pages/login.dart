import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:vinculed_app_1/src/ui/pages/candidato/lector_qr.dart';
import 'package:vinculed_app_1/src/ui/pages/candidato/menu.dart';
import 'package:vinculed_app_1/src/ui/pages/reclutador/registrar_reclutador.dart';
import 'package:vinculed_app_1/src/ui/pages/recpass.dart';
import 'package:vinculed_app_1/src/ui/widgets/buttons/large_buttons.dart';
import 'package:vinculed_app_1/src/ui/widgets/text_inputs/text_form_field.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _loginFormKey = GlobalKey<FormState>();
  // Controladores para los campos de texto
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _isLoading = false;

  //Iniciar sesión
  Future<void> _login() async{
    if(_isLoading) return; // Prevenir múltiples inicios de sesión simultáneos
    setState(() {
      _isLoading = true;
    });

    // Validar el formulario
    if (!_loginFormKey.currentState!.validate()) {
      setState(() {
        _isLoading = false;
      });
      return;
    }
    try{
      await FirebaseAuth.instance.signInWithEmailAndPassword(email: emailController.text.trim(), password: passwordController.text.trim());
      if(mounted){  
        setState(() {
          _isLoading = false;
        });
      }
      // Cerrar el diálogo de carga
    } on FirebaseAuthException catch(e){
      if(mounted){  
        setState(() {
          _isLoading = false;
        });
      }
      switch(e.code){
        case 'user-not-found':
          _showError("No se encontró un usuario con ese correo.");
          break;
        case 'invalid-credential':
          _showError("El correo electrónico o la contraseña no son válidos.");
          break;
        default:
          _showError("Error de autenticación: ${e.code} ");
      }
    }catch(e){
      if(mounted){  
        setState(() {
          _isLoading = false;
        });
      }
      _showError("Ocurrió un error, intenta de nuevo");
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  @override
  Widget build(BuildContext context) {
    const double kButtonMaxWidth = 420; // ancho uniforme
    return Stack(
      children: [Scaffold(
        backgroundColor: Colors.white, // Fondo blanco
        body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints){
                return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: Padding(
                          padding: const EdgeInsets.fromLTRB(20.0, 0.0, 20.0, 0.0), // Espaciado del contenido en el eje horizontal
                            child: Center(
                                  child: Form(
                                    key: _loginFormKey,
                                    child: Column(
                                      //mainAxisAlignment: MainAxisAlignment.center, // Centra el contenido verticalmente
                                      crossAxisAlignment: CrossAxisAlignment.center, // Centra horizontalmente
                                      children: [
                                        // Logo en la parte superior
                                        Image.asset(
                                          'assets/images/graduate.png', // Asegúrate de que tu imagen esté en esta ruta
                                          width: 150, // Ajusta el tamaño de la imagen
                                        ), // Espacio entre el logo y el formulario de inicio de sesión
      
                                        SizedBox(height: 10), // Espacio entre el título y los campos de entrada
      
                                        // Campo de texto para el email
                                        StyledTextFormField(
                                          isRequired: true,
                                          controller: emailController,
                                          title: "Correo electrónico",
                                          keyboardType: TextInputType.emailAddress,
                                          validator: (value) {
                                            if (value == null || value.isEmpty) {
                                              return 'Por favor, ingresa tu correo electrónico';
                                            }
                                            // Expresión regular simple para validar el formato del correo electrónico
                                            final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
                                            if (!emailRegex.hasMatch(value)) {
                                              return 'Ingresa un correo electrónico válido';
                                            }
                                            return null; // Retorna null si la validación es exitosa
                                          },
                                        ),
      
                                        const SizedBox(height: 5), // Espacio entre los campos de texto
      
                                        // Campo de texto para la contraseña
                                        StyledTextFormField(
                                          isRequired: true,
                                          controller: passwordController,
                                          title: "Contraseña",
                                          obscureText: true,
                                          isPasswordField: true,
                                          validator: (value) {
                                            if (value == null || value.isEmpty) {
                                              return 'Por favor, ingresa tu contraseña';
                                            }
                                            return null;
                                          },
                                        ),
      
                                        SizedBox(height: 10), // Espacio entre los campos de texto y el botón
      
                                        // Botón de inicio de sesión
                                        ConstrainedBox(
                                          constraints: const BoxConstraints(maxWidth: kButtonMaxWidth),
                                          child: SizedBox(
                                            width: double.infinity,
                                            child: LargeButton(
                                              title: "Iniciar Sesión",
                                              primaryColor: true,
                                              onTap: _login,
                                            ),
                                          ),
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
      
                                        // Botón de Registro de Alumno
                                        ConstrainedBox(
                                          constraints: const BoxConstraints(maxWidth: kButtonMaxWidth),
                                          child: SizedBox(
                                            width: double.infinity,
                                            child: LargeButton(
                                              title: "Registrarme como Alumno",
                                              primaryColor: true,
                                              onTap: () {
                                                // Redirigir a la página de registro de alumno
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(builder: (context) => const LectorQRPage()),
                                                );
                                              },
                                            ),
                                          ),
                                        ),
      
                                        SizedBox(height: 10),
      
                                        // Botón de inicio de sesión
                                        ConstrainedBox(
                                          constraints: const BoxConstraints(maxWidth: kButtonMaxWidth),
                                          child: SizedBox(
                                            width: double.infinity,
                                            child: LargeButton(
                                              title: "Registrarme como Reclutador",
                                              primaryColor: true,
                                              onTap: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(builder: (context) => RegistrarReclutadorPage()),
                                                );
                                              },
                                            ),
                                          ),
                                        ),
                                      ],
                                  ),
                              ),
                            ),
                        ),
                    ),
                );
              }
            ),
        ),
      ),
      if(_isLoading)
        Container(
          color: Colors.black54, // Fondo semi-transparente
          child: const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
          ),
        ),
      ]
    );
  }
}
