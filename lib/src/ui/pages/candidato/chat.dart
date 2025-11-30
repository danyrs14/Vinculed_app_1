import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:vinculed_app_1/src/core/controllers/theme_controller.dart';
import 'package:vinculed_app_1/src/core/models/chat_model.dart';
import 'package:vinculed_app_1/src/core/services/chat_service.dart';
import 'package:vinculed_app_1/src/ui/widgets/text_inputs/text_input.dart';
import 'package:vinculed_app_1/src/ui/widgets/textos/textos.dart';

class ChatConversationPage extends StatefulWidget {
  const ChatConversationPage({
    super.key,
    required this.contactName,
    required this.peerUid,
    this.isTyping = false,
  });

  final String contactName;
  final String peerUid;
  final bool isTyping;

  @override
  State<ChatConversationPage> createState() => _ChatConversationPageState();
}

class _ChatConversationPageState extends State<ChatConversationPage> {
  final _scrollCtrl = ScrollController();
  final _inputCtrl = TextEditingController();

  late final String _myUid;
  late final String _chatId;

  @override
  void initState() {
    super.initState();

    final user = FirebaseAuth.instance.currentUser;
    _myUid = user?.uid ?? '';

    _chatId = ChatService.instance.buildChatId(_myUid, widget.peerUid);

    // Opcional: marcar como leído el chat cuando se abre
    if (_myUid.isNotEmpty) {
      ChatService.instance.markChatAsRead(chatId: _chatId, userUid: _myUid);
    }
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    _inputCtrl.dispose();
    super.dispose();
  }

  /// Enviar mensaje usando ChatService (Firestore)
  Future<void> _send() async {
    final txt = _inputCtrl.text.trim();
    if (txt.isEmpty || _myUid.isEmpty) return;

    _inputCtrl.clear();

    await ChatService.instance.sendMessage(
      senderUid: _myUid,
      receiverUid: widget.peerUid,
      text: txt,
    );

    _jumpToEnd();
  }

  String _formatTime(DateTime dt) {
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
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

            // Separador de fecha ("TODAY, JULY 15") – lo dejamos fijo como en tu diseño
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Center(
                child: Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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

            // Lista de mensajes (desde Firestore)
            Expanded(
              child: StreamBuilder<List<ChatMessage>>(
                stream: ChatService.instance.streamMessages(_chatId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final msgs = snapshot.data ?? [];

                  if (msgs.isEmpty) {
                    return const Center(
                      child: Text(
                        'Comienza la conversación ✨',
                        style: TextStyle(fontSize: 14),
                      ),
                    );
                  }

                  // Auto-scroll al final cuando hay nuevos mensajes
                  WidgetsBinding.instance
                      .addPostFrameCallback((_) => _jumpToEnd());

                  return ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    itemCount: msgs.length,
                    itemBuilder: (context, i) {
                      final chatMsg = msgs[i];

                      final isMe = chatMsg.senderUid == _myUid;
                      final timeLabel = _formatTime(chatMsg.createdAt);

                      // Adaptamos el modelo real a tu modelo visual _Msg
                      final m = _Msg(
                        text: chatMsg.text,
                        me: isMe,
                        time: timeLabel,
                      );

                      final showTime = m.time.isNotEmpty;

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Column(
                          crossAxisAlignment: m.me
                              ? CrossAxisAlignment.end
                              : CrossAxisAlignment.start,
                          children: [
                            _Bubble(msg: m),
                            if (showTime) ...[
                              const SizedBox(height: 4),
                              Text(
                                m.time,
                                style: const TextStyle(fontSize: 11),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
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

/// Modelo interno de mensaje (solo para la parte visual)
class _Msg {
  final String text;
  final bool me; // true: enviado por mí (derecha). false: recibido (izquierda).
  final String time; // etiqueta visible bajo algunos bubbles.

  _Msg({
    required this.text,
    required this.me,
    required this.time,
  });
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
          CircleAvatar(
            backgroundColor: Colors.blue[50],
            radius: 18,
            backgroundImage: const AssetImage(
              'assets/images/amlo.jpg',
            ), // usa tu asset o cámbialo por iniciales/NetworkImage si luego usas fotos
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
                    style:
                    TextStyle(fontSize: 12, color: theme.secundario()),
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

/// Burbuja de chat (diseño igual al que ya tenías)
class _Bubble extends StatelessWidget {
  const _Bubble({required this.msg});

  final _Msg msg;

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;

    final bg =
    msg.me ? theme.secundario() : Colors.blueGrey.withOpacity(0.25);
    final fg = msg.me ? Colors.white : Colors.black87;

    final radius = BorderRadius.only(
      topLeft: const Radius.circular(14),
      topRight: const Radius.circular(14),
      bottomLeft: Radius.circular(msg.me ? 14 : 3),
      bottomRight: Radius.circular(msg.me ? 3 : 14),
    );

    final tickColor =
    msg.me ? Colors.white.withOpacity(0.9) : Colors.transparent;

    return Row(
      mainAxisAlignment:
      msg.me ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (!msg.me) const SizedBox(width: 32), // sangría ligera como en apps reales
        Flexible(
          child: Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
              child: TextInput(
                controller: controller,
                minLines: 1,
                maxLines: 4,
                title: 'Escribe un mensaje',
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
