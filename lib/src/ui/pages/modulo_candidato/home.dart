import 'package:flutter/material.dart';
import 'package:vinculed_app_1/src/core/controllers/theme_controller.dart';
import 'package:vinculed_app_1/src/ui/widgets/buttons/simple_buttons.dart';
import 'package:vinculed_app_1/src/ui/widgets/textos/textos.dart';

class Home extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;
    return Scaffold(
      backgroundColor: theme.background(),
      // Eliminando el appBar y el BottomNavigationBar
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [

              SizedBox(height: 20),
              // Título de la pantalla
              Row(
                mainAxisAlignment: MainAxisAlignment.start, // Centra la fila horizontalmente
                children: [
                  SizedBox(width: 10),
                  // Imagen de perfil
                  CircleAvatar(
                    backgroundImage: AssetImage('assets/images/amlo.jpg'), // Cambia la ruta de la imagen
                    radius: 30, // Radio del círculo
                  ),
                  SizedBox(width: 10), // Espacio entre la imagen y el texto

                  // Texto del nombre de usuario
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start, // Alineación del texto
                    children: [
                      Texto(
                        text: '@Usuario_Registrado',
                        fontSize: 16,
                      ),
                      Texto(
                        text:
                        'Bienvenido de Nuevo', // Mensaje
                        fontSize: 18,
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 5), // Espacio entre el texto y los siguientes elementos
              //Contenido a futuro
            ],
          ),
        ),
      ),
    );
  }
}
