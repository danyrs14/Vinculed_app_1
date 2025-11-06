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

class ExperiencePost extends StatefulWidget {
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
    this.dislikesLabel = 'No me gusta',
    this.commentsLabel = 'Comentar',
    // Estado inicial opcional
    this.initialIsLiked = false,
    this.initialIsDisliked = false,
    this.initialShowComposer = false,
    // Callbacks
    this.onLike,
    this.onDislike,
    this.onCommentTap,
    this.onSubmitComment,
    this.commentCountText,
    // Comentarios (opcional)
    this.highlightComment,
    this.initialComments,                 // ← NUEVO: precargar comentarios
    // Autor del nuevo comentario (opcional)
    this.currentUserName = 'Tú',          // ← NUEVO
    this.currentUserAvatarAsset = 'assets/images/amlo.jpg', // ← NUEVO (pon tu default)
    // Layout
    this.maxWidth = 520,
    this.padding = const EdgeInsets.all(16),
  });

  final String authorName;
  final String avatarAsset;
  final String subtitle;
  final String content;

  final String likesLabel;
  final String dislikesLabel;
  final String commentsLabel;

  final bool initialIsLiked;
  final bool initialIsDisliked;
  final bool initialShowComposer;

  final String? commentCountText;

  final ExperienceComment? highlightComment;
  final List<ExperienceComment>? initialComments; // ← NUEVO

  final String currentUserName;                  // ← NUEVO
  final String currentUserAvatarAsset;           // ← NUEVO

  final VoidCallback? onMore;
  final VoidCallback? onLike;
  final VoidCallback? onDislike;
  final VoidCallback? onCommentTap;
  final ValueChanged<String>? onSubmitComment;

  final IconData moreIcon;

  final double maxWidth;
  final EdgeInsets padding;

  @override
  State<ExperiencePost> createState() => _ExperiencePostState();
}

class _ExperiencePostState extends State<ExperiencePost> {
  late bool _isLiked;
  late bool _isDisliked;
  late bool _showComposer;

  final TextEditingController _commentCtrl = TextEditingController();
  bool _sending = false;

  // Lista interna de comentarios que se quedan en la tarjeta
  late List<ExperienceComment> _comments; // ← NUEVO

  @override
  void initState() {
    super.initState();
    _isLiked = widget.initialIsLiked;
    _isDisliked = widget.initialIsDisliked;
    _showComposer = widget.initialShowComposer;
    _comments = List<ExperienceComment>.from(widget.initialComments ?? const []); // ← NUEVO
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  void _toggleLike() {
    setState(() {
      if (_isLiked) {
        _isLiked = false;
      } else {
        _isLiked = true;
        _isDisliked = false; // exclusividad
      }
    });
    widget.onLike?.call();
  }

  void _toggleDislike() {
    setState(() {
      if (_isDisliked) {
        _isDisliked = false;
      } else {
        _isDisliked = true;
        _isLiked = false; // exclusividad
      }
    });
    widget.onDislike?.call();
  }

  void _toggleComposer() {
    setState(() => _showComposer = !_showComposer);
    widget.onCommentTap?.call();
  }

  Future<void> _submitComment() async {
    final text = _commentCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() => _sending = true);
    try {
      // Notifica hacia fuera (opcional)
      widget.onSubmitComment?.call(text);

      // Agrega el comentario a la lista local para que se quede visible
      final newComment = ExperienceComment(
        avatarAsset: widget.currentUserAvatarAsset,
        author: widget.currentUserName,
        text: text,
      );
      setState(() {
        _comments.insert(0, newComment); // arriba del todo (o usa add para abajo)
      });

      // Limpia y cierra el composer (puedes dejarlo abierto si quieres)
      _commentCtrl.clear();
      setState(() => _showComposer = false);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;
    final accent = theme.primario(); // color de acento

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: widget.maxWidth),
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
        padding: widget.padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(radius: 20, backgroundImage: AssetImage(widget.avatarAsset)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.authorName, style: const TextStyle(fontWeight: FontWeight.w800)),
                      if (widget.subtitle.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(widget.subtitle, style: const TextStyle(color: Colors.black54, fontSize: 12)),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  onPressed: widget.onMore,
                  icon: Icon(widget.moreIcon, color: Colors.black54),
                  tooltip: 'Más opciones',
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ── Contenido
            Text(widget.content, textAlign: TextAlign.left),

            const SizedBox(height: 12),
            const Divider(height: 1),

            // ── Acciones
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  _ActionIcon(
                    icon: _isLiked ? Icons.favorite : Icons.favorite_border,
                    selected: _isLiked,
                    selectedColor: accent,
                    label: widget.likesLabel,
                    onTap: _toggleLike,
                  ),
                  const SizedBox(width: 16),
                  _ActionIcon(
                    icon: _isDisliked ? Icons.thumb_down_alt : Icons.thumb_down_off_alt_outlined,
                    selected: _isDisliked,
                    selectedColor: accent,
                    label: widget.dislikesLabel,
                    onTap: _toggleDislike,
                  ),
                  const SizedBox(width: 16),
                  _ActionIcon(
                    icon: Icons.mode_comment_outlined,
                    selected: _showComposer,
                    selectedColor: accent,
                    label: widget.commentsLabel,
                    onTap: _toggleComposer,
                  ),
                  const Spacer(),
                  if (widget.commentCountText != null)
                    Text(
                      widget.commentCountText!,
                      style: const TextStyle(color: Colors.black54, fontSize: 12),
                    ),
                ],
              ),
            ),

            // ── Composer de comentario (abre al tocar "Comentar")
            if (_showComposer) ...[
              const SizedBox(height: 10),
              _CommentComposer(
                controller: _commentCtrl,
                sending: _sending,
                onCancel: () => setState(() => _showComposer = false),
                onSend: _submitComment,
              ),
            ],

            // ── Comentario destacado (si lo hubiera)
            if (widget.highlightComment != null) ...[
              const SizedBox(height: 12),
              _CommentBubble(
                avatar: widget.highlightComment!.avatarAsset,
                name: widget.highlightComment!.author,
                text: widget.highlightComment!.text,
              ),
            ],

            // ── Comentarios que se van agregando y se quedan
            if (_comments.isNotEmpty) ...[
              const SizedBox(height: 12),
              ..._comments.map((c) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: _CommentBubble(
                  avatar: c.avatarAsset,
                  name: c.author,
                  text: c.text,
                ),
              )),
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
    this.selected = false,
    this.selectedColor,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool dense;

  final bool selected;
  final Color? selectedColor;

  @override
  Widget build(BuildContext context) {
    final baseColor = Colors.black87;
    final color = selected ? (selectedColor ?? baseColor) : baseColor;
    final fontWeight = selected ? FontWeight.w700 : FontWeight.w600;

    final child = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: dense ? 16 : 20, color: color),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: dense ? 12 : 13.5,
            color: color,
            fontWeight: fontWeight,
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

class _CommentComposer extends StatelessWidget {
  const _CommentComposer({
    required this.controller,
    required this.onSend,
    required this.onCancel,
    required this.sending,
  });

  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback onCancel;
  final bool sending;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: controller,
          maxLines: null,
          decoration: InputDecoration(
            hintText: 'Escribe un comentario...',
            isDense: true,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            suffixIcon: IconButton(
              icon: sending
                  ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
                  : const Icon(Icons.send),
              onPressed: sending ? null : onSend,
              tooltip: 'Enviar',
            ),
          ),
        ),
        const SizedBox(height: 6),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: sending ? null : onCancel,
            icon: const Icon(Icons.close),
            label: const Text('Cancelar'),
          ),
        ),
      ],
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
