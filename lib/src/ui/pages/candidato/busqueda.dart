import 'package:flutter/material.dart';
import 'package:vinculed_app_1/src/core/controllers/theme_controller.dart';
import 'package:vinculed_app_1/src/ui/pages/candidato/menu.dart';
import 'package:vinculed_app_1/src/ui/widgets/buttons/large_buttons.dart';
import 'package:vinculed_app_1/src/ui/widgets/buttons/simple_buttons.dart';
import 'package:vinculed_app_1/src/ui/widgets/text_inputs/text_input.dart';
import 'package:vinculed_app_1/src/ui/widgets/textos/textos.dart';

class Busqueda extends StatefulWidget {
  @override
  _BusquedaState createState() => _BusquedaState();
}

class _BusquedaState extends State<Busqueda> {
  bool _isSearching = false;
  TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context); // Regresar a la pantalla anterior
        return false;
      },
      child: Scaffold(
        backgroundColor: theme.background(),
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
                      setState(() {
                        _isSearching = true; // Activa la búsqueda
                      });
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.notifications_none, color: theme.primario()), // Ícono de notificaciones
                    onPressed: () {},
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
        body: Column(

          children: [
            Texto(
              text: 'Buscar Vacantes',
              fontSize: 24,
            ),
            // Campo de texto para búsqueda
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextInput(
                controller: _searchController,
                title: "Buscar",
                onChanged: (text) {
                  setState(() {
                    // Aquí puedes realizar un filtro para los resultados mientras escribes
                  });
                },
              ),
            ),

            SimpleButton(
              title: "Regresar",
              onTap: (){
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MenuPage(),
                  ),
                );
              },
            ),
            // Mostrar resultados o pantalla de búsqueda

          ],
        ),
      ),
    );
  }




    @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
