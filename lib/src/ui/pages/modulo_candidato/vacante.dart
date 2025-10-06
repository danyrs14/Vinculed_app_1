import 'package:flutter/material.dart';
import 'package:vinculed_app_1/src/core/controllers/theme_controller.dart';
import 'package:vinculed_app_1/src/ui/widgets/textos/textos.dart';

// Si ya tienes tu modelo JobData en otro archivo, impórtalo.
// Aquí dejo uno mínimo opcional para que compile si llamas directo.
// Elimínalo si ya importas tu propio modelo desde job_card.dart
class JobData {
  final String title;
  final String company;
  final String? salary;     // Ej: $7500 Mensuales
  final String? address;    // Dirección completa
  final List<String>? requirements;
  final String? description;

  const JobData({
    required this.title,
    required this.company,
    this.salary,
    this.address,
    this.requirements,
    this.description,
  });
}

class JobDetailPage extends StatelessWidget {
  const JobDetailPage({
    super.key,
    required this.job,
    this.onApply,
    this.onToggleFavorite,
    this.isFavorite = false,
  });

  final JobData job;
  final VoidCallback? onApply;
  final VoidCallback? onToggleFavorite;
  final bool isFavorite;

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;
    final colorScheme = Theme.of(context).colorScheme;

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
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const Busqueda(),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: Icon(Icons.notifications_none, color: theme.primario()), // Ícono de notificaciones
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const Notificaciones(),
                      ),
                    );
                  },
                ),

                IconButton(
                  icon: const CircleAvatar(
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
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Ancho máximo para que se vea limpio también en tablets
            final maxWidth = constraints.maxWidth < 540 ? constraints.maxWidth : 540.0;

            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Fila superior: Back (opcional) y favorito
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            tooltip: 'Regresar',
                            onPressed: () => Navigator.maybePop(context),
                            icon: Icon(Icons.arrow_back, color: colorScheme.onBackground),
                          ),
                          IconButton(
                            tooltip: isFavorite ? 'Quitar de favoritos' : 'Agregar a favoritos',
                            onPressed: onToggleFavorite ??
                                    () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        isFavorite ? 'Quitado de favoritos' : 'Agregado a favoritos',
                                      ),
                                    ),
                                  );
                                },
                            icon: Icon(
                              isFavorite ? Icons.favorite : Icons.favorite_border,
                              color: theme.primario(),
                            ),
                          ),
                        ],
                      ),

                      // Título
                      Texto(text: job.title, fontSize: 22),
                      const SizedBox(height: 6),

                      // Sueldo
                      if (job.salary != null && job.salary!.trim().isNotEmpty) ...[
                        Texto(text: job.salary!, fontSize: 16),
                        const SizedBox(height: 6),
                      ],

                      // Empresa
                      Texto(text: job.company, fontSize: 16),
                      const SizedBox(height: 10),

                      // Dirección
                      if (job.address != null && job.address!.trim().isNotEmpty) ...[
                        Texto(text: job.address!, fontSize: 14),
                        const SizedBox(height: 14),
                      ],

                      const Divider(height: 24),

                      // Requisitos
                      if (job.requirements != null && job.requirements!.isNotEmpty) ...[
                        const Texto(text: 'Requisitos:', fontSize: 16),
                        const SizedBox(height: 6),
                        ...job.requirements!.map(
                              (r) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Texto(text: r, fontSize: 14),
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Divider(height: 24),
                      ],

                      // Descripción
                      if (job.description != null && job.description!.trim().isNotEmpty) ...[
                        const Texto(text: 'Descripcion:', fontSize: 16),
                        const SizedBox(height: 6),
                        Texto(text: job.description!, fontSize: 14),
                      ],

                      const SizedBox(height: 24),

                      // Botón Postularme (centrado)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 220,
                            height: 44,
                            child: ElevatedButton(
                              onPressed: onApply ??
                                      () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Postulación enviada')),
                                    );
                                  },
                              style: ElevatedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Text('Postularme'),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// -------------------------
/// Stubs para que compile si no existen aún
/// -------------------------

class Busqueda extends StatelessWidget {
  const Busqueda({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;
    return Scaffold(
      backgroundColor: theme.background(),
      appBar: AppBar(
        title: const Text('Búsqueda'),
        backgroundColor: theme.background(),
        elevation: 0,
      ),
      body: const Center(child: Text('Pantalla de Búsqueda (stub)')),
    );
  }
}

class Notificaciones extends StatelessWidget {
  const Notificaciones({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;
    return Scaffold(
      backgroundColor: theme.background(),
      appBar: AppBar(
        title: const Text('Notificaciones'),
        backgroundColor: theme.background(),
        elevation: 0,
      ),
      body: const Center(child: Text('Pantalla de Notificaciones (stub)')),
    );
  }
}
