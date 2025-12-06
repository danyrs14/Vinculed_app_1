import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:vinculed_app_1/src/core/controllers/theme_controller.dart';
import 'package:vinculed_app_1/src/core/models/chat_thread.dart';
import 'package:vinculed_app_1/src/core/services/chat_service.dart';
import 'package:vinculed_app_1/src/ui/pages/reclutador/chat.dart';
import 'package:vinculed_app_1/src/ui/widgets/elements_app/chat_preview.dart';
import 'package:vinculed_app_1/src/ui/widgets/textos/textos.dart';

class Mensajes extends StatefulWidget {
  const Mensajes({super.key});

  @override
  State<Mensajes> createState() => _MensajesState();
}

class _MensajesState extends State<Mensajes> {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  String _myUid = '';

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

  // Fallback genérico si no hay nombre en Firestore
  String _fallbackName(String uid) {
    if (uid.isEmpty) return 'Usuario';
    return 'Usuario';
  }

  /// Lógica para iniciar un chat nuevo desde el FAB
  Future<void> _startNewChat() async {
    if (_myUid.isEmpty) return;

    final controller = TextEditingController();

    final peerUid = await showDialog<String>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Nuevo chat'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'UID del usuario',
              hintText: 'Pega o escribe el UID del usuario',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                final value = controller.text.trim();
                Navigator.of(ctx).pop(value.isEmpty ? null : value);
              },
              child: const Text('Iniciar'),
            ),
          ],
        );
      },
    );

    if (peerUid == null || peerUid.trim().isEmpty) {
      return;
    }

    final trimmedPeerUid = peerUid.trim();

    // Obtenemos el nombre del usuario (si existe en /users)
    String displayName = _fallbackName(trimmedPeerUid);
    try {
      final userDoc =
      await _db.collection('users').doc(trimmedPeerUid).get();
      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>? ?? {};
        displayName = (data['fullName'] ??
            data['displayName'] ??
            data['name'] ??
            displayName)
            .toString();
      }
    } catch (_) {
      // Si falla la consulta, usamos el fallback y ya
    }
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatConversation(
          contactName: displayName,
          peerUid: trimmedPeerUid,
          isTyping: false,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;

    if (_myUid.isEmpty) {
      return Scaffold(
        backgroundColor: theme.background(),
        body: const Center(
          child: Text('Inicia sesión para ver tus mensajes'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.background(),
      floatingActionButton: FloatingActionButton(
        onPressed: _startNewChat,
        backgroundColor: theme.secundario(),
        child: const Icon(Icons.chat_bubble_outline),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 8),
              const Texto(text: 'Mensajes', fontSize: 22),
              const SizedBox(height: 12),

              // Lista de conversaciones desde Firestore
              Expanded(
                child: StreamBuilder<List<ChatThread>>(
                  stream: ChatService.instance.streamUserChats(_myUid),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      // Para que veas el error real en la consola
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
                        final peerUid = thread.participants.firstWhere(
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
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ChatConversation(
                                  contactName: displayName,
                                  peerUid: peerUid,
                                  isTyping: false,
                                ),
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
