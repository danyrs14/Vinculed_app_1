import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:vinculed_app_1/src/core/controllers/theme_controller.dart';
import 'package:vinculed_app_1/src/ui/pages/reclutador/ajustes.dart';
import 'package:vinculed_app_1/src/ui/pages/reclutador/home.dart';
import 'package:vinculed_app_1/src/ui/pages/reclutador/mensajes.dart';
import 'package:vinculed_app_1/src/ui/pages/reclutador/mis_vacantes.dart';
import 'package:vinculed_app_1/src/ui/pages/reclutador/new_vacancy.dart';
import 'package:vinculed_app_1/src/ui/pages/reclutador/notificaciones.dart';
import 'package:vinculed_app_1/src/ui/pages/reclutador/perfil.dart';

class MenuPageRec extends StatefulWidget {
  const MenuPageRec({Key? key}) : super(key: key);

  @override
  State<MenuPageRec> createState() => _MenuPageRecState();
}

class _MenuPageRecState extends State<MenuPageRec> {
  final usuario = FirebaseAuth.instance.currentUser!;
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
      AjustesRec(),   // 3
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
            Image.asset('assets/images/graduate.png', width: 50, height: 50),

            Row(
              children: [
                IconButton(
                  icon: Icon(Icons.add, color: theme.primario()),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const CrearVacantePage()),
                    );
                  },
                ),
                IconButton(
                  icon: Icon(Icons.notifications_none, color: theme.primario()),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => NotificacionesRec()),
                    );
                  },
                ),
                IconButton(
                  icon: CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.blue[50],
                    backgroundImage: usuario.photoURL != null ? NetworkImage(usuario.photoURL!) : null,
                    child: usuario.photoURL == null ? const Icon(Icons.person, size: 18, color: Colors.blueGrey) : null,
                  ),
                  onPressed: () {
                    // Acción para perfil
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const PerfilRec()),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
        elevation: 0,
      ),

      body: PageView(
        controller: _pageController,
        physics: const PageScrollPhysics(), // swipe horizontal natural
        onPageChanged: (index) {
          // sincroniza la barra inferior cuando el usuario desliza
          setState(() => _paginaActual = index);
        },
        children: _paginas,
      ),

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
                color: _paginaActual == 0 ? theme.primario() : Colors.grey,
                width: 26, height: 26,
              ),
              label: 'Perfil',
            ),
            BottomNavigationBarItem(
              backgroundColor: theme.background(),
              icon: Icon(
                Icons.work_outline,
                color: _paginaActual == 1 ? theme.primario() : Colors.grey,
                size: 26,
              ),
              label: 'Mis Vacantes',
            ),
            BottomNavigationBarItem(
              backgroundColor: theme.background(),
              icon: Image.asset(
                'assets/icons/home.png',
                color: _paginaActual == 2 ? theme.primario() : Colors.grey,
                width: 26, height: 26,
              ),
              label: 'Inicio',
            ),
            BottomNavigationBarItem(
              backgroundColor: theme.background(),
              icon: Image.asset(
                'assets/icons/configuracion.png',
                color: _paginaActual == 3 ? theme.primario() : Colors.grey,
                width: 26, height: 26,
              ),
              label: 'Ajustes',
            ),
            BottomNavigationBarItem(
              backgroundColor: theme.background(),
              icon: Image.asset(
                'assets/icons/mail.png',
                color: _paginaActual == 4 ? theme.primario() : Colors.grey,
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
