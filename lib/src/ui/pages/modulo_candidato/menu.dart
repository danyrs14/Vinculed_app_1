import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:vinculed_app_1/src/core/controllers/theme_controller.dart';
import 'package:vinculed_app_1/src/ui/pages/modulo_candidato/busqueda.dart';
import 'package:vinculed_app_1/src/ui/pages/modulo_candidato/experiencias.dart';
import 'package:vinculed_app_1/src/ui/pages/modulo_candidato/home.dart';
import 'package:vinculed_app_1/src/ui/pages/modulo_candidato/mensajes.dart';
import 'package:vinculed_app_1/src/ui/pages/modulo_candidato/notificaciones.dart';
import 'package:vinculed_app_1/src/ui/pages/modulo_candidato/perfil.dart';
import 'package:vinculed_app_1/src/ui/pages/modulo_candidato/postulaciones.dart';

class MenuPage extends StatefulWidget {
  const MenuPage({Key? key}) : super(key: key);

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  int _paginaActual = 2; // Iniciar en la página de 'Inicio'
  late List<Widget> _paginas;

  @override
  void initState() {
    super.initState();
    _paginas = [
      Perfil(), // Página de perfil
      Postulaciones(), // Página de reporte
      Home(), // Página de inicio
      Experiencias(), // Página de gestión
      Mensajes(), // Página de configuración
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.background(), // Fondo personalizado para el AppBar
        automaticallyImplyLeading: false, // Elimina el botón de retroceso predeterminado
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween, // Distribuye los elementos en el AppBar
          children: [
            // Logo a la izquierda
            Image.asset(
              'assets/images/escom.png', // Asegúrate de tener la ruta correcta de la imagen
              width: 50, // Ajusta el tamaño del logo
              height: 50,
            ),

            // Íconos a la derecha (Búsqueda, Notificaciones y Perfil)
            Row(
              children: [
                IconButton(
                  icon: Icon(Icons.search, color: theme.primario()), // Ícono de búsqueda
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => Busqueda(),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: Icon(Icons.notifications_none, color: theme.primario()), // Ícono de notificaciones
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => Notificaciones(),
                      ),
                    );
                  },
                ),

                IconButton(
                  icon: CircleAvatar(
                    backgroundImage: AssetImage('assets/images/amlo.jpg'), // Foto de perfil
                    radius: 18, // Tamaño del avatar
                  ),
                  onPressed: () {
                    // Acción para perfil
                  },
                ),
              ],
            ),
          ],
        ),
        elevation: 0, // Sin sombra en el AppBar
      ),


      body: _paginas[_paginaActual], // Mostramos la página actual
      bottomNavigationBar: Container(
        color: theme.background(),
        child: BottomNavigationBar(
          onTap: (index) {
            setState(() {
              _paginaActual = index;
            });
          },
          currentIndex: _paginaActual,
          selectedItemColor: theme.fuente(),
          unselectedItemColor: Colors.grey,
          selectedLabelStyle: TextStyle(
            fontFamily: 'Poppins',
            color: theme.fuente(),
          ),
          unselectedLabelStyle: TextStyle(
            color: Colors.grey,
          ),
          showUnselectedLabels: true,
          iconSize: 26,
          items: [
            BottomNavigationBarItem(
              backgroundColor: theme.background(),
              icon: _paginaActual == 0
                  ? Image.asset(
                'assets/icons/perfil.png',
                color: theme.fuente(),
                width: 26,
                height: 26,
              )
                  : Image.asset(
                'assets/icons/perfil.png',
                color: Colors.grey,
                width: 26,
                height: 26,
              ),
              label: 'Perfil',
            ),
            BottomNavigationBarItem(
              backgroundColor: theme.background(),
              icon: _paginaActual == 1
                  ? Image.asset(
                'assets/icons/verif.png',
                color: theme.fuente(),
                width: 26,
                height: 26,
              )
                  : Image.asset(
                'assets/icons/verif.png',
                color: Colors.grey,
                width: 26,
                height: 26,
              ),
              label: 'Postulaciones',
            ),
            BottomNavigationBarItem(
              backgroundColor: theme.background(),
              icon: _paginaActual == 2
                  ? Image.asset(
                'assets/icons/home.png',
                color: theme.fuente(),
                width: 26,
                height: 26,
              )
                  : Image.asset(
                'assets/icons/home.png',
                color: Colors.grey,
                width: 26,
                height: 26,
              ),
              label: 'Inicio',
            ),
            BottomNavigationBarItem(
              backgroundColor: theme.background(),
              icon: _paginaActual == 3
                  ? Image.asset(
                'assets/icons/cora.png',
                color: theme.fuente(),
                width: 26,
                height: 26,
              )
                  : Image.asset(
                'assets/icons/cora.png',
                color: Colors.grey,
                width: 26,
                height: 26,
              ),
              label: 'Experiencias',
            ),
            BottomNavigationBarItem(
              backgroundColor: theme.background(),
              icon: _paginaActual == 4
                  ? Image.asset(
                'assets/icons/mail.png',
                color: theme.fuente(),
                width: 26,
                height: 26,
              )
                  : Image.asset(
                'assets/icons/mail.png',
                color: Colors.grey,
                width: 26,
                height: 26,
              ),
              label: 'Mensajes',
            ),
          ],
        ),
      ),
    );
  }
}
