import 'package:flutter/material.dart';
import 'package:vinculed_app_1/src/core/controllers/theme_controller.dart';
import 'package:vinculed_app_1/src/ui/pages/candidato/menu.dart';
import 'package:vinculed_app_1/src/ui/widgets/buttons/simple_buttons.dart';
import 'package:vinculed_app_1/src/ui/widgets/textos/textos.dart';

class Notificaciones extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;
    return Scaffold(
      backgroundColor: theme.background(),
      appBar: AppBar(
        backgroundColor: theme.background(),
        automaticallyImplyLeading: false,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Image.asset(
              'assets/images/escom.png',
              width: 50,
              height: 50,
            ),

            Row(
              children: [
                IconButton(
                  icon: Icon(Icons.search, color: theme.primario()),
                  onPressed: () {
                  },
                ),
                IconButton(
                  icon: Icon(Icons.notifications_none, color: theme.primario()),
                  onPressed: () {},
                ),
                IconButton(
                  icon: CircleAvatar(
                    backgroundColor: Colors.blue[50],
                    backgroundImage: AssetImage('assets/images/amlo.jpg'),
                    radius: 18,
                  ),
                  onPressed: () {
                  },
                ),
              ],
            ),
          ],
        ),
        elevation: 0,
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
}
