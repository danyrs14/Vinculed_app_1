import 'package:flutter/material.dart';
import 'package:vinculed_app_1/src/core/controllers/theme_controller.dart';
import 'package:vinculed_app_1/src/ui/pages/candidato/comentarios.dart';
import 'package:vinculed_app_1/src/ui/widgets/textos/textos.dart';
import 'package:provider/provider.dart';
import 'package:vinculed_app_1/src/core/providers/user_provider.dart';

class Experiencias extends StatelessWidget {
  const Experiencias({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;

    return Scaffold(
      backgroundColor: theme.background(),
      // SIN appbar y SIN menú: solo contenido
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Encabezado dentro del body (flecha, título, botón +)
              Row(
                children: [
                  IconButton(
                    tooltip: 'Regresar',
                    onPressed: () => Navigator.maybePop(context),
                    icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                  ),
                  const SizedBox(width: 4),
                  const Expanded(
                    child: Center(
                      child: Texto(text: 'Experiencias', fontSize: 22),
                    ),
                  ),
                  // Botón + para crear experiencia
                  Material(
                    color: theme.secundario(),
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Crear nueva experiencia')),
                        );
                      },
                      child: const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Icon(Icons.add, color: Colors.white, size: 22),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Card de experiencia (como en la imagen)
              Expanded(
                child: ListView(
                  children: [
                    ExperiencePostCard(
                      authorName: 'Raul Medina Perez',
                      authorRole: 'Estudiante',
                      timeAgo: '20 h',
                      content:
                      'Mi experiencia como becaria en el departamento de desarrollo de software fue increíblemente enriquecedora. '
                          'Durante mi tiempo en la empresa, participé activamente en varios proyectos relacionados con la creación '
                          'y mejora de aplicaciones móviles.',
                      commentsCountLabel: '1 Comentario',
                      // Al tocar "Comentar" o el contador -> abrir pantalla Comentarios
                      onComment: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ComentariosPage(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tarjeta de publicación de experiencia (estilo de la captura)
class ExperiencePostCard extends StatelessWidget {
  const ExperiencePostCard({
    super.key,
    required this.authorName,
    required this.authorRole,
    required this.timeAgo,
    required this.content,
    required this.commentsCountLabel,
    this.onLike,
    this.onComment,
    this.onMore,
  });

  final String authorName;
  final String authorRole;
  final String timeAgo;
  final String content;
  final String commentsCountLabel;

  final VoidCallback? onLike;
  final VoidCallback? onComment;
  final VoidCallback? onMore;

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: theme.background(),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.black.withOpacity(0.08)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabecera: avatar, nombre/rol, menú ...
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const CircleAvatar(
                  radius: 18,
                  backgroundImage: AssetImage('assets/images/amlo.jpg'), // coloca tu asset o cámbialo
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Texto(text: authorName, fontSize: 14),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(authorRole, style: const TextStyle(fontSize: 12)),
                          const SizedBox(width: 8),
                          Text(timeAgo, style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Más opciones',
                  onPressed: onMore ??
                          () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Opciones de la publicación')),
                        );
                      },
                  icon: const Icon(Icons.more_horiz),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Contenido
            Text(
              content,
              style: const TextStyle(fontSize: 14, height: 1.35),
              textAlign: TextAlign.left,
            ),
            const SizedBox(height: 12),

            // Separador fino
            Container(height: 1, color: Colors.black.withOpacity(0.08)),

            // Conteo de comentarios (alineado a la derecha y CLICKEABLE)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  const Spacer(),
                  InkWell(
                    borderRadius: BorderRadius.circular(6),
                    onTap: onComment,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      child: Text(
                        commentsCountLabel,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 6),

            // Acciones: Me gusta | Comentar (ambos clickeables)
            Row(
              children: [
                IconButton(
                  onPressed: onLike ??
                          () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Te gustó esta experiencia')),
                        );
                      },
                  icon: Icon(Icons.favorite_border, color: theme.primario()),
                ),
                GestureDetector(
                  onTap: onLike,
                  child: Text(
                    'Me gusta',
                    style: TextStyle(color: theme.primario(), fontSize: 14),
                  ),
                ),
                const SizedBox(width: 18),
                IconButton(
                  onPressed: onComment,
                  icon: Icon(Icons.chat_bubble_outline, color: theme.primario()),
                ),
                GestureDetector(
                  onTap: onComment,
                  child: Text(
                    'Comentar',
                    style: TextStyle(color: theme.primario(), fontSize: 14),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
