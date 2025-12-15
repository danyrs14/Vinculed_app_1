import 'package:flutter/material.dart';
import 'package:vinculed_app_1/src/core/controllers/theme_controller.dart';
import 'package:vinculed_app_1/src/ui/widgets/textos/textos.dart';

class ChatPreview {
  final String name;
  final String lastMessage;
  final String timeLabel;
  final int unreadCount;
  final bool isTyping;

  const ChatPreview({
    required this.name,
    required this.lastMessage,
    required this.timeLabel,
    this.unreadCount = 0,
    this.isTyping = false,
  });
}

class ChatPreviewTile extends StatelessWidget {
  const ChatPreviewTile({
    super.key,
    required this.preview,
    this.onTap,
    this.borderRadius = 10,
    this.verticalPadding = 10,
  });

  final ChatPreview preview;
  final VoidCallback? onTap;
  final double borderRadius;
  final double verticalPadding;

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    String first = parts.first.isNotEmpty ? parts.first[0] : '';
    String last =
    parts.length > 1 && parts.last.isNotEmpty ? parts.last[0] : '';
    final ini = (first + last).toUpperCase();
    return ini.isEmpty ? '?' : ini;
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;

    // Texto de subtítulo (escribiendo vs último mensaje)
    final subtitleText = preview.isTyping
        ? Texto(
      text: '${preview.name.split(' ').first} esta escribiendo...',
      fontSize: 12,
    )
        : Texto(text: preview.lastMessage, fontSize: 12);

    final bool hasNew = preview.unreadCount > 0;

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

            Expanded(
              child: DefaultTextStyle.merge(
                style: TextStyle(
                  fontWeight:
                  hasNew ? FontWeight.w600 : FontWeight.normal,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Texto(text: preview.name, fontSize: 14),
                    const SizedBox(height: 2),
                    DefaultTextStyle.merge(
                      style: TextStyle(
                        color:
                        preview.isTyping ? theme.secundario() : null,
                      ),
                      child: subtitleText,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  preview.timeLabel,
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 6),
                if (hasNew)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: theme.secundario(),
                      shape: BoxShape.circle,
                    ),
                    child: const Text(
                      '',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
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
