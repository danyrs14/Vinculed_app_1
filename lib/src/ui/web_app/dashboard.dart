import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:vinculed_app_1/src/core/controllers/theme_controller.dart';
import 'package:vinculed_app_1/src/ui/widgets/buttons/mini_buttons.dart';
import 'package:vinculed_app_1/src/ui/widgets/buttons/simple_buttons.dart';

class Dashboard extends StatelessWidget {
  const Dashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 700;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.background(),
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
        actions: isMobile
            ? [
          PopupMenuButton<String>(
            icon: const Icon(Icons.menu),
            onSelected: (value) {},
            itemBuilder: (context) => [
              const PopupMenuItem(value: "Inicio", child: Text("Inicio")),
              const PopupMenuItem(value: "Postulaciones", child: Text("Postulaciones")),
              const PopupMenuItem(value: "Experiencias", child: Text("Experiencias")),
              const PopupMenuItem(value: "Mensajes", child: Text("Mensajes")),
              const PopupMenuItem(value: "Preferencias", child: Text("Preferencias")),
              const PopupMenuItem(value: "FAQ", child: Text("FAQ")),
            ],
          )
        ]
            : [
          _navButton("Inicio"),
          _navButton("Postulaciones"),
          _navButton("Experiencias"),
          _navButton("Mensajes"),
          _navButton("Preferencias"),
          _navButton("FAQ"),
          TextButton(
            onPressed: () {
              context.go('/login');
            },
            child: Text(
              "Iniciar Sesión",
              style: TextStyle(color: theme.secundario(), fontWeight: FontWeight.bold),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: MiniButton(
              onTap: () {},
              title: "Registrarse",
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
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 800;
                return isNarrow
                    ? SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "¡Mejores\nOportunidades nos\nesperan!",
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 20),
                        SimpleButton(
                          onTap: () {},
                          title: "Postularse",
                        ),
                        const SizedBox(height: 20),
                        Center(
                          child: Image.asset(
                            'assets/illustration.png',
                            height: 200,
                          ),
                        )
                      ],
                    ),
                  ),
                )
                    : Row(
                  children: [
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
                            SimpleButton(
                              onTap: () {},
                              title: "Postularse",
                            ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: Image.asset(
                          'assets/illustration.png',
                          height: 300,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          _footer(isMobile),
        ],
      ),
    );
  }

  Widget _footer(bool isMobile) {
    return Container(
      color: const Color(0xFF2B2F33),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
      child: isMobile
          ? Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "ESCOM",
            style: TextStyle(color: Colors.white, fontSize: 20),
          ),
          const SizedBox(height: 10),
          const Text(
            "Copyright © 2025\nDerechos Reservados",
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 20),
          _footerColumn("Equipo TT", [
            "Acerca de",
            "Blog",
            "Contactanos",
            "Pricing",
            "Testimonials"
          ]),
          const SizedBox(height: 20),
          _footerColumn("Soporte", [
            "Emergencias",
            "Ayuda",
            "Ubicacion",
            "Privacy policy",
            "Status"
          ]),
          const SizedBox(height: 20),
          _footerSubscribe(),
        ],
      )
          : Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
          _footerSubscribe(),
        ],
      ),
    );
  }

  Widget _footerSubscribe() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Conócenos", style: TextStyle(color: Colors.white, fontSize: 16)),
        const SizedBox(height: 10),
        SizedBox(
          width: 200,
          child: TextField(
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: "Correo Electrónico",
              hintStyle: const TextStyle(color: Colors.white70),
              filled: true,
              fillColor: Colors.grey[800],
              suffixIcon: const Icon(Icons.send, color: Colors.white70),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        )
      ],
    );
  }

  Widget _navButton(String text) {
    return TextButton(
      onPressed: () {},
      child: Text(
        text,
        style: const TextStyle(color: Colors.black87),
      ),
    );
  }

  static Widget _footerColumn(String title, List<String> links) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: Colors.white, fontSize: 16)),
        const SizedBox(height: 5),
        for (var link in links)
          TextButton(
            onPressed: () {},
            style: TextButton.styleFrom(padding: EdgeInsets.zero),
            child: Text(link, style: const TextStyle(color: Colors.white70)),
          ),
      ],
    );
  }
}
