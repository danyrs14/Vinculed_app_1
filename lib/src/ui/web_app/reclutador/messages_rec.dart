import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:vinculed_app_1/src/core/controllers/theme_controller.dart';
import 'package:vinculed_app_1/src/core/models/chat_thread.dart';
import 'package:vinculed_app_1/src/core/models/chat_model.dart';
import 'package:vinculed_app_1/src/core/services/chat_service.dart';
import 'package:vinculed_app_1/src/core/services/chat_new_helper.dart';
import 'package:vinculed_app_1/src/ui/widgets/elements_app/chat_preview.dart';
import 'package:vinculed_app_1/src/ui/widgets/textos/textos.dart';
import 'package:vinculed_app_1/src/ui/widgets/text_inputs/text_input.dart';

import 'package:vinculed_app_1/src/ui/widgets/elements/header3.dart';
import 'package:vinculed_app_1/src/ui/widgets/elements/footer.dart';

class MessagesPageRec extends StatefulWidget {
  const MessagesPageRec({super.key});

  @override
  State<MessagesPageRec> createState() => _MessagesPageRecState();
}

class _MessagesPageRecState extends State<MessagesPageRec> {
  final _scrollCtrl = ScrollController();
  bool _showFooter = false;

  static const double _footerReservedSpace = EscomFooter.height;
  static const double _extraBottomPadding = 24.0;
  static const double _atEndThreshold = 4.0;

  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  String _myUid = '';

  // Para el panel derecho (chat embebido) o pantalla de chat en móvil
  String? _selectedPeerUid;
  String? _selectedContactName;

  @override
  void initState() {
    super.initState();
    final user = _auth.currentUser;
    _myUid = user?.uid ?? '';

    _scrollCtrl.addListener(_handleScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _handleScroll());
  }

  void _handleScroll() {
    final pos = _scrollCtrl.position;
    if (!pos.hasPixels || !pos.hasContentDimensions) return;

    if (pos.maxScrollExtent <= 0) {
      if (_showFooter) setState(() => _showFooter = false);
      return;
    }

    final atBottom = pos.pixels >= (pos.maxScrollExtent - _atEndThreshold);
    if (atBottom != _showFooter) setState(() => _showFooter = atBottom);
  }

  @override
  void dispose() {
    _scrollCtrl
      ..removeListener(_handleScroll)
      ..dispose();
    super.dispose();
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
  /// y mostramos la conversación (embed) o pantalla de chat en móvil.
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

    // ===================== SIN SESIÓN =====================
    if (_myUid.isEmpty) {
      return Scaffold(
        backgroundColor: theme.background(),
        appBar: EscomHeader3(
          onLoginTap: () => context.go('/reclutador/perfil_rec'),
          onNotifTap: () {},
          onMenuSelected: (label) {
            switch (label) {
              case "Inicio":
                context.go('/inicio');
                break;
              case "Crear Vacante":
                context.go('/reclutador/new_vacancy');
                break;
              case "Mis Vacantes":
                context.go('/reclutador/postulaciones');
                break;
              case "FAQ":
                context.go('/reclutador/faq_rec');
                break;
              case "Mensajes":
                context.go('/reclutador/msg_rec');
                break;
            }
          },
        ),
        body: Stack(
          children: [
            Positioned.fill(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final minBodyHeight =
                      constraints.maxHeight - _footerReservedSpace - _extraBottomPadding;

                  return NotificationListener<ScrollNotification>(
                    onNotification: (n) {
                      if (n is ScrollUpdateNotification ||
                          n is UserScrollNotification ||
                          n is ScrollEndNotification) {
                        _handleScroll();
                      }
                      return false;
                    },
                    child: SingleChildScrollView(
                      controller: _scrollCtrl,
                      padding: const EdgeInsets.only(
                        bottom: _footerReservedSpace + _extraBottomPadding,
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1200),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 24,
                            ),
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minHeight: minBodyHeight > 0 ? minBodyHeight : 0,
                              ),
                              child: const Center(
                                child: Text('Inicia sesión para ver tus mensajes'),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Footer animado (aparece al llegar al final del contenido)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: AnimatedSlide(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                offset: _showFooter ? Offset.zero : const Offset(0, 1),
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 220),
                  opacity: _showFooter ? 1 : 0,
                  child: EscomFooter(isMobile: isMobile),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // ===================== CON SESIÓN =====================
    return Scaffold(
      backgroundColor: theme.background(),
      appBar: EscomHeader3(
        onLoginTap: () => context.go('/reclutador/perfil_rec'),
        onNotifTap: () {},
        onMenuSelected: (label) {
          switch (label) {
            case "Inicio":
              context.go('/inicio');
              break;
            case "Crear Vacante":
              context.go('/reclutador/new_vacancy');
              break;
            case "Mis Vacantes":
              context.go('/reclutador/postulaciones');
              break;
            case "FAQ":
              context.go('/reclutador/faq_rec');
              break;
            case "Mensajes":
              context.go('/reclutador/msg_rec');
              break;
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _startNewChat,
        backgroundColor: theme.secundario(),
        child: const Icon(Icons.chat_bubble_outline),
      ),
      body: Stack(
        children: [
          // Scroll global con padding inferior para el footer
          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final minBodyHeight =
                    constraints.maxHeight - _footerReservedSpace - _extraBottomPadding;

                return NotificationListener<ScrollNotification>(
                  onNotification: (n) {
                    if (n is ScrollUpdateNotification ||
                        n is UserScrollNotification ||
                        n is ScrollEndNotification) {
                      _handleScroll();
                    }
                    return false;
                  },
                  child: SingleChildScrollView(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.only(
                      bottom: _footerReservedSpace + _extraBottomPadding,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1200),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 24,
                          ),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: minBodyHeight > 0 ? minBodyHeight : 0,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const SizedBox(height: 8),
                                const Texto(text: 'Mensajes', fontSize: 22),
                                const SizedBox(height: 12),

                                // Layout: web (row) / móvil (pantallas: lista o chat)
                                SizedBox(
                                  height: 520,
                                  child: isMobile
                                      ? (
                                      // SOLO modo móvil:
                                      //  - si no hay seleccionado -> lista completa
                                      //  - si hay seleccionado -> chat a pantalla completa (dentro de este alto)
                                      _selectedPeerUid == null
                                          ? _buildChatListMobile()
                                          : _ChatPanelRec(
                                        myUid: _myUid,
                                        peerUid: _selectedPeerUid!,
                                        contactName:
                                        _selectedContactName ??
                                            'Usuario',
                                        onBack: () {
                                          setState(() {
                                            _selectedPeerUid = null;
                                            _selectedContactName = null;
                                          });
                                        },
                                      )
                                  )
                                      : Row(
                                    children: [
                                      // ========== LISTA DE CONVERSACIONES (IZQUIERDA) ==========
                                      SizedBox(
                                        width: 340,
                                        child: StreamBuilder<List<ChatThread>>(
                                          stream: ChatService.instance
                                              .streamUserChats(_myUid),
                                          builder: (context, snapshot) {
                                            if (snapshot.hasError) {
                                              debugPrint(
                                                  'Error en streamUserChats (rec): ${snapshot.error}');
                                              return const Center(
                                                child: Text(
                                                  'No existe el chat',
                                                  style: TextStyle(
                                                      fontSize: 14),
                                                  textAlign:
                                                  TextAlign.center,
                                                ),
                                              );
                                            }

                                            if (snapshot.connectionState ==
                                                ConnectionState.waiting) {
                                              return const Center(
                                                child:
                                                CircularProgressIndicator(),
                                              );
                                            }

                                            final threads =
                                                snapshot.data ?? [];

                                            if (threads.isEmpty) {
                                              return const Center(
                                                child: Text(
                                                  'Aún no tienes conversaciones',
                                                  style: TextStyle(
                                                      fontSize: 14),
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
                                                final peerUid = thread
                                                    .participants
                                                    .firstWhere(
                                                      (uid) => uid != _myUid,
                                                  orElse: () => '',
                                                );

                                                if (peerUid.isEmpty) {
                                                  return const SizedBox
                                                      .shrink();
                                                }

                                                final timeLabel =
                                                _formatTimeLabel(
                                                    thread
                                                        .lastMessageAt);

                                                final int totalUnread =
                                                    thread.unreadCount;
                                                final bool lastFromMe =
                                                    thread.lastSenderUid ==
                                                        _myUid;

                                                final bool hasNewForMe =
                                                    !lastFromMe &&
                                                        totalUnread > 0;

                                                final int unreadForMe =
                                                hasNewForMe ? 1 : 0;

                                                // ========= OBTENER NOMBRE DESDE EL DOCUMENTO DEL CHAT =========
                                                String displayName =
                                                _fallbackName(peerUid);

                                                final Map<String,
                                                    dynamic>?
                                                namesMap = thread
                                                    .participantsDisplayNames;
                                                if (namesMap != null &&
                                                    namesMap.containsKey(
                                                        peerUid)) {
                                                  final raw =
                                                  namesMap[peerUid];
                                                  if (raw is String &&
                                                      raw
                                                          .trim()
                                                          .isNotEmpty) {
                                                    displayName =
                                                        raw.trim();
                                                  }
                                                }
                                                // =============================================================

                                                final preview = ChatPreview(
                                                  name: displayName,
                                                  lastMessage:
                                                  thread.lastMessage,
                                                  timeLabel: timeLabel,
                                                  unreadCount:
                                                  unreadForMe,
                                                  isTyping: false,
                                                );

                                                return ChatPreviewTile(
                                                  preview: preview,
                                                  onTap: () {
                                                    setState(() {
                                                      _selectedPeerUid =
                                                          peerUid;
                                                      _selectedContactName =
                                                          displayName;
                                                    });
                                                  },
                                                );
                                              },
                                            );
                                          },
                                        ),
                                      ),

                                      const SizedBox(width: 16),

                                      // ========== PANEL DE CHAT (DERECHA) ==========
                                      Expanded(
                                        child: _selectedPeerUid == null
                                            ? Container(
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius:
                                            BorderRadius.circular(
                                                12),
                                            border: Border.all(
                                              color: Colors.black12,
                                            ),
                                          ),
                                          child: const Center(
                                            child: Text(
                                              'Selecciona una conversación o inicia un chat nuevo',
                                              style: TextStyle(
                                                  fontSize: 14),
                                              textAlign:
                                              TextAlign.center,
                                            ),
                                          ),
                                        )
                                            : _ChatPanelRec(
                                          myUid: _myUid,
                                          peerUid: _selectedPeerUid!,
                                          contactName:
                                          _selectedContactName ??
                                              'Usuario',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Footer animado (aparece al llegar al final del contenido)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: AnimatedSlide(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              offset: _showFooter ? Offset.zero : const Offset(0, 1),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 220),
                opacity: _showFooter ? 1 : 0,
                child: EscomFooter(isMobile: isMobile),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Lista de conversaciones para MODO MÓVIL (pantalla de lista completa),
  /// basada en tu widget `Mensajes`.
  Widget _buildChatListMobile() {
    return StreamBuilder<List<ChatThread>>(
      stream: ChatService.instance.streamUserChats(_myUid),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          debugPrint('Error en streamUserChats (rec): ${snapshot.error}');
          return const Center(
            child: Text(
              'Ocurrió un error al cargar tus chats',
              style: TextStyle(fontSize: 14),
              textAlign: TextAlign.center,
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
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
          separatorBuilder: (_, __) => const SizedBox(height: 6),
          itemBuilder: (context, i) {
            final thread = threads[i];

            // Encontrar al otro usuario (peerUid)
            final peerUid = thread.participants.firstWhere(
                  (uid) => uid != _myUid,
              orElse: () => '',
            );

            if (peerUid.isEmpty) {
              return const SizedBox.shrink();
            }

            final timeLabel = _formatTimeLabel(thread.lastMessageAt);

            final int totalUnread = thread.unreadCount;
            final bool lastFromMe = thread.lastSenderUid == _myUid;

            final bool hasNewForMe = !lastFromMe && totalUnread > 0;

            final int unreadForMe = hasNewForMe ? 1 : 0;

            // ========= OBTENER NOMBRE DESDE EL DOCUMENTO DEL CHAT =========
            String displayName = _fallbackName(peerUid);

            final Map<String, dynamic>? namesMap =
                thread.participantsDisplayNames;
            if (namesMap != null && namesMap.containsKey(peerUid)) {
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
    );
  }
}

/// ======================= PANEL DE CHAT (WEB REC / MÓVIL) =======================
/// Versión adaptada del ChatConversationPage, pero embebida.
/// En móvil se muestra a pantalla completa dentro del contenedor de 520px,
/// con botón de regreso opcional.
class _ChatPanelRec extends StatefulWidget {
  const _ChatPanelRec({
    required this.myUid,
    required this.peerUid,
    required this.contactName,
    this.onBack,
  });

  final String myUid;
  final String peerUid;
  final String contactName;
  final VoidCallback? onBack; // solo se usa en modo móvil

  @override
  State<_ChatPanelRec> createState() => _ChatPanelRecState();
}

class _ChatPanelRecState extends State<_ChatPanelRec> {
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
  void didUpdateWidget(covariant _ChatPanelRec oldWidget) {
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
          // Header interno del chat (con o sin back)
          _ChatHeaderRec(
            name: widget.contactName,
            subtitle: null,
            onBack: widget.onBack,
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
                  'CHAT',
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

                    final m = _MsgRec(
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
                          _BubbleRec(msg: m),
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
          _InputBarRec(
            controller: _inputCtrl,
            onSend: _send,
          ),
        ],
      ),
    );
  }
}

/// Modelo interno para la burbuja (reclutador)
class _MsgRec {
  final String text;
  final bool me;
  final String time;

  _MsgRec({
    required this.text,
    required this.me,
    required this.time,
  });
}

/// Encabezado del panel de chat (reclutador)
/// Ahora puede opcionalmente mostrar un botón de back (solo en móvil).
class _ChatHeaderRec extends StatelessWidget {
  const _ChatHeaderRec({
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
          if (onBack != null)
            IconButton(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back_ios_new, size: 20),
            ),
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
        ],
      ),
    );
  }
}

/// Burbuja de chat (reclutador)
class _BubbleRec extends StatelessWidget {
  const _BubbleRec({required this.msg});

  final _MsgRec msg;

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

/// Barra de entrada inferior del panel (reclutador)
class _InputBarRec extends StatelessWidget {
  const _InputBarRec({
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
