import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:vinculed_app_1/src/core/controllers/theme_controller.dart';
import 'package:vinculed_app_1/src/core/models/chat_thread.dart';
import 'package:vinculed_app_1/src/core/models/chat_model.dart';
import 'package:vinculed_app_1/src/core/services/chat_service.dart';
import 'package:vinculed_app_1/src/core/services/chat_new_helper.dart';
import 'package:vinculed_app_1/src/ui/pages/reclutador/chat.dart'; // lo dejamos por compatibilidad
import 'package:vinculed_app_1/src/ui/widgets/elements_app/chat_preview.dart';
import 'package:vinculed_app_1/src/ui/widgets/textos/textos.dart';
import 'package:vinculed_app_1/src/ui/widgets/text_inputs/text_input.dart';

import 'package:vinculed_app_1/src/ui/widgets/elements/header2.dart';
import 'package:vinculed_app_1/src/ui/widgets/elements/footer.dart';

class MessagesPage extends StatefulWidget {
  const MessagesPage({super.key});

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  String _myUid = '';

  // 👉 Para el panel derecho (chat embebido)
  String? _selectedPeerUid;
  String? _selectedContactName;

  @override
  void initState() {
    super.initState();
    final user = _auth.currentUser;
    _myUid = user?.uid ?? '';
  }

  String _formatTimeLabel(DateTime? dt) {
    if (dt == null) return '';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(dt.year, dt.month, dt.day);

    final diff = today.difference(day).inDays;

    if (diff == 0) {
      final hh = dt.hour.toString().padLeft(2, '0');
      final mm = dt.minute.toString().padLeft(2, '0');
      return '$hh:$mm';
    } else if (diff == 1) {
      return 'ayer';
    } else if (diff < 7) {
      const weekdays = [
        'Lunes',
        'Martes',
        'Miércoles',
        'Jueves',
        'Viernes',
        'Sábado',
        'Domingo',
      ];
      return weekdays[dt.weekday - 1];
    } else {
      final d = dt.day.toString().padLeft(2, '0');
      final m = dt.month.toString().padLeft(2, '0');
      final y = dt.year.toString();
      return '$d/$m/$y';
    }
  }

  String _fallbackName(String uid) {
    if (uid.isEmpty) return 'Usuario';
    return 'Usuario';
  }

  /// Nuevo chat: usamos ChatNewHelper para elegir usuario
  /// y mostramos la conversación en el panel derecho (no navegamos a otra pantalla).
  Future<void> _startNewChat() async {
    if (_myUid.isEmpty) return;

    final selection = await ChatNewHelper.instance.pickUserByName(
      context: context,
    );

    if (!mounted || selection == null) return;

    setState(() {
      _selectedPeerUid = selection.peerUid;
      _selectedContactName = selection.displayName;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;
    final w = MediaQuery.of(context).size.width;
    final isMobile = w < 700;

    // Si no hay sesión, mostramos el mismo mensaje pero con header y footer.
    if (_myUid.isEmpty) {
      return Scaffold(
        backgroundColor: theme.background(),
        appBar: EscomHeader2(
          onLoginTap: () => context.go('/alumno/perfil_cand'),
          onNotifTap: () {},
          onMenuSelected: (label) {
            switch (label) {
              case "Inicio":
                context.go('/inicio');
                break;
              case "Postulaciones":
                context.go('/alumno/mis_postulaciones');
                break;
              case "MessagesPage":
                context.go('/alumno/messages');
                break;
              case "Experiencias":
                context.go('/alumno/experiencias');
                break;
              case "FAQ":
                context.go('/alumno/faq');
                break;
              case "Explorar Puestos en TI":
                context.go('/alumno/preferences');
                break;
            }
          },
        ),
        bottomNavigationBar: EscomFooter(isMobile: isMobile),
        body: const Center(
          child: Text('Inicia sesión para ver tus MessagesPage'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.background(),
      appBar: EscomHeader2(
        onLoginTap: () => context.go('/alumno/perfil_cand'),
        onNotifTap: () {},
        onMenuSelected: (label) {
          switch (label) {
            case "Inicio":
              context.go('/inicio');
              break;
            case "Postulaciones":
              context.go('/alumno/mis_postulaciones');
              break;
            case "MessagesPage":
              context.go('/alumno/messages');
              break;
            case "Experiencias":
              context.go('/alumno/experiencias');
              break;
            case "FAQ":
              context.go('/alumno/faq');
              break;
            case "Explorar Puestos en TI":
              context.go('/alumno/preferences');
              break;
          }
        },
      ),
      bottomNavigationBar: EscomFooter(isMobile: isMobile),
      floatingActionButton: FloatingActionButton(
        onPressed: _startNewChat,
        backgroundColor: theme.secundario(),
        child: const Icon(Icons.chat_bubble_outline),
      ),
      body: SafeArea(
        top: false, // 👈 para que no meta padding extra debajo del header
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 8),
              const Texto(text: 'MessagesPage', fontSize: 22),
              const SizedBox(height: 12),

              // Layout web: lista izquierda + chat derecho
              Expanded(
                child: Row(
                  children: [
                    // ==================== LISTA DE CONVERSACIONES (IZQUIERDA) ====================
                    SizedBox(
                      width: 340,
                      child: StreamBuilder<List<ChatThread>>(
                        stream: ChatService.instance.streamUserChats(_myUid),
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            debugPrint(
                                'Error en streamUserChats: ${snapshot.error}');
                            return const Center(
                              child: Text(
                                'Ocurrió un error al cargar tus chats',
                                style: TextStyle(fontSize: 14),
                                textAlign: TextAlign.center,
                              ),
                            );
                          }

                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          final threads = snapshot.data ?? [];

                          if (threads.isEmpty) {
                            return const Center(
                              child: Text(
                                'Aún no tienes conversaciones',
                                style: TextStyle(fontSize: 14),
                              ),
                            );
                          }

                          return ListView.separated(
                            itemCount: threads.length,
                            separatorBuilder: (_, __) =>
                            const SizedBox(height: 6),
                            itemBuilder: (context, i) {
                              final thread = threads[i];

                              // Encontrar al otro usuario (peerUid)
                              final peerUid =
                              thread.participants.firstWhere(
                                    (uid) => uid != _myUid,
                                orElse: () => '',
                              );

                              if (peerUid.isEmpty) {
                                return const SizedBox.shrink();
                              }

                              final timeLabel =
                              _formatTimeLabel(thread.lastMessageAt);

                              final int totalUnread = thread.unreadCount;
                              final bool lastFromMe =
                                  thread.lastSenderUid == _myUid;

                              final bool hasNewForMe =
                                  !lastFromMe && totalUnread > 0;

                              final int unreadForMe = hasNewForMe ? 1 : 0;

                              // ========= OBTENER NOMBRE DESDE EL DOCUMENTO DEL CHAT =========
                              String displayName = _fallbackName(peerUid);

                              final Map<String, dynamic>? namesMap =
                                  thread.participantsDisplayNames;
                              if (namesMap != null &&
                                  namesMap.containsKey(peerUid)) {
                                final raw = namesMap[peerUid];
                                if (raw is String && raw.trim().isNotEmpty) {
                                  displayName = raw.trim();
                                }
                              }
                              // =============================================================

                              final preview = ChatPreview(
                                name: displayName,
                                lastMessage: thread.lastMessage,
                                timeLabel: timeLabel,
                                unreadCount: unreadForMe,
                                isTyping: false,
                              );

                              return ChatPreviewTile(
                                preview: preview,
                                onTap: () {
                                  setState(() {
                                    _selectedPeerUid = peerUid;
                                    _selectedContactName = displayName;
                                  });
                                },
                              );
                            },
                          );
                        },
                      ),
                    ),

                    const SizedBox(width: 16),

                    // ==================== PANEL DE CHAT (DERECHA) ====================
                    Expanded(
                      child: _selectedPeerUid == null
                          ? Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.black12,
                          ),
                        ),
                        child: const Center(
                          child: Text(
                            'Selecciona una conversación o inicia un chat nuevo',
                            style: TextStyle(fontSize: 14),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                          : _ChatPanel(
                        myUid: _myUid,
                        peerUid: _selectedPeerUid!,
                        contactName:
                        _selectedContactName ?? 'Usuario',
                      ),
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

/// ======================= PANEL DE CHAT (WEB) =======================
/// Versión adaptada del ChatConversationPage, pero embebida en el lado derecho
class _ChatPanel extends StatefulWidget {
  const _ChatPanel({
    required this.myUid,
    required this.peerUid,
    required this.contactName,
  });

  final String myUid;
  final String peerUid;
  final String contactName;

  @override
  State<_ChatPanel> createState() => _ChatPanelState();
}

class _ChatPanelState extends State<_ChatPanel> {
  final _scrollCtrl = ScrollController();
  final _inputCtrl = TextEditingController();

  late String _chatId;

  @override
  void initState() {
    super.initState();

    // Construye el chatId determinístico (uid1_uid2)
    _chatId = ChatService.instance.buildChatId(widget.myUid, widget.peerUid);

    // Marcar como leído el chat cuando se abre
    if (widget.myUid.isNotEmpty) {
      ChatService.instance.markChatAsRead(
        chatId: _chatId,
        userUid: widget.myUid,
      );
    }
  }

  @override
  void didUpdateWidget(covariant _ChatPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Si cambiamos de peer, recalculamos chatId y marcamos como leído
    if (oldWidget.peerUid != widget.peerUid ||
        oldWidget.myUid != widget.myUid) {
      _chatId = ChatService.instance.buildChatId(
        widget.myUid,
        widget.peerUid,
      );
      if (widget.myUid.isNotEmpty) {
        ChatService.instance.markChatAsRead(
          chatId: _chatId,
          userUid: widget.myUid,
        );
      }
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
    if (txt.isEmpty || widget.myUid.isEmpty) return;

    _inputCtrl.clear();

    try {
      await ChatService.instance.sendMessage(
        senderUid: widget.myUid,
        receiverUid: widget.peerUid,
        text: txt,
      );
      _jumpToEnd();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al enviar mensaje: $e'),
        ),
      );
    }
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

    if (widget.myUid.isEmpty) {
      return Container(
        color: theme.background(),
        child: const Center(
          child: Text(
            'Debes iniciar sesión para usar el chat',
            style: TextStyle(fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: theme.background(),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        children: [
          // Header interno del chat
          _ChatHeader(
            name: widget.contactName,
            subtitle: null,
          ),

          // Separador de fecha como en el diseño móvil
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
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

          // Lista de MessagesPage (desde Firestore)
          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
              stream: ChatService.instance.streamMessages(_chatId),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(
                    child: Text(
                      'Ocurrió un error al cargar el chat',
                      style: TextStyle(fontSize: 14),
                    ),
                  );
                }

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

                WidgetsBinding.instance
                    .addPostFrameCallback((_) => _jumpToEnd());

                return ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  itemCount: msgs.length,
                  itemBuilder: (context, i) {
                    final chatMsg = msgs[i];

                    final isMe = chatMsg.senderUid == widget.myUid;
                    final timeLabel = _formatTime(chatMsg.createdAt);

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
    );
  }
}

/// Modelo interno para la burbuja
class _Msg {
  final String text;
  final bool me;
  final String time;

  _Msg({
    required this.text,
    required this.me,
    required this.time,
  });
}

/// Encabezado del panel de chat
class _ChatHeader extends StatelessWidget {
  const _ChatHeader({
    required this.name,
    this.subtitle,
  });

  final String name;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.blue[50],
            radius: 18,
            backgroundImage: const AssetImage(
              'assets/images/amlo.jpg',
            ),
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
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.secundario(),
                    ),
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
        if (!msg.me) const SizedBox(width: 32),
        Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: radius,
            ),
            child: Text(
              msg.text,
              style: TextStyle(
                color: fg,
                fontSize: 14,
                height: 1.25,
              ),
            ),
          ),
        ),
        if (msg.me) ...[
          const SizedBox(width: 6),
          Icon(Icons.done_all, size: 16, color: tickColor),
        ],
      ],
    );
  }
}

/// Barra de entrada inferior del panel
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
