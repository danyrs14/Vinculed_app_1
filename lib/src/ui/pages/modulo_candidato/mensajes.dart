import 'package:flutter/material.dart';
import 'package:vinculed_app_1/src/core/controllers/theme_controller.dart';
import 'package:vinculed_app_1/src/ui/pages/modulo_candidato/chat.dart';
import 'package:vinculed_app_1/src/ui/widgets/elements_app/chat_preview.dart';
import 'package:vinculed_app_1/src/ui/widgets/textos/textos.dart';

class Mensajes extends StatelessWidget {
  const Mensajes({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;

    // Datos de ejemplo (sustituye por tus datos reales)
    final chats = <ChatPreview>[
      const ChatPreview(
        name: 'Luis Roberto Guzmán',
        lastMessage: 'Luis Roberto esta escribiendo...',
        isTyping: true,
        timeLabel: '14:28',
        unreadCount: 1,
      ),
      const ChatPreview(
        name: 'Andrés Manuel Lopez',
        lastMessage: 'Muchas Gracias, te confirmo.',
        timeLabel: 'ayer',
        unreadCount: 3,
      ),
      const ChatPreview(
        name: 'Kevin Alberto Flores',
        lastMessage: 'Te llamo en un momento.',
        timeLabel: 'ayer',
      ),
      const ChatPreview(
        name: 'Sandra Perez',
        lastMessage: 'Con el tema de la Vacante que...',
        timeLabel: 'Viernes',
      ),
      const ChatPreview(
        name: 'Samuel Gutierrez Vazquez',
        lastMessage: 'Claro con gusto.',
        timeLabel: '07/21/2022',
      ),
      const ChatPreview(
        name: 'Liliana Fuentes Valle',
        lastMessage: 'Al horario que tu me digas me...',
        timeLabel: '07/18/2022',
      ),
      const ChatPreview(
        name: 'Ana Regina Muñoz',
        lastMessage: 'Sin problema lo checamos.',
        timeLabel: '07/16/2022',
      ),
    ];

    return Scaffold(
      backgroundColor: theme.background(),
      // Solo contenido (tu AppBar y menú ya los tienes)
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

              // Lista de conversaciones
              Expanded(
                child: ListView.separated(
                  itemCount: chats.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 6),
                  itemBuilder: (context, i) {
                    final c = chats[i];
                    return ChatPreviewTile(
                      preview: c,
                      onTap: () {
                        // 👉 Navegar a la conversación
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatConversationPage(
                              contactName: c.name,
                              isTyping: c.isTyping,
                            ),
                          ),
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
