import 'package:flutter/material.dart';
import 'package:vinculed_app_1/src/core/controllers/theme_controller.dart';
import 'package:vinculed_app_1/src/ui/pages/candidato/busqueda.dart';
import 'package:vinculed_app_1/src/ui/pages/candidato/experiencias.dart';
import 'package:vinculed_app_1/src/ui/pages/candidato/home.dart';
import 'package:vinculed_app_1/src/ui/pages/candidato/mensajes.dart';
import 'package:vinculed_app_1/src/ui/pages/candidato/notificaciones.dart';
import 'package:vinculed_app_1/src/ui/pages/candidato/perfil.dart';
import 'package:vinculed_app_1/src/ui/pages/candidato/postulaciones.dart';
import 'package:vinculed_app_1/src/ui/pages/reclutador/home.dart';
import 'package:vinculed_app_1/src/ui/pages/reclutador/mensajes.dart';
import 'package:vinculed_app_1/src/ui/pages/reclutador/mis_vacantes.dart';
import 'package:vinculed_app_1/src/ui/pages/reclutador/new_vacancy.dart';
import 'package:vinculed_app_1/src/ui/pages/reclutador/perfil.dart';

class MenuPageRec extends StatefulWidget {
  const MenuPageRec({Key? key}) : super(key: key);

  @override
  State<MenuPageRec> createState() => _MenuPageRecState();
}

class _MenuPageRecState extends State<MenuPageRec> {
  int _paginaActual = 2; // Inicia en 'Inicio'
  late final List<Widget> _paginas;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _paginas = const [
      PerfilRec(),         // 0
      VacantesRec(),  // 1
      HomeRec(),           // 2
      Experiencias(),   // 3
      MensajesRec(),       // 4
    ];
    _pageController = PageController(initialPage: _paginaActual);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTapNav(int index) {
    setState(() => _paginaActual = index);
    // sincroniza el swipe con la barra inferior
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.background(),
        automaticallyImplyLeading: false,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Image.asset('assets/images/escom.png', width: 50, height: 50),

            Row(
              children: [
                IconButton(
                  icon: Icon(Icons.add, color: theme.primario()),
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => CrearVacantePage()),
                    );
                  },
                ),
                IconButton(
                  icon: Icon(Icons.notifications_none, color: theme.primario()),
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => Notificaciones()),
                    );
                  },
                ),
                IconButton(
                  icon: const CircleAvatar(
                    backgroundImage: AssetImage('assets/images/amlo.jpg'),
                    radius: 18,
                  ),
                  onPressed: () {
                    // Acción para perfil
                  },
                ),
              ],
            ),
          ],
        ),
        elevation: 0,
      ),

      // ⬇️ Cuerpo convertido a PageView para permitir DESLIZAR entre pantallas
      body: PageView(
        controller: _pageController,
        physics: const PageScrollPhysics(), // swipe horizontal natural
        onPageChanged: (index) {
          // sincroniza la barra inferior cuando el usuario desliza
          setState(() => _paginaActual = index);
        },
        children: _paginas,
      ),

      // ⬇️ Tu BottomNavigationBar se mantiene igual, solo conectamos al PageView
      bottomNavigationBar: Container(
        color: theme.background(),
        child: BottomNavigationBar(
          onTap: _onTapNav,
          currentIndex: _paginaActual,
          selectedItemColor: theme.fuente(),
          unselectedItemColor: Colors.grey,
          selectedLabelStyle: TextStyle(
            fontFamily: 'Poppins',
            color: theme.fuente(),
          ),
          unselectedLabelStyle: const TextStyle(color: Colors.grey),
          showUnselectedLabels: true,
          iconSize: 26,
          items: [
            BottomNavigationBarItem(
              backgroundColor: theme.background(),
              icon: Image.asset(
                'assets/icons/perfil.png',
                color: _paginaActual == 0 ? theme.fuente() : Colors.grey,
                width: 26, height: 26,
              ),
              label: 'Perfil',
            ),
            BottomNavigationBarItem(
              backgroundColor: theme.background(),
              icon: Image.asset(
                'assets/icons/verif.png',
                color: _paginaActual == 1 ? theme.fuente() : Colors.grey,
                width: 26, height: 26,
              ),
              label: 'Mis Vacantes',
            ),
            BottomNavigationBarItem(
              backgroundColor: theme.background(),
              icon: Image.asset(
                'assets/icons/home.png',
                color: _paginaActual == 2 ? theme.fuente() : Colors.grey,
                width: 26, height: 26,
              ),
              label: 'Inicio',
            ),
            BottomNavigationBarItem(
              backgroundColor: theme.background(),
              icon: Image.asset(
                'assets/icons/configuracion.png',
                color: _paginaActual == 3 ? theme.fuente() : Colors.grey,
                width: 26, height: 26,
              ),
              label: 'Ajustes',
            ),
            BottomNavigationBarItem(
              backgroundColor: theme.background(),
              icon: Image.asset(
                'assets/icons/mail.png',
                color: _paginaActual == 4 ? theme.fuente() : Colors.grey,
                width: 26, height: 26,
              ),
              label: 'Mensajes',
            ),
          ],
        ),
      ),
    );
  }
}
