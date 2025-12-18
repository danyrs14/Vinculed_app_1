import 'package:flutter/material.dart';

class CommentComposer extends StatelessWidget {
  const CommentComposer({
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
          maxLength: 280,
          decoration: InputDecoration(
            hintText: 'Escribe un comentario...',
            isDense: true,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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

class RemoteReply {
  // Comentario directo a la publicación
  final int idComentario;
  final int idAlumno;
  final String nombre;
  final String urlFotoPerfil;
  final String comentario;
  final DateTime? fecha;
  final bool respuestas;
  RemoteReply({
    required this.idComentario,
    required this.idAlumno,
    required this.nombre,
    required this.urlFotoPerfil,
    required this.comentario,
    required this.fecha,
    required this.respuestas,
  });
  factory RemoteReply.fromJson(Map<String, dynamic> j) => RemoteReply(
        idComentario: (j['id_comentario'] as num?)?.toInt() ?? 0,
        idAlumno: (j['id_alumno'] as num?)?.toInt() ?? 0,
        nombre: (j['nombre'] ?? '').toString(),
        urlFotoPerfil: (j['url_foto_perfil'] ?? '').toString(),
        comentario: (j['comentario'] ?? '').toString(),
        fecha: DateTime.tryParse((j['fecha'] ?? '').toString()),
        respuestas: (j['respuestas'] == true),
      );
}

class RemoteCommentReply {
  // Respuesta a un comentario
  final int idComentario;
  final int idAlumno;
  final int idComentarioPadre;
  final String nombre;
  final String urlFotoPerfil;
  final String comentario;
  final DateTime? fecha;
  final bool respuestas;
  RemoteCommentReply({
    required this.idComentario,
    required this.idAlumno,
    required this.idComentarioPadre,
    required this.nombre,
    required this.urlFotoPerfil,
    required this.comentario,
    required this.fecha,
    required this.respuestas,
  });
  factory RemoteCommentReply.fromJson(Map<String, dynamic> j) =>
      RemoteCommentReply(
        idComentario: (j['id_comentario'] as num?)?.toInt() ?? 0,
        idAlumno: (j['id_alumno'] as num?)?.toInt() ?? 0,
        idComentarioPadre: (j['id_comentario_padre'] as num?)?.toInt() ?? 0,
        nombre: (j['nombre'] ?? '').toString(),
        urlFotoPerfil: (j['url_foto_perfil'] ?? '').toString(),
        comentario: (j['comentario'] ?? '').toString(),
        fecha: DateTime.tryParse((j['fecha'] ?? '').toString()),
        respuestas: (j['respuestas'] == true),
      );
}

class CommentBubble extends StatelessWidget {
  const CommentBubble({
    required this.avatar,
    required this.name,
    required this.text,
    this.showRepliesButton = false,
    this.onShowReplies,
    this.onReply,
    this.repliesButtonLabel,
    // Nuevos parámetros para opciones
    this.isOwner = false,
    this.onReport,
    this.onDelete,
  });

  final String avatar;
  final String name;
  final String text;
  final bool showRepliesButton;
  final VoidCallback? onShowReplies;
  final VoidCallback? onReply;
  final String? repliesButtonLabel;
  // Nuevos campos
  final bool isOwner;
  final VoidCallback? onReport;
  final VoidCallback? onDelete;

  Widget _defaultAvatarIcon(double size) {
    return Container(
      width: size,
      height: size,
      decoration:
          const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFE0E0E0)),
      alignment: Alignment.center,
      child: Icon(Icons.person, size: size * 0.6, color: Colors.grey.shade700),
    );
  }

  Widget _buildAvatar(String src, double radius) {
    final size = radius * 2;
    if (src.isEmpty) return _defaultAvatarIcon(size);
    if (src.startsWith('http')) {
      return ClipOval(
        child: Image.network(src,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _defaultAvatarIcon(size)),
      );
    }
    return ClipOval(
      child: Image.asset(src,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _defaultAvatarIcon(size)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, right: 8),
          child:
              SizedBox(width: 36, height: 36, child: _buildAvatar(avatar, 18)),
        ),
        Flexible(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white),
            ),
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.black12),
                    ),
                    child: Text(text)),
                if (showRepliesButton || onReply != null) ...[
                  const SizedBox(height: 6),
                  // Reemplazar Row por Wrap para evitar overflow horizontal
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    alignment: WrapAlignment.start,
                    children: [
                      if (showRepliesButton)
                        TextButton(
                          onPressed: onShowReplies,
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            minimumSize: const Size(0, 0),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            repliesButtonLabel ?? 'Mostrar respuestas',
                            overflow: TextOverflow.fade,
                            softWrap: true,
                          ),
                        ),
                      TextButton(
                        onPressed: onReply,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          minimumSize: const Size(0, 0),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text('Responder',
                            overflow: TextOverflow.fade, softWrap: true),
                      ),
                    ],
                  ),
                ],
              ], // cierre correcto de children
            ),
          ),
        ),
        // Menú de opciones al lado del comentario
        if (isOwner)
          PopupMenuButton<String>(
            color: Colors.white,
            icon: const Icon(Icons.more_vert, size: 20),
            padding: EdgeInsets.zero,
            tooltip: 'Opciones',
            onSelected: (value) {
              if (value == 'reportar' && onReport != null) {
                onReport!();
              } else if (value == 'eliminar' && onDelete != null) {
                onDelete!();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'reportar',
                child: Row(
                  children: [
                    Icon(Icons.flag_outlined, size: 18),
                    SizedBox(width: 8),
                    Text('Reportar'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'eliminar',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, size: 18, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Eliminar', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          )
        else if (onReport != null)
          IconButton(
            icon: const Icon(Icons.flag_outlined, size: 20),
            tooltip: 'Reportar',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: onReport,
          ),
      ],
    );
  }
}

class ReplyBubble extends StatelessWidget {
  final RemoteCommentReply reply;
  final String fallbackAvatar;
  final bool showRepliesButton;
  final VoidCallback? onShowReplies;
  final String? repliesButtonLabel;
  final VoidCallback? onReply;
  // Nuevos parámetros para opciones
  final bool isOwner;
  final VoidCallback? onReport;
  final VoidCallback? onDelete;

  const ReplyBubble({
    required this.reply,
    required this.fallbackAvatar,
    this.showRepliesButton = false,
    this.onShowReplies,
    this.repliesButtonLabel,
    this.onReply,
    this.isOwner = false,
    this.onReport,
    this.onDelete,
  });
  Widget _defaultAvatarIcon(double size) {
    return Container(
      width: size,
      height: size,
      decoration:
          const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFE0E0E0)),
      alignment: Alignment.center,
      child: Icon(Icons.person, size: size * 0.6, color: Colors.grey.shade700),
    );
  }

  Widget _buildAvatar(String src, double radius) {
    final size = radius * 2;
    if (src.isEmpty) return _defaultAvatarIcon(size);
    if (src.startsWith('http')) {
      return ClipOval(
        child: Image.network(src,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _defaultAvatarIcon(size)),
      );
    }
    return ClipOval(
      child: Image.asset(src,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _defaultAvatarIcon(size)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, right: 8),
          child: SizedBox(
              width: 32,
              height: 32,
              child: _buildAvatar(
                  reply.urlFotoPerfil.isNotEmpty ? reply.urlFotoPerfil : '',
                  16)),
        ),
        Flexible(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white),
            ),
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(reply.nombre,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 13)),
                const SizedBox(height: 4),
                Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.black12),
                    ),
                    child: Text(reply.comentario)),
                if (showRepliesButton || onReply != null) ...[
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    alignment: WrapAlignment.start,
                    children: [
                      if (showRepliesButton)
                        TextButton(
                          onPressed: onShowReplies,
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            minimumSize: const Size(0, 0),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            repliesButtonLabel ?? 'Mostrar respuestas',
                            overflow: TextOverflow.fade,
                            softWrap: true,
                          ),
                        ),
                      TextButton(
                        onPressed: onReply,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          minimumSize: const Size(0, 0),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text('Responder',
                            overflow: TextOverflow.fade, softWrap: true),
                      ),
                    ],
                  ),
                ],
              ], // cierre correcto de children
            ),
          ),
        ),
        // Menú de opciones al lado de la respuesta
        if (isOwner)
          PopupMenuButton<String>(
            color: Colors.white,
            icon: const Icon(Icons.more_vert, size: 18),
            padding: EdgeInsets.zero,
            tooltip: 'Opciones',
            onSelected: (value) {
              if (value == 'reportar' && onReport != null) {
                onReport!();
              } else if (value == 'eliminar' && onDelete != null) {
                onDelete!();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'reportar',
                child: Row(
                  children: [
                    Icon(Icons.flag_outlined, size: 18),
                    SizedBox(width: 8),
                    Text('Reportar'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'eliminar',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, size: 18, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Eliminar', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          )
        else if (onReport != null)
          IconButton(
            icon: const Icon(Icons.flag_outlined, size: 18),
            tooltip: 'Reportar',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: onReport,
          ),
      ],
    );
  }
}

class InlineReplyComposer extends StatelessWidget {
  final TextEditingController controller;
  final bool sending;
  final VoidCallback onCancel;
  final VoidCallback onSend;
  const InlineReplyComposer(
      {required this.controller,
      required this.sending,
      required this.onCancel,
      required this.onSend});
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: controller,
          maxLines: null,
          maxLength: 280,
          decoration: InputDecoration(
            hintText: 'Escribe una respuesta...',
            isDense: true,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            suffixIcon: IconButton(
              icon: sending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.send),
              onPressed: sending ? null : onSend,
              tooltip: 'Enviar',
            ),
          ),
        ),
        const SizedBox(height: 4),
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
