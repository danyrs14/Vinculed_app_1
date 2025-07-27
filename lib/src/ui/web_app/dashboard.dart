import 'package:flutter/material.dart';

class Dashboard extends StatelessWidget {
  const Dashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 20,
        title: Row(
          children: [
            Image.asset(
              'assets/images/escom.png',
              height: 40,
            ),
            const SizedBox(width: 10),
          ],
        ),
        actions: [
          _navButton("Inicio"),
          _navButton("Postulaciones"),
          _navButton("Experiencias"),
          _navButton("Mensajes"),
          _navButton("Preferencias"),
          _navButton("FAQ"),
          TextButton(
            onPressed: () {},
            child: const Text(
              "Iniciar Sesion",
              style: TextStyle(color: Colors.blue),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
              ),
              child: const Text("Registrarse"),
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                // Texto y botón
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(40.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "¡Mejores\nOportunidades nos\nesperan!",
                          style: TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            padding:
                            const EdgeInsets.symmetric(horizontal: 25),
                          ),
                          child: const Text("Registrarse"),
                        ),
                      ],
                    ),
                  ),
                ),
                // Imagen ilustrativa
                Expanded(
                  child: Center(
                    child: Image.asset(
                      'assets/illustration.png',
                      height: 300,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Footer
          Container(
            color: const Color(0xFF2B2F33),
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      "ESCOM",
                      style: TextStyle(color: Colors.white, fontSize: 20),
                    ),
                    SizedBox(height: 10),
                    Text(
                      "Copyright © 2025\nDerechos Reservados",
                      style: TextStyle(color: Colors.white70),
                    )
                  ],
                ),
                const Spacer(),
                _footerColumn("Equipo TT", [
                  "Acerca de",
                  "Blog",
                  "Contactanos",
                  "Pricing",
                  "Testimonials"
                ]),
                const SizedBox(width: 60),
                _footerColumn("Soporte", [
                  "Emergencias",
                  "Ayuda",
                  "Ubicacion",
                  "Privacy policy",
                  "Status"
                ]),
                const SizedBox(width: 60),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Conocenos",
                        style: TextStyle(color: Colors.white, fontSize: 16)),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: 200,
                      child: TextField(
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: "Correo Electronico",
                          hintStyle:
                          const TextStyle(color: Colors.white70),
                          filled: true,
                          fillColor: Colors.grey[800],
                          suffixIcon: const Icon(Icons.send,
                              color: Colors.white70),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none),
                        ),
                      ),
                    )
                  ],
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  // Botones del navbar
  Widget _navButton(String text) {
    return TextButton(
      onPressed: () {},
      child: Text(
        text,
        style: const TextStyle(color: Colors.black87),
      ),
    );
  }

  // Columnas del footer
  static Widget _footerColumn(String title, List<String> links) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(color: Colors.white, fontSize: 16)),
        const SizedBox(height: 5),
        for (var link in links)
          TextButton(
            onPressed: () {},
            style: TextButton.styleFrom(padding: EdgeInsets.zero),
            child: Text(link,
                style: const TextStyle(color: Colors.white70)),
          ),
      ],
    );
  }
}
