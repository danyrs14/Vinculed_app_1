import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:vinculed_app_1/src/core/controllers/theme_controller.dart';
import 'package:vinculed_app_1/src/core/models/chat_thread.dart';
import 'package:vinculed_app_1/src/core/services/chat_service.dart';
import 'package:vinculed_app_1/src/ui/pages/candidato/chat.dart';
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
      // Hoy: mostrar hora
      final hh = dt.hour.toString().padLeft(2, '0');
      final mm = dt.minute.toString().padLeft(2, '0');
      return '$hh:$mm';
    } else if (diff == 1) {
      return 'ayer';
    } else if (diff < 7) {
      // Mismo rango de semana: día de la semana (muy simple)
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
      // Fecha dd/MM/yyyy
      final d = dt.day.toString().padLeft(2, '0');
      final m = dt.month.toString().padLeft(2, '0');
      final y = dt.year.toString();
      return '$d/$m/$y';
    }
  }

  String _fallbackName(String uid) {
    if (uid.length <= 8) return uid;
    return 'Usuario ${uid.substring(0, 6)}';
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
        onPressed: () {
          // Acción para iniciar nuevo chat (opcional)
        },
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

                        final timeLabel =
                        _formatTimeLabel(thread.lastMessageAt);

                        // Usamos otro widget pequeño para resolver el nombre desde Firestore
                        return StreamBuilder<DocumentSnapshot>(
                          stream: _db
                              .collection('users')
                              .doc(peerUid)
                              .snapshots(),
                          builder: (context, userSnap) {
                            String displayName = _fallbackName(peerUid);

                            if (userSnap.hasData &&
                                userSnap.data != null &&
                                userSnap.data!.data() != null) {
                              final data = userSnap.data!.data()
                              as Map<String, dynamic>;

                              // Tratamos de obtener el nombre de varios campos posibles
                              displayName = (data['fullName'] ??
                                  data['displayName'] ??
                                  data['name'] ??
                                  displayName) as String;
                            }

                            // Construimos el modelo que ya usa tu diseño
                            final preview = ChatPreview(
                              name: displayName,
                              lastMessage: thread.lastMessage,
                              timeLabel: timeLabel,
                              unreadCount: thread.unreadCount,
                              // isTyping no lo consultamos aún, así que lo dejamos en false
                              isTyping: false,
                            );

                            return ChatPreviewTile(
                              preview: preview,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ChatConversationPage(
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
