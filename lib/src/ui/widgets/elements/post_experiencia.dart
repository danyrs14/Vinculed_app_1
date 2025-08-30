import 'package:flutter/material.dart';
import 'package:vinculed_app_1/src/core/controllers/theme_controller.dart';

class ExperienceComment {
  final String avatarAsset;
  final String author;
  final String text;

  const ExperienceComment({
    required this.avatarAsset,
    required this.author,
    required this.text,
  });
}

class ExperiencePost extends StatelessWidget {
  const ExperiencePost({
    super.key,
    // Cabecera
    required this.authorName,
    required this.avatarAsset,
    this.subtitle = '',
    this.moreIcon = Icons.more_horiz,
    this.onMore,
    // Contenido
    required this.content,
    // Acciones
    this.likesLabel = 'Me gusta',
    this.commentsLabel = 'Comentar',
    this.onLike,
    this.onComment,
    this.commentCountText,
    // Comentarios (opcional)
    this.highlightComment,
    // Layout
    this.maxWidth = 520,
    this.padding = const EdgeInsets.all(16),
  });

  final String authorName;

  final String avatarAsset;

  final String subtitle;

  final String content;

  final String likesLabel;

  final String commentsLabel;

  final String? commentCountText;

  final ExperienceComment? highlightComment;

  final VoidCallback? onMore;

  final VoidCallback? onLike;

  final VoidCallback? onComment;

  final IconData moreIcon;

  final double maxWidth;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Container(
        decoration: BoxDecoration(
          color: theme.background(),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(radius: 20, backgroundImage: AssetImage(avatarAsset)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(authorName, style: const TextStyle(fontWeight: FontWeight.w800)),
                      if (subtitle.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(subtitle, style: const TextStyle(color: Colors.black54, fontSize: 12)),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onMore,
                  icon: Icon(moreIcon, color: Colors.black54),
                  tooltip: 'Más opciones',
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ── Contenido
            Text(content, textAlign: TextAlign.left),

            const SizedBox(height: 12),
            const Divider(height: 1),

            // ── Acciones
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  _ActionIcon(icon: Icons.favorite_border, label: likesLabel, onTap: onLike),
                  const SizedBox(width: 16),
                  _ActionIcon(icon: Icons.mode_comment_outlined, label: commentsLabel, onTap: onComment),
                  const Spacer(),
                  if (commentCountText != null)
                    Text(commentCountText!, style: const TextStyle(color: Colors.black54, fontSize: 12)),
                ],
              ),
            ),

            if (highlightComment != null) ...[
              const SizedBox(height: 12),
              _CommentBubble(
                avatar: highlightComment!.avatarAsset,
                name: highlightComment!.author,
                text: highlightComment!.text,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ActionIcon extends StatelessWidget {
  const _ActionIcon({
    required this.icon,
    required this.label,
    this.onTap,
    this.dense = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final child = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: dense ? 16 : 20, color: Colors.black87),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: dense ? 12 : 13.5,
            color: Colors.black87,
            fontWeight: dense ? FontWeight.w500 : FontWeight.w600,
          ),
        ),
      ],
    );

    if (onTap == null) return child;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: child,
      ),
    );
  }
}

class _CommentBubble extends StatelessWidget {
  const _CommentBubble({
    required this.avatar,
    required this.name,
    required this.text,
    this.footer,
  });

  final String avatar;
  final String name;
  final String text;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, right: 8),
          child: CircleAvatar(radius: 18, backgroundImage: AssetImage(avatar)),
        ),
        Flexible(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black12.withOpacity(.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.black12),
            ),
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(text),
                if (footer != null) ...[
                  const SizedBox(height: 6),
                  DefaultTextStyle(
                    style: const TextStyle(fontSize: 12, color: Colors.black87),
                    child: footer!,
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
