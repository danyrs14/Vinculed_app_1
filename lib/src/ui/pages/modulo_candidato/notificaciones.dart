import 'package:flutter/material.dart';
import 'package:vinculed_app_1/src/core/controllers/theme_controller.dart';
import 'package:vinculed_app_1/src/ui/pages/modulo_candidato/menu.dart';
import 'package:vinculed_app_1/src/ui/widgets/buttons/simple_buttons.dart';
import 'package:vinculed_app_1/src/ui/widgets/textos/textos.dart';

class Notificaciones extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;
    return Scaffold(
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Center(
              child: Texto(
                text: 'Notificaciones',
                fontSize: 24,
              ),
            ),
            SizedBox(height: 10),
                        Spacer(),

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
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationItem(
      String userName, String message, String timeAgo) {
    final theme = ThemeController.instance;
    return Card(
      color: theme.background(),
      margin: EdgeInsets.symmetric(vertical: 10),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue,
          child: Text(
            userName[1], // Muestra la primera letra del nombre de usuario
            style: TextStyle(color: Colors.white),
          ),
        ),
        title: Text(userName),
        subtitle: Text(message),
        trailing: Text(timeAgo),
      ),
    );
  }
}
