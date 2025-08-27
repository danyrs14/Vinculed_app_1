import 'package:flutter/material.dart';

class EscomFooter extends StatelessWidget {
  const EscomFooter({super.key, required this.isMobile});

  final bool isMobile;

  static const double height = 300; // aumentamos para la imagen

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      color: const Color(0xFF2B2F33),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: isMobile ? _mobileScrollable() : _desktopCompact(),
    );
  }

  // ====== MÓVIL: contenido scrolleable para evitar overflow ======
  Widget _mobileScrollable() {
    return ScrollConfiguration(
      behavior: const _NoGlowBehavior(),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Imagen arriba de todo
            Image.asset(
              'assets/images/escom.png', // cambia la ruta si es otra
              height: 50,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 12),
            const Text("ESCOM", style: TextStyle(color: Colors.white, fontSize: 20)),
            const SizedBox(height: 8),
            const Text(
              "Copyright © 2025\nDerechos Reservados",
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            _footerColumn(
              "Equipo TT",
              ["Acerca de", "Blog", "Contactanos", "Pricing", "Testimonials"],
            ),
            const SizedBox(height: 16),
            _footerColumn(
              "Soporte",
              ["Emergencias", "Ayuda", "Ubicacion", "Privacy policy", "Status"],
            ),
            const SizedBox(height: 16),
            _footerSubscribe(),
          ],
        ),
      ),
    );
  }

  Widget _desktopCompact() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Imagen arriba de todo
            Image.asset(
              'assets/images/escudoESCOM.png', // cambia la ruta si es otra
              height: 150,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 12),
            Center(
              child: const Text(
                "Copyright © 2025\nDerechos Reservados",
                style: TextStyle(color: Colors.white70),
              ),
            ),
          ],
        ),
        const Spacer(),
        Flexible(
          child: _footerColumn(
            "Equipo TT",
            ["Acerca de", "Blog", "Contactanos", "Pricing", "Testimonials"],
          ),
        ),
        const SizedBox(width: 48),
        Flexible(
          child: _footerColumn(
            "Soporte",
            ["Emergencias", "Ayuda", "Ubicacion", "Privacy policy", "Status"],
          ),
        ),
        const SizedBox(width: 48),
        const Flexible(child: _FooterSubscribeBox()),
      ],
    );
  }

  static Widget _footerColumn(String title, List<String> links) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(title, style: const TextStyle(color: Colors.white, fontSize: 16)),
        const SizedBox(height: 6),
        for (final link in links)
          TextButton(
            onPressed: () {},
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size(0, 28),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              alignment: Alignment.centerLeft,
            ),
            child: Text(link, style: const TextStyle(color: Colors.white70)),
          ),
      ],
    );
  }

  static Widget _footerSubscribe() => const _FooterSubscribeBox();
}

class _FooterSubscribeBox extends StatelessWidget {
  const _FooterSubscribeBox();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text("Conócenos", style: TextStyle(color: Colors.white, fontSize: 16)),
        const SizedBox(height: 8),
        SizedBox(
          width: 220,
          child: TextField(
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: "Correo Electrónico",
              hintStyle: const TextStyle(color: Colors.white70),
              filled: true,
              fillColor: Colors.grey[800],
              suffixIcon: const Icon(Icons.send, color: Colors.white70, size: 20),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _NoGlowBehavior extends ScrollBehavior {
  const _NoGlowBehavior();
  @override
  Widget buildOverscrollIndicator(BuildContext context, Widget child, ScrollableDetails details) {
    return child;
  }
}
