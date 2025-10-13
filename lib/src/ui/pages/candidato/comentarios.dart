import 'package:flutter/material.dart';
import 'package:vinculed_app_1/src/core/controllers/theme_controller.dart';
import 'package:vinculed_app_1/src/ui/widgets/textos/textos.dart';

/// Pantalla de Comentarios (solo contenido, sin AppBar ni menú).
/// Llama a esta pantalla cuando el usuario toca "Comentar" o "1Comentario".
class ComentariosPage extends StatefulWidget {
  const ComentariosPage({super.key});

  @override
  State<ComentariosPage> createState() => _ComentariosPageState();
}

class _ComentariosPageState extends State<ComentariosPage> {
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  // Comentarios de ejemplo (ajusta a tu modelo real si lo tienes)
  final List<_Comentario> _items = [
    const _Comentario(
      author: 'Alejandro Yañez Sanchez',
      text: 'Muy buena reseña, me encanta!',
    ),
  ];

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _send() {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _items.add(_Comentario(author: 'Tú', text: text));
    });
    _inputCtrl.clear();
    _jumpToEnd();
  }

  void _jumpToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollCtrl.hasClients) return;
      _scrollCtrl.animateTo(
        _scrollCtrl.position.maxScrollExtent + 100,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;

    return Scaffold(
      backgroundColor: theme.background(),
      body: SafeArea(
        child: Column(
          children: [
            // Encabezado dentro del body (sin AppBar global)
            Padding(
              padding: const EdgeInsets.fromLTRB(6, 6, 12, 6),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.maybePop(context),
                    icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                  ),
                  const Expanded(
                    child: Center(
                      child: Texto(text: 'Comentarios', fontSize: 22),
                    ),
                  ),
                  const SizedBox(width: 40), // balancea el espacio con el back
                ],
              ),
            ),

            // Lista de comentarios
            Expanded(
              child: ListView.builder(
                controller: _scrollCtrl,
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
                itemCount: _items.length,
                itemBuilder: (context, i) {
                  final c = _items[i];
                  return _CommentTile(
                    author: c.author,
                    text: c.text,
                    onLike: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Te gustó este comentario')),
                      );
                    },
                    onReply: () {
                      setState(() {
                        _inputCtrl.text = '@${c.author.split(' ').first} ';
                        _inputCtrl.selection = TextSelection.fromPosition(
                          TextPosition(offset: _inputCtrl.text.length),
                        );
                      });
                    },
                  );
                },
              ),
            ),

            // Caja de texto inferior
            _CommentInputBar(
              controller: _inputCtrl,
              onSend: _send,
            ),
          ],
        ),
      ),
    );
  }
}

/// Modelo simple interno
class _Comentario {
  final String author;
  final String text;
  const _Comentario({required this.author, required this.text});
}

/// Item visual de comentario (avatar + burbuja + acciones)
class _CommentTile extends StatelessWidget {
  const _CommentTile({
    required this.author,
    required this.text,
    this.onLike,
    this.onReply,
  });

  final String author;
  final String text;
  final VoidCallback? onLike;
  final VoidCallback? onReply;

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CircleAvatar(
            radius: 18,
            backgroundImage: AssetImage('assets/images/amlo.jpg'), // reemplaza por tu asset
          ),
          const SizedBox(width: 10),
          // Burbuja de comentario
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Texto(text: author, fontSize: 14),
                      const SizedBox(height: 6),
                      Text(
                        text,
                        style: const TextStyle(fontSize: 14, height: 1.3),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // Acciones (Me gusta | Responder)
                Row(
                  children: [
                    Icon(Icons.favorite_border, size: 20, color: theme.primario()),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: onLike,
                      child: Text(
                        'Me gusta',
                        style: TextStyle(color: theme.primario(), fontSize: 14),
                      ),
                    ),
                    const SizedBox(width: 18),
                    Icon(Icons.chat_bubble_outline, size: 20, color: theme.primario()),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: onReply,
                      child: Text(
                        'Responder',
                        style: TextStyle(color: theme.primario(), fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Barra inferior para escribir comentario
class _CommentInputBar extends StatelessWidget {
  const _CommentInputBar({
    required this.controller,
    required this.onSend,
  });

  final TextEditingController controller;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
        child: Row(
          children: [
            // Input redondeado estilo imagen
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: theme.background(),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: Colors.black87, width: 1.2),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: controller,
                  minLines: 1,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText: 'Comentar...',
                    border: InputBorder.none,
                  ),
                  onSubmitted: (_) => onSend(),
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Botón enviar (círculo azul con ícono triangular)
            GestureDetector(
              onTap: onSend,
              child: CircleAvatar(
                radius: 24,
                backgroundColor: theme.secundario(),
                child: const Icon(Icons.send_rounded, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
