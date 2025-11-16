import 'package:flutter/material.dart';
import 'package:vinculed_app_1/src/core/controllers/theme_controller.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:vinculed_app_1/src/core/providers/user_provider.dart';
import 'package:vinculed_app_1/src/ui/widgets/elements/formulario_reporte.dart';
import 'package:vinculed_app_1/src/ui/widgets/elements/media.dart';

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
    this.mediaUrl,
    // Acciones
    this.likesLabel = 'Me gusta',
    this.dislikesLabel = 'No me gusta',
    this.commentsLabel = 'Comentar',
    // Estado inicial opcional
    this.initialIsLiked = false,
    this.initialIsDisliked = false,
    this.initialShowComposer = false,
    // Reacciones
    this.initialLikesCount = 0,
    required this.idPublicacion,
    required this.idAlumno,
    // Comentarios totales (para decidir mostrar botón Ver comentarios)
    this.totalComments = 0,
    // Callbacks
    this.onLike,
    this.onDislike,
    this.onCommentTap,
    this.onSubmitComment,
    this.commentCountText,
    // Comentarios (opcional)
    this.highlightComment,
    this.initialComments,
    // Autor del nuevo comentario (opcional)
    this.currentUserName = 'Tú',
    this.currentUserAvatarAsset = 'assets/images/amlo.jpg',
    // Layout
    this.maxWidth = 520,
    this.padding = const EdgeInsets.all(16),
  });

  final String authorName;
  final String avatarAsset;
  final String subtitle;
  final String content;
  final String? mediaUrl;

  final String likesLabel;
  final String dislikesLabel;
  final String commentsLabel;

  final bool initialIsLiked;
  final bool initialIsDisliked;
  final bool initialShowComposer;

  final int initialLikesCount; // nuevo campo
  final int idPublicacion; // nuevo campo
  final int idAlumno; // nuevo campo

  final int totalComments; // nuevo

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
  late int _likesCount; // nuevo contador dinámico
  bool _sendingReaction = false; // bandera para evitar doble clic spam

  // Comentarios remotos
  List<_RemoteReply> _remoteComments = [];
  bool _commentsLoaded = false;
  bool _loadingComments = false;
  String _commentsError = '';
  bool _showRemoteComments = false; // permitir ocultar/mostrar

  // --- Respuestas de comentarios ---
  final Map<int, List<_RemoteCommentReply>> _replies = {}; // id_comentario -> lista de respuestas
  final Set<int> _loadingReplies = {}; // ids que están cargando
  final Set<int> _expandedReplies = {}; // ids de comentarios que se expandieron
  final Map<int, String> _repliesError = {}; // errores por comentario

  // Nueva variable para manejar el composer de respuestas inline
  int? _replyingTo; // id del comentario/respuesta al que se está respondiendo
  final TextEditingController _replyCtrl = TextEditingController();
  bool _sendingReply = false;

  @override
  void initState() {
    super.initState();
    _isLiked = widget.initialIsLiked;
    _isDisliked = widget.initialIsDisliked;
    _showComposer = widget.initialShowComposer;
    _comments = List<ExperienceComment>.from(widget.initialComments ?? const []); // ← NUEVO
    _likesCount = widget.initialLikesCount; // inicializar
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    _replyCtrl.dispose();
    super.dispose();
  }

  Future<void> _postReaction({required String tipo, required String accion}) async {
    if (_sendingReaction) return;
    setState(() => _sendingReaction = true);
    try {
      final userProv = Provider.of<UserDataProvider>(context, listen: false);
      final headers = await userProv.getAuthHeaders();
      final body = jsonEncode({
        'id_publicacion': widget.idPublicacion,
        'id_alumno': widget.idAlumno,
        'tipo_reaccion': tipo,
        'accion': accion,
      });
      final res = await http.post(
        Uri.parse('http://localhost:3000/api/experiencias_alumnos/reaccionar'),
        headers: headers,
        body: body,
      );
      if (res.statusCode < 200 || res.statusCode >= 300) {
        // Revertir si falla
        // ignore: avoid_print
        print('Error al reaccionar: ${res.statusCode} ${res.body}');
        _revertLastReaction(tipo, accion);
      }
    } catch (e) {
      // ignore: avoid_print
      print('Excepción al reaccionar: $e');
      _revertLastReaction(tipo, accion);
    } finally {
      if (mounted) setState(() => _sendingReaction = false);
    }
  }

  void _revertLastReaction(String tipo, String accion) {
    setState(() {
      if (tipo == 'upvote') {
        if (accion == 'agregar') {
          // Se intentó agregar pero falló
          _isLiked = false;
          _likesCount = (_likesCount - 1).clamp(0, 1 << 30);
        } else {
          // Se intentó quitar pero falló
          _isLiked = true;
          _likesCount++;
        }
      } else if (tipo == 'downvote') {
        if (accion == 'agregar') {
          _isDisliked = false;
        } else {
          _isDisliked = true;
        }
      }
    });
  }

  void _toggleLike() {
    if (_sendingReaction) return; // evitar spam
    final wasLiked = _isLiked;
    final wasDisliked = _isDisliked;
    final accion = wasLiked ? 'quitar' : 'agregar';
    setState(() {
      if (wasLiked) {
        _isLiked = false;
        _likesCount = (_likesCount - 1);
      } else {
        _isLiked = true;
        _likesCount++;
        _isDisliked = false; // exclusividad
      }
    });
    widget.onLike?.call();
    _postReaction(tipo: 'upvote', accion: accion);
    // Si antes estaba en downvote y ahora pasamos a upvote, opcionalmente podríamos quitar el downvote explícitamente.
    if (wasDisliked && !wasLiked) {
      // Dependiendo backend puede no ser necesario. Opcional: enviar quitar downvote.
      // _postReaction(tipo: 'downvote', accion: 'quitar');
    }
  }

  void _toggleDislike() {
    if (_sendingReaction) return;
    final wasDisliked = _isDisliked;
    final wasLiked = _isLiked;
    final accion = wasDisliked ? 'quitar' : 'agregar';
    setState(() {
      if (wasDisliked) {
        _isDisliked = false;
        _likesCount++;
      } else {
        _isDisliked = true;
        _likesCount = (_likesCount - 1);
        if (wasLiked) {
          _isLiked = false;
        }
      }
    });
    widget.onDislike?.call();
    _postReaction(tipo: 'downvote', accion: accion);
  }

  void _toggleComposer() {
    setState(() => _showComposer = !_showComposer);
    widget.onCommentTap?.call();
  }

  Future<void> _submitComment() async {
    final raw = _commentCtrl.text.trim();
    if (raw.isEmpty) return;
    // Limitar a 280 caracteres
    final text = raw.length > 280 ? raw.substring(0, 280) : raw;
    setState(() => _sending = true);
    try {
      final userProv = Provider.of<UserDataProvider>(context, listen: false);
      final headers = await userProv.getAuthHeaders();
      final body = jsonEncode({
        'id_publicacion': widget.idPublicacion,
        'id_alumno': widget.idAlumno,
        'comentario': text,
      });
      final res = await http.post(
        Uri.parse('http://localhost:3000/api/experiencias_alumnos/comentar'),
        headers: headers,
        body: body,
      );
      if (res.statusCode >= 200 && res.statusCode < 300) {
        // Notifica hacia fuera (opcional)
        widget.onSubmitComment?.call(text);
        // Agrega comentario local para feedback inmediato
        final newComment = ExperienceComment(
          avatarAsset: widget.currentUserAvatarAsset,
          author: widget.currentUserName,
          text: text,
        );
        setState(() {
          _comments.insert(0, newComment);
        });
        _commentCtrl.clear();
        setState(() => _showComposer = false);
      } else {
        // ignore: avoid_print
        print('Error al comentar: ${res.statusCode} ${res.body}');
      }
    } catch (e) {
      // ignore: avoid_print
      print('Excepción al comentar: $e');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _fetchComments() async {
    if (_loadingComments || _commentsLoaded) {
      setState(() => _showRemoteComments = true);
      return;
    }
    setState(() {
      _loadingComments = true;
      _commentsError = '';
      _showRemoteComments = true;
    });
    try {
      final userProv = Provider.of<UserDataProvider>(context, listen: false);
      final headers = await userProv.getAuthHeaders();
      final url = Uri.parse('http://localhost:3000/api/experiencias_alumnos/comentarios').replace(queryParameters: {
        'id_alumno': '${widget.idAlumno}',
        'id_publicacion': '${widget.idPublicacion}',
      });
      final res = await http.get(url, headers: headers);
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final data = jsonDecode(res.body);
        if (data is List) {
          _remoteComments = data.map((e) => _RemoteReply.fromJson(e as Map<String, dynamic>)).toList();
        } else {
          _commentsError = 'Formato inesperado';
        }
        _commentsLoaded = true;
      } else {
        _commentsError = 'Error ${res.statusCode}';
      }
    } catch (e) {
      _commentsError = 'Error: $e';
    } finally {
      _loadingComments = false;
      if (mounted) setState(() {});
    }
  }

  Future<void> _fetchRepliesFor(int idComentario) async {
    if (_loadingReplies.contains(idComentario)) return; // evitar doble fetch
    setState(() { _loadingReplies.add(idComentario); _repliesError.remove(idComentario); });
    try {
      final userProv = Provider.of<UserDataProvider>(context, listen: false);
      final headers = await userProv.getAuthHeaders();
      final url = Uri.parse('http://localhost:3000/api/experiencias_alumnos/comentarios/respuestas').replace(queryParameters: {
        'id_comentario_padre': '$idComentario',
        'id_alumno': '${widget.idAlumno}',
      });
      final res = await http.get(url, headers: headers);
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final data = jsonDecode(res.body);
        if (data is List) {
          final list = data.map((e) => _RemoteCommentReply.fromJson(e as Map<String,dynamic>)).toList();
          _replies[idComentario] = list;
        } else {
          _repliesError[idComentario] = 'Formato inesperado';
        }
      } else {
        _repliesError[idComentario] = 'Error ${res.statusCode}';
      }
    } catch (e) {
      _repliesError[idComentario] = 'Error: $e';
    } finally {
      _loadingReplies.remove(idComentario);
      if (mounted) setState(() {});
    }
  }

  void _toggleReplies(_RemoteReply rc) {
    final id = rc.idComentario;
    _toggleRepliesById(id);
  }

  void _toggleRepliesById(int idComentario) {
    if (_expandedReplies.contains(idComentario)) {
      setState(() { _expandedReplies.remove(idComentario); });
    } else {
      setState(() { _expandedReplies.add(idComentario); });
      if (!_replies.containsKey(idComentario)) {
        _fetchRepliesFor(idComentario);
      }
    }
  }

  List<Widget> _buildReplyTree(_RemoteCommentReply reply, int depth) {
    const double baseIndent = 42.0;
    final double indent = baseIndent * depth;

    return [
      Padding(
        padding: EdgeInsets.only(left: indent, bottom: 8),
        child: _ReplyBubble(
          reply: reply,
          fallbackAvatar: widget.currentUserAvatarAsset,
          showRepliesButton: reply.respuestas,
          onShowReplies: reply.respuestas ? () => _toggleRepliesById(reply.idComentario) : null,
          repliesButtonLabel: _expandedReplies.contains(reply.idComentario) ? 'Ocultar respuestas' : 'Mostrar respuestas',
          onReply: () => _startReply(reply.idComentario),
        ),
      ),
      if (_replyingTo == reply.idComentario)
        Padding(
          padding: EdgeInsets.only(left: indent + 24, bottom: 8),
          child: _InlineReplyComposer(
            controller: _replyCtrl,
            sending: _sendingReply,
            onCancel: _cancelReply,
            onSend: _submitReply,
          ),
        ),
      if (_expandedReplies.contains(reply.idComentario)) ...[
        if (_loadingReplies.contains(reply.idComentario))
          Padding(
            padding: EdgeInsets.only(left: indent + 24, bottom: 8),
            child: const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)),
          )
        else if (_repliesError.containsKey(reply.idComentario))
          Padding(
            padding: EdgeInsets.only(left: indent + 24, bottom: 8),
            child: Text(_repliesError[reply.idComentario]!, style: const TextStyle(color: Colors.red)),
          )
        else ...[
          if ((_replies[reply.idComentario] ?? const []).isEmpty)
            Padding(
              padding: EdgeInsets.only(left: indent + 24, bottom: 8),
              child: const Text('No hay respuestas'),
            )
          else ...(_replies[reply.idComentario] ?? const <_RemoteCommentReply>[])
              .expand((child) => _buildReplyTree(child, depth + 1)),
        ],
      ],
    ];
  }

  void _startReply(int idComentario) {
    setState(() {
      _replyingTo = idComentario;
    });
  }

  void _cancelReply() {
    setState(() {
      _replyingTo = null;
      _replyCtrl.clear();
    });
  }

  Future<void> _submitReply() async {
    final parentId = _replyingTo;
    if (parentId == null) return;
    final raw = _replyCtrl.text.trim();
    if (raw.isEmpty) return;
    final text = raw.length > 280 ? raw.substring(0, 280) : raw;
    setState(() => _sendingReply = true);
    try {
      final userProv = Provider.of<UserDataProvider>(context, listen: false);
      final headers = await userProv.getAuthHeaders();
      final body = jsonEncode({
        'id_publicacion': widget.idPublicacion,
        'id_alumno': widget.idAlumno,
        'comentario': text,
        'id_comentario_padre': parentId,
      });
      final res = await http.post(Uri.parse('http://localhost:3000/api/experiencias_alumnos/comentar'), headers: headers, body: body);
      if (res.statusCode >= 200 && res.statusCode < 300) {
        _RemoteCommentReply parsed;
        try {
          final data = jsonDecode(res.body);
          if (data is Map<String, dynamic>) {
            // Parse, but the backend might not return all fields.
            parsed = _RemoteCommentReply.fromJson(data);
          } else {
            // Non-map response, create an empty parsed to use fallbacks below.
            parsed = _RemoteCommentReply(
              idComentario: 0,
              idAlumno: 0,
              idComentarioPadre: 0,
              nombre: '',
              urlFotoPerfil: '',
              comentario: '',
              fecha: null,
              respuestas: false,
            );
          }
        } catch (_) {
          // If response is not JSON or unexpected, fallback to local values
          parsed = _RemoteCommentReply(
            idComentario: 0,
            idAlumno: 0,
            idComentarioPadre: 0,
            nombre: '',
            urlFotoPerfil: '',
            comentario: '',
            fecha: null,
            respuestas: false,
          );
        }

        // Build a normalized reply, preferring server data when available, otherwise local fallbacks
        final normalized = _RemoteCommentReply(
          idComentario: parsed.idComentario != 0 ? parsed.idComentario : DateTime.now().millisecondsSinceEpoch,
          idAlumno: parsed.idAlumno != 0 ? parsed.idAlumno : widget.idAlumno,
          idComentarioPadre: parsed.idComentarioPadre != 0 ? parsed.idComentarioPadre : parentId,
          nombre: (parsed.nombre.isNotEmpty) ? parsed.nombre : widget.currentUserName,
          urlFotoPerfil: (parsed.urlFotoPerfil.isNotEmpty) ? parsed.urlFotoPerfil : widget.currentUserAvatarAsset,
          comentario: (parsed.comentario.isNotEmpty) ? parsed.comentario : text,
          fecha: parsed.fecha ?? DateTime.now(),
          respuestas: parsed.respuestas,
        );

        setState(() {
          _replies.putIfAbsent(parentId, () => []);
          _replies[parentId]!.insert(0, normalized);
          _expandedReplies.add(parentId);
          _replyCtrl.clear();
          _replyingTo = null;
        });
      } else {
        // ignore: avoid_print
        print('Error al enviar respuesta: ${res.statusCode} ${res.body}');
      }
    } catch (e) {
      // ignore: avoid_print
      print('Excepción al enviar respuesta: $e');
    } finally {
      if (mounted) setState(() => _sendingReply = false);
    }
  }

  void _onCommentsButtonPressed() {
    if (!_commentsLoaded) {
      _fetchComments();
    } else {
      setState(() {
        _showRemoteComments = !_showRemoteComments;
      });
    }
  }

  Future<void> _openReportDialog() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => ReportContentDialog(
        idAlumno: widget.idAlumno,
        idContenido: widget.idPublicacion,
        tipoContenidoInicial: 'Publicacion',
      ),
    );
    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reporte enviado correctamente. Lo revisaremos.')),
      );
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
                CircleAvatar(
                  radius: 20,
                  backgroundImage: widget.avatarAsset.startsWith('http')
                      ? NetworkImage(widget.avatarAsset)
                      : AssetImage(widget.avatarAsset) as ImageProvider,
                ),
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
                  onPressed: _openReportDialog,
                  icon: const Icon(Icons.flag_outlined, color: Colors.black54),
                  tooltip: 'Reportar',
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ── Contenido
            Text(widget.content, textAlign: TextAlign.left),

            // ── Media (opcional)
            if ((widget.mediaUrl ?? '').isNotEmpty) ...[
              const SizedBox(height: 12),
              MediaContent(url: widget.mediaUrl!),
            ],

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
                    label: 'Me gusta · $_likesCount',
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
            // Botón Ver comentarios dentro del contenedor
            if (widget.totalComments > 0 && !_showComposer) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.blue,
                    side: const BorderSide(color: Colors.blue),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  onPressed: _onCommentsButtonPressed,
                  child: Text(_showRemoteComments ? 'Ocultar comentarios' : 'Ver comentarios'),
                ),
              ),
            ],
            // ── Composer de comentario (abre al tocar "Comentar")
            if (_showComposer) ...[
              const SizedBox(height: 12),
              _CommentComposer(
                controller: _commentCtrl,
                sending: _sending,
                onCancel: () => setState(() => _showComposer = false),
                onSend: _submitComment,
              ),
              const SizedBox(height: 8),
            ],
            // Sección de comentarios remotos
            if (_showRemoteComments) ...[
              const SizedBox(height: 8),
              if (_loadingComments)
                const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 8), child: CircularProgressIndicator()))
              else if (_commentsError.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(_commentsError, style: const TextStyle(color: Colors.red)),
                )
              else if (_remoteComments.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Text('No hay comentarios'),
                )
              else ...[
                ..._remoteComments.map((rc) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _CommentBubble(
                            avatar: rc.urlFotoPerfil.isEmpty ? widget.currentUserAvatarAsset : rc.urlFotoPerfil,
                            name: rc.nombre,
                            text: rc.comentario,
                            showRepliesButton: rc.respuestas,
                            onShowReplies: rc.respuestas ? () => _toggleReplies(rc) : null,
                            onReply: () => _startReply(rc.idComentario),
                            repliesButtonLabel: _expandedReplies.contains(rc.idComentario) ? 'Ocultar respuestas' : 'Mostrar respuestas',
                          ),
                          if (_replyingTo == rc.idComentario) ...[
                            Padding(
                              padding: const EdgeInsets.only(left: 42, top: 6, bottom: 6),
                              child: _InlineReplyComposer(
                                controller: _replyCtrl,
                                sending: _sendingReply,
                                onCancel: _cancelReply,
                                onSend: _submitReply,
                              ),
                            ),
                          ],
                          if (_expandedReplies.contains(rc.idComentario)) ...[
                            const SizedBox(height: 6),
                            if (_loadingReplies.contains(rc.idComentario))
                              const Padding(
                                padding: EdgeInsets.only(left: 42, bottom: 8),
                                child: SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                              )
                            else if (_repliesError.containsKey(rc.idComentario))
                              Padding(
                                padding: const EdgeInsets.only(left: 42, bottom: 8),
                                child: Text(_repliesError[rc.idComentario]!, style: const TextStyle(color: Colors.red)),
                              )
                            else ...[
                              if ((_replies[rc.idComentario] ?? const []).isEmpty)
                                const Padding(
                                  padding: EdgeInsets.only(left: 42, bottom: 8),
                                  child: Text('No hay respuestas'),
                                )
                              else ...(_replies[rc.idComentario] ?? const <_RemoteCommentReply>[])
                                  .expand((r) => _buildReplyTree(r, 1)),
                            ],
                          ],
                        ],
                      ),
                    )),
              ],
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
    this.selected = false,
    this.selectedColor,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
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
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 13.5,
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
          maxLength: 280,
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

class _RemoteReply { // Comentario directo a la publicación
  final int idComentario;
  final int idAlumno;
  final String nombre;
  final String urlFotoPerfil;
  final String comentario;
  final DateTime? fecha;
  final bool respuestas;
  _RemoteReply({
    required this.idComentario,
    required this.idAlumno,
    required this.nombre,
    required this.urlFotoPerfil,
    required this.comentario,
    required this.fecha,
    required this.respuestas,
  });
  factory _RemoteReply.fromJson(Map<String, dynamic> j) => _RemoteReply(
        idComentario: (j['id_comentario'] as num?)?.toInt() ?? 0,
        idAlumno: (j['id_alumno'] as num?)?.toInt() ?? 0,
        nombre: (j['nombre'] ?? '').toString(),
        urlFotoPerfil: (j['url_foto_perfil'] ?? '').toString(),
        comentario: (j['comentario'] ?? '').toString(),
        fecha: DateTime.tryParse((j['fecha'] ?? '').toString()),
        respuestas: (j['respuestas'] == true),
      );
}

class _RemoteCommentReply { // Respuesta a un comentario
  final int idComentario;
  final int idAlumno;
  final int idComentarioPadre;
  final String nombre;
  final String urlFotoPerfil;
  final String comentario;
  final DateTime? fecha;
  final bool respuestas;
  _RemoteCommentReply({
    required this.idComentario,
    required this.idAlumno,
    required this.idComentarioPadre,
    required this.nombre,
    required this.urlFotoPerfil,
    required this.comentario,
    required this.fecha,
    required this.respuestas,
  });
  factory _RemoteCommentReply.fromJson(Map<String,dynamic> j) => _RemoteCommentReply(
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

class _CommentBubble extends StatelessWidget {
  const _CommentBubble({
    required this.avatar,
    required this.name,
    required this.text,
    this.showRepliesButton = false,
    this.onShowReplies,
    this.onReply,
    this.repliesButtonLabel,
  });

  final String avatar;
  final String name;
  final String text;
  final bool showRepliesButton;
  final VoidCallback? onShowReplies;
  final VoidCallback? onReply;
  final String? repliesButtonLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, right: 8),
          child: CircleAvatar(
            radius: 18,
            backgroundImage: avatar.startsWith('http') ? NetworkImage(avatar) : AssetImage(avatar) as ImageProvider,
          ),
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
                  Row(
                    children: [
                      if (showRepliesButton)
                        TextButton(
                          onPressed: onShowReplies,
                          style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4)),
                          child: Text(repliesButtonLabel ?? 'Mostrar respuestas'),
                        ),
                      TextButton(
                        onPressed: onReply,
                        style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4)),
                        child: const Text('Responder'),
                      ),
                    ],
                  ),
                ],
              ], // cierre correcto de children
            ),
          ),
        ),
      ],
    );
  }
}

class _ReplyBubble extends StatelessWidget {
  final _RemoteCommentReply reply;
  final String fallbackAvatar;
  final bool showRepliesButton;
  final VoidCallback? onShowReplies;
  final String? repliesButtonLabel;
  final VoidCallback? onReply;
  const _ReplyBubble({
    required this.reply,
    required this.fallbackAvatar,
    this.showRepliesButton = false,
    this.onShowReplies,
    this.repliesButtonLabel,
    this.onReply,
  });
  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, right: 8),
          child: CircleAvatar(
            radius: 16,
            backgroundImage: reply.urlFotoPerfil.isNotEmpty && reply.urlFotoPerfil.startsWith('http')
                ? NetworkImage(reply.urlFotoPerfil)
                : AssetImage(fallbackAvatar) as ImageProvider,
          ),
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
                Text(reply.nombre, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
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
                  Row(
                    children: [
                      if (showRepliesButton)
                        TextButton(
                          onPressed: onShowReplies,
                          style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4)),
                          child: Text(repliesButtonLabel ?? 'Mostrar respuestas'),
                        ),
                      TextButton(
                        onPressed: onReply,
                        style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4)),
                        child: const Text('Responder'),
                      ),
                    ],
                  ),
                ],
              ], // cierre correcto de children
            ),
          ),
        ),
      ],
    );
  }
}

class _InlineReplyComposer extends StatelessWidget {
  final TextEditingController controller;
  final bool sending;
  final VoidCallback onCancel;
  final VoidCallback onSend;
  const _InlineReplyComposer({required this.controller, required this.sending, required this.onCancel, required this.onSend});
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
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            suffixIcon: IconButton(
              icon: sending
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
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

