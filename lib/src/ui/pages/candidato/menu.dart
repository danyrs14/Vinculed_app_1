import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:vinculed_app_1/src/core/controllers/theme_controller.dart';
import 'package:vinculed_app_1/src/ui/pages/candidato/busqueda.dart';
import 'package:vinculed_app_1/src/ui/pages/candidato/experiencias.dart';
import 'package:vinculed_app_1/src/ui/pages/candidato/home.dart';
import 'package:vinculed_app_1/src/ui/pages/candidato/mensajes.dart';
import 'package:vinculed_app_1/src/ui/pages/candidato/notificaciones.dart';
import 'package:vinculed_app_1/src/ui/pages/candidato/perfil.dart';
import 'package:vinculed_app_1/src/ui/pages/candidato/postulaciones.dart';

class MenuPage extends StatefulWidget {
  const MenuPage({Key? key}) : super(key: key);

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  int _paginaActual = 2; // Inicia en 'Inicio'
  late final List<Widget> _paginas;
  late final PageController _pageController;
  final usuario = FirebaseAuth.instance.currentUser!;

  @override
  void initState() {
    super.initState();
    _paginas =  [
      const Perfil(),         // 0
      const Postulaciones(),  // 1
      Home(),           // 2
      const Experiencias(),   // 3
      Mensajes(),       // 4
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
                  icon: Icon(Icons.search, color: theme.primario()),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => Busqueda()),
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
                      MaterialPageRoute(builder: (context) => const Perfil()),
                    );
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
                color: _paginaActual == 0 ? theme.primario() : Colors.grey,
                width: 26, height: 26,
              ),
              label: 'Perfil',
            ),
            BottomNavigationBarItem(
              backgroundColor: theme.background(),
              icon: Image.asset(
                'assets/icons/verif.png',
                color: _paginaActual == 1 ? theme.primario() : Colors.grey,
                width: 26, height: 26,
              ),
              label: 'Postulaciones',
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
                'assets/icons/cora.png',
                color: _paginaActual == 3 ? theme.primario() : Colors.grey,
                width: 26, height: 26,
              ),
              label: 'Experiencias',
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
