import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:vinculed_app_1/src/ui/pages/modulo_candidato/menu.dart';
import 'package:vinculed_app_1/src/ui/widgets/text_inputs/text_input.dart';
import 'package:vinculed_app_1/src/ui/widgets/text_inputs/dropdown.dart';
import 'package:vinculed_app_1/src/ui/widgets/buttons/large_buttons.dart';
import 'package:vinculed_app_1/src/ui/pages/verificarEmail.dart';

class RegisterStudentPage extends StatefulWidget {
  const RegisterStudentPage({Key? key}) : super(key: key);

  @override
  State<RegisterStudentPage> createState() => _RegisterStudentPageState();
}

class _RegisterStudentPageState extends State<RegisterStudentPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _genderController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _loading = false;

  Future<void> _registerUser() async {
    final name = _nameController.text.trim();
    final gender = _genderController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (name.isEmpty || gender.isEmpty || email.isEmpty || password.isEmpty) {
      _showError("Todos los campos son obligatorios.");
      return;
    }

    setState(() => _loading = true);

    try {
      // 1. Registrar en Firebase
      final auth = FirebaseAuth.instance;
      final credential = await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final idToken = await credential.user!.getIdToken();

      // 2. Enviar al backend para guardarlo en MySQL
      final response = await http.post(
        Uri.parse('http://10.0.2.2:3000/api/usuarios/registrar'),
        headers: {
          'Authorization': 'Bearer $idToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'nombre': name,
          'email': email,
          'rol': 'alumno',
          'genero': gender,
          'uid_firebase': credential.user!.uid,
        }),
      );

      if ((response.statusCode == 201 || response.statusCode == 200) && (credential.user != null && !credential.user!.emailVerified) ) {
        //Enviar email de verificación
        await credential.user!.sendEmailVerification();
        
        //Pagina de verificación
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => verificarEmailPage()),
        );
      } else {
        _showError("Error en el backend: ${response.body}");
      }
    } on FirebaseAuthException catch (e) {
      _showError("Error: ${e.message}");
    } catch (e) {
      _showError("Error inesperado: $e");
    } finally {
      setState(() => _loading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Registro de Usuario"),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextInput(
                  controller: _nameController,
                  title: "Nombre completo",
                  required: true,
                ),
                SizedBox(height: 10),
                DropdownInput<String>(
                  title: "Género",
                  required: true,
                  value: "Masculino",
                  items: const [
                    DropdownMenuItem(value: "masculino", child: Text("Masculino")),
                    DropdownMenuItem(value: "femenino", child: Text("Femenino")),
                    DropdownMenuItem(value: "otro", child: Text("Otro")),
                  ],
                  onChanged: (valor) {
                    setState(() {
                      _genderController.text = valor ?? "Masculino";
                    });
                  },
                ),
                SizedBox(height: 10),
                TextInput(
                  controller: _emailController,
                  title: "Correo electrónico",
                  keyboardType: TextInputType.emailAddress,
                  required: true,
                ),
                SizedBox(height: 10),
                TextInput(
                  controller: _passwordController,
                  title: "Contraseña",
                  obscureText: true,
                  required: true ,
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
    );
  }
}
