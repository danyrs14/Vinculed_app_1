import 'package:flutter/material.dart';
import 'package:vinculed_app_1/src/core/controllers/theme_controller.dart';
import 'package:vinculed_app_1/src/ui/widgets/textos/textos.dart';

/// Modelo para previsualizar una conversación en la lista de chats.
class ChatPreview {
  /// Nombre del contacto o chat.
  final String name;

  /// Último mensaje (o preview).
  final String lastMessage;

  /// Etiqueta de tiempo: "14:28", "ayer", "Viernes", "07/21/2022", etc.
  final String timeLabel;

  /// Cantidad de mensajes no leídos. Si es 0, no se muestra el badge.
  final int unreadCount;

  /// Si el contacto está escribiendo (pinta el subtítulo en color secundario).
  final bool isTyping;

  const ChatPreview({
    required this.name,
    required this.lastMessage,
    required this.timeLabel,
    this.unreadCount = 0,
    this.isTyping = false,
  });
}

/// Item visual para una fila de previsualización de chat.
class ChatPreviewTile extends StatelessWidget {
  const ChatPreviewTile({
    super.key,
    required this.preview,
    this.onTap,
    this.borderRadius = 10,
    this.verticalPadding = 10,
  });

  /// Datos a mostrar.
  final ChatPreview preview;

  /// Acción al tocar el tile (por ejemplo, navegar al chat).
  final VoidCallback? onTap;

  /// Estética del tile.
  final double borderRadius;
  final double verticalPadding;

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    String first = parts.first.isNotEmpty ? parts.first[0] : '';
    String last = parts.length > 1 && parts.last.isNotEmpty ? parts.last[0] : '';
    final ini = (first + last).toUpperCase();
    return ini.isEmpty ? '?' : ini;
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;

    final subtitleText = preview.isTyping
        ? Texto(
      text: '${preview.name.split(' ').first} esta escribiendo...',
      fontSize: 12,
    )
        : Texto(text: preview.lastMessage, fontSize: 12);

    return InkWell(
      borderRadius: BorderRadius.circular(borderRadius),
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: verticalPadding),
        decoration: BoxDecoration(
          color: theme.background(),
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: Row(
          children: [
            // Avatar con iniciales (no dependemos de assets)
            CircleAvatar(
              radius: 24,
              backgroundColor: theme.secundario().withOpacity(0.15),
              child: Text(
                _initials(preview.name),
                style: TextStyle(
                  color: theme.primario(),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Nombre y último mensaje
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Texto(text: preview.name, fontSize: 14),
                  const SizedBox(height: 2),
                  DefaultTextStyle.merge(
                    style: TextStyle(
                      color: preview.isTyping ? theme.secundario() : null,
                    ),
                    child: subtitleText,
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Hora / día y badge de no leídos
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  preview.timeLabel,
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 6),
                if (preview.unreadCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.secundario(),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      preview.unreadCount.toString(),
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  )
                else
                  const SizedBox(height: 18),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
