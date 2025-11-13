import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:vinculed_app_1/src/core/controllers/theme_controller.dart';
import 'dart:convert';

//import 'package:vinculed_app_1/src/ui/widgets/text_inputs/text_input.dart';
import 'package:vinculed_app_1/src/ui/widgets/text_inputs/text_form_field.dart';
import 'package:vinculed_app_1/src/ui/widgets/text_inputs/dropdown.dart';
import 'package:vinculed_app_1/src/ui/widgets/buttons/large_buttons.dart';
import 'package:vinculed_app_1/src/ui/pages/verificarEmail.dart';

class RegisterStudentPage extends StatefulWidget {
  final String nombre;
  const RegisterStudentPage({Key? key, required this.nombre}) : super(key: key);

  @override
  State<RegisterStudentPage> createState() => _RegisterStudentPageState();
}

class _RegisterStudentPageState extends State<RegisterStudentPage> {
  final _registroFormKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _genderController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _loading = false;

  //Para la validación de la contraseña
  bool _hasMinLength = false;
  bool _hasLetter = false;
  bool _hasNumber = false;
  bool _hasSpecialChar = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.nombre;
  }

  Future<void> _registerUser() async {
    final name = _nameController.text.trim();
    final gender = _genderController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    // Validar el formulario
    if (!_registroFormKey.currentState!.validate()) {
      return;
    }

    setState(() => _loading = true);

    try {
      //Registrar en Firebase
      final auth = FirebaseAuth.instance;
      final credential = await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user!;
      final idToken = await user.getIdToken();
      await user.updateDisplayName(name); //Actualizar el nombre del usuario en firebase
      //Enviar al backend para guardarlo en MySQL
      final response = await http.post(
        Uri.parse('https://oda-talent-back-81413836179.us-central1.run.app/api/usuarios/registrar'),
        headers: {
          'Authorization': 'Bearer $idToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'nombre': name,
          'email': email,
          'rol': 'alumno',
          'genero': gender,
          'uid_firebase': user.uid,
        }),
      );

      if ((response.statusCode == 201 || response.statusCode == 200) && (!user.emailVerified) ) {
        //Enviar email de verificación
        await credential.user!.sendEmailVerification();
        //Pagina de verificación
        if (mounted){
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      } else {
        throw Exception("Error del servidor: ${response.body}"); 
      }
    } on FirebaseAuthException catch (e) {
      print(e.code);
      switch (e.code) {
        case 'email-already-in-use':
          _showError("El correo ya está en uso.");
          break;
        case 'invalid-email':
          _showError("El correo no es válido.");
          break;
        case 'weak-password':
          _showError("La contraseña es muy débil.");
          break;
        default:
          _showError("Error de autenticación: ${e.message}");
      }
    } on Exception catch(e) { //
      await FirebaseAuth.instance.currentUser?.delete(); //Eliminar el usuario de Firebase si hubo un error
      _showError("Error inesperado: ${e.toString()}");
    } finally {
      setState(() => _loading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  void _validatePassword(String value) {
    setState(() {
      _hasMinLength = value.length >= 8;
      _hasLetter = RegExp(r'[A-Za-z]').hasMatch(value);
      _hasNumber = RegExp(r'\d').hasMatch(value);
      _hasSpecialChar = RegExp(r'[+@$!%*?&.,;:_\-]').hasMatch(value);
    });
  }

  Widget _buildValidationRow(String text, bool isValid) {
    return Row(
      children: [
        Icon(
          isValid ? Icons.check_circle : Icons.radio_button_unchecked,
          color: isValid ? Colors.blue : Colors.grey,
          size: 20,
        ),
        SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            color: isValid ? Colors.blue : Colors.grey,
            fontWeight: isValid ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;
    return Scaffold(
      backgroundColor: Colors.white, 
      appBar: AppBar(
        backgroundColor: theme.background(),
        automaticallyImplyLeading: false,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Image.asset('assets/images/escom.png', width: 50, height: 50),
          ],
        ),
        elevation: 0,
      ),
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
                                  key: _registroFormKey,
                                  child: Column(

                                    children: [
                                      Text("Registrar Alumno",
                                        style: TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: theme.fuente(),
                                        ),),
                                      SizedBox(height: 20),
                                      StyledTextFormField(
                                        controller: _nameController,
                                        title: "Nombre completo",
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'El nombre es obligatorio.';
                                          }
                                          return null;
                                        },
                                      ),
                                      SizedBox(height: 10),
                                  
                                      DropdownInput<String>(
                                        title: "Género",
                                        required: true,
                                        items: const [
                                          DropdownMenuItem(value: "masculino", child: Text("Masculino")),
                                          DropdownMenuItem(value: "femenino", child: Text("Femenino")),
                                          DropdownMenuItem(value: "otro", child: Text("Otro")),
                                        ],
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'El género es obligatorio.';
                                          }
                                          return null;
                                        },
                                        onChanged: (valor) {
                                          setState(() {
                                            _genderController.text = valor ?? "masculino";
                                          });
                                        },
                                      ),
                                      SizedBox(height: 10),
                                      StyledTextFormField(
                                        controller: _emailController,
                                        title: "Correo institucional",
                                        keyboardType: TextInputType.emailAddress,
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'El correo es obligatorio.';
                                          }
                                          final emailRegex = RegExp(r'^[^@]+@alumno.ipn.mx$');
                                          if (!emailRegex.hasMatch(value)) {
                                            return 'Ingrese un correo válido.';
                                          }
                                          return null;
                                        },
                                      ),
                                      SizedBox(height: 10),
                                      StyledTextFormField(
                                        controller: _passwordController,
                                        title: "Contraseña",
                                        obscureText: true,
                                        isPasswordField: true, 
                                        onChanged: _validatePassword,
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'La contraseña es obligatoria.';
                                          }
                                          if (!_hasMinLength || !_hasLetter || !_hasNumber || !_hasSpecialChar) {
                                            return 'La contraseña no cumple con los requisitos.';
                                          }
                                          return null;
                                        },
                                      ),
                                      SizedBox(height: 5),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text("Requisitos de la contraseña:", style: TextStyle(fontWeight: FontWeight.bold)),
                                          SizedBox(height: 8),
                                          _buildValidationRow("Al menos 8 caracteres", _hasMinLength),
                                          SizedBox(height: 4),
                                          _buildValidationRow("Al menos una letra", _hasLetter),
                                          SizedBox(height: 4),
                                          _buildValidationRow("Al menos un número", _hasNumber),
                                          SizedBox(height: 4),
                                          _buildValidationRow("Al menos un carácter especial", _hasSpecialChar),
                                        ],
                                      ),
                                      SizedBox(height: 20),
                                      LargeButton(
                                        title: _loading ? "Registrando..." : "Registrarme",
                                        primaryColor: true,
                                        onTap: _loading ? null : _registerUser,
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
      );
  }
}
