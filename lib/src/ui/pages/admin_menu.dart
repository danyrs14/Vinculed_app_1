import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:vinculed_app_1/src/core/controllers/theme_controller.dart';
import 'package:vinculed_app_1/src/ui/pages/admin_ajustes.dart';
import 'package:vinculed_app_1/src/ui/pages/admin_gestion_empresas.dart';
import 'package:vinculed_app_1/src/ui/pages/admin_gestion_reclutador.dart';
import 'package:vinculed_app_1/src/ui/pages/admin_gestion_reportes.dart';


class MenuPageAdmin extends StatefulWidget {
  const MenuPageAdmin({Key? key}) : super(key: key);

  @override
  State<MenuPageAdmin> createState() => _MenuPageAdminState();
}

class _MenuPageAdminState extends State<MenuPageAdmin> {
  final usuario = FirebaseAuth.instance.currentUser!;
  int _paginaActual = 1; // Inicia en 'Inicio'
  late final List<Widget> _paginas;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _paginas = const [
      //PerfilRec(),         // 0
      ReportesAdminMovilPage(),  // 1
      InicioAdminPageMovil(),           // 2
      AdminGestionEmpresasPageMovil(),   // 3
      AjustesAdmin(),       // 4
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
              icon: Icon(
                Icons.report_outlined,
                color: _paginaActual == 0 ? theme.fuente() : Colors.grey,
                size: 26,
              ),
              label: 'Reportes',
            ),
            BottomNavigationBarItem(
              backgroundColor: theme.background(),
              icon: Icon(
                Icons.person_search_outlined,
                color: _paginaActual == 1 ? theme.fuente() : Colors.grey,
                size: 26,
              ),
              label: 'Reclutadores',
            ),
            BottomNavigationBarItem(
              backgroundColor: theme.background(),
              icon: Icon(
                Icons.work_outlined,
                color: _paginaActual == 2 ? theme.fuente() : Colors.grey,
                size: 26,
              ),
              label: 'Empresas',
            ),
            BottomNavigationBarItem(
              backgroundColor: theme.background(),
              icon: Icon(
                Icons.settings_outlined,
                color: _paginaActual == 3 ? theme.fuente() : Colors.grey,
                size: 26,
              ),
              label: 'Ajustes',
            ),
          ],
        ),
      ),
    );
  }
}
