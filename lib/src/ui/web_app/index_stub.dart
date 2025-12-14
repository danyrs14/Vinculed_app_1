import 'package:flutter/material.dart';

// Stub para plataformas no web para evitar importar bibliotecas exclusivas de la web.
class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Esto nunca debería usarse en móviles, pero existe para satisfacer las importaciones.
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Text('La AdminApp exclusiva para la web no está disponible en esta plataforma.'),
        ),
      ),
    );
  }
}
