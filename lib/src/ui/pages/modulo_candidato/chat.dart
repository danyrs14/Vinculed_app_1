import 'package:flutter/material.dart';
import 'package:vinculed_app_1/src/core/controllers/theme_controller.dart';
import 'package:vinculed_app_1/src/ui/widgets/textos/textos.dart';

/// Pantalla de conversación (contenido completo).
/// Llama a esta pantalla al tocar un ChatPreviewTile.
class ChatConversationPage extends StatefulWidget {
  const ChatConversationPage({
    super.key,
    required this.contactName,
    this.isTyping = false,
  });

  final String contactName;
  final bool isTyping;

  @override
  State<ChatConversationPage> createState() => _ChatConversationPageState();
}

class _ChatConversationPageState extends State<ChatConversationPage> {
  final _scrollCtrl = ScrollController();
  final _inputCtrl = TextEditingController();

  // Mensajes de ejemplo (adáptalos a tu modelo real)
  late List<_Msg> _messages = [
    _Msg(text: 'Sam, are you ready? 😂😂', me: false, time: '15:18 PM'),
    _Msg(text: 'Actually yes, lemme see..', me: true, time: ''),
    _Msg(text: 'Done, I just finished it!', me: true, time: ''),
    _Msg(text: '🥺🥺', me: true, time: '15:19 PM'),
    _Msg(text: 'Nah, it\'s crazy 😁', me: false, time: ''),
    _Msg(text: 'Cheating?', me: false, time: '15:20 PM'),
    _Msg(text: 'No way, lol', me: true, time: ''),
    _Msg(text: 'I\'m a pro, that\'s why 😎', me: true, time: '15:20 PM'),
    _Msg(text: 'Still, can\'t believe 🤣', me: false, time: '15:21 PM'),
    _Msg(text: 'Read about inflation news, now!!', me: true, time: '15:22 PM'),
  ];

  @override
  void dispose() {
    _scrollCtrl.dispose();
    _inputCtrl.dispose();
    super.dispose();
  }

  void _send() {
    final txt = _inputCtrl.text.trim();
    if (txt.isEmpty) return;
    setState(() {
      _messages.add(_Msg(text: txt, me: true, time: _nowLabel()));
    });
    _inputCtrl.clear();
    _jumpToEnd();
  }

  String _nowLabel() {
    final now = DateTime.now();
    final hh = now.hour.toString().padLeft(2, '0');
    final mm = now.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  void _jumpToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollCtrl.hasClients) return;
      _scrollCtrl.animateTo(
        _scrollCtrl.position.maxScrollExtent + 80,
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
            // Header en el contenido (para no depender de AppBar externo)
            _ChatHeader(
              name: widget.contactName,
              subtitle: widget.isTyping ? 'escribiendo...' : null,
              onBack: () => Navigator.maybePop(context),
            ),

            // Separador de fecha ("TODAY, JULY 15")
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'TODAY, JULY 15',
                    style: TextStyle(fontSize: 12, letterSpacing: 0.6),
                  ),
                ),
              ),
            ),

            // Lista de mensajes
            Expanded(
              child: ListView.builder(
                controller: _scrollCtrl,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                itemCount: _messages.length,
                itemBuilder: (context, i) {
                  final m = _messages[i];
                  // Mostrar hora debajo de ciertos mensajes como en la captura
                  final showTime = m.time.isNotEmpty;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Column(
                      crossAxisAlignment:
                      m.me ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                      children: [
                        _Bubble(msg: m),
                        if (showTime) ...[
                          const SizedBox(height: 4),
                          Text(m.time, style: const TextStyle(fontSize: 11)),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),

            // Caja de texto de mensaje
            _InputBar(
              controller: _inputCtrl,
              onSend: _send,
            ),
          ],
        ),
      ),
    );
  }
}

/// Modelo interno de mensaje (ajústalo a tu dominio si ya lo tienes)
class _Msg {
  final String text;
  final bool me; // true: enviado por mí (derecha). false: recibido (izquierda).
  final String time; // etiqueta visible bajo algunos bubbles.

  _Msg({required this.text, required this.me, required this.time});
}

/// Encabezado del chat (dentro del body)
class _ChatHeader extends StatelessWidget {
  const _ChatHeader({
    required this.name,
    this.subtitle,
    this.onBack,
  });

  final String name;
  final String? subtitle;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          ),
          const CircleAvatar(
            radius: 18,
            backgroundImage: AssetImage('assets/images/amlo.jpg'), // usa tu asset o cámbialo por iniciales
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Texto(text: name, fontSize: 16),
                if ((subtitle ?? '').isNotEmpty)
                  Text(
                    subtitle!,
                    style: TextStyle(fontSize: 12, color: theme.secundario()),
                  ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_none),
          ),
        ],
      ),
    );
  }
}

/// Burbuja de chat
class _Bubble extends StatelessWidget {
  const _Bubble({required this.msg});

  final _Msg msg;

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;

    final bg = msg.me ? theme.secundario() : Colors.blueGrey.withOpacity(0.25);
    final fg = msg.me ? Colors.white : Colors.black87;

    final radius = BorderRadius.only(
      topLeft: const Radius.circular(14),
      topRight: const Radius.circular(14),
      bottomLeft: Radius.circular(msg.me ? 14 : 3),
      bottomRight: Radius.circular(msg.me ? 3 : 14),
    );

    final tickColor = msg.me ? Colors.white.withOpacity(0.9) : Colors.transparent;

    return Row(
      mainAxisAlignment: msg.me ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (!msg.me) const SizedBox(width: 32), // sangría ligera como en apps reales
        Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(color: bg, borderRadius: radius),
            child: Text(
              msg.text,
              style: TextStyle(color: fg, fontSize: 14, height: 1.25),
            ),
          ),
        ),
        if (msg.me) ...[
          const SizedBox(width: 6),
          // "palomitas" estilo simple
          Icon(Icons.done_all, size: 16, color: tickColor),
        ],
      ],
    );
  }
}

/// Barra de entrada inferior
class _InputBar extends StatelessWidget {
  const _InputBar({
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
        padding: const EdgeInsets.fromLTRB(14, 6, 14, 10),
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: theme.background(),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: Colors.black87, width: 1.2),
                ),
                child: TextField(
                  controller: controller,
                  minLines: 1,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText: 'Escribe aquí...',
                    border: InputBorder.none,
                  ),
                  onSubmitted: (_) => onSend(),
                ),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: onSend,
              child: CircleAvatar(
                radius: 24,
                backgroundColor: theme.secundario(),
                child: const Icon(Icons.send, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
