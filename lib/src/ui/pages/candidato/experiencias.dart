import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:vinculed_app_1/src/core/providers/user_provider.dart';
import 'package:vinculed_app_1/src/core/controllers/theme_controller.dart';
import 'package:vinculed_app_1/src/ui/widgets/text_inputs/roles_multi_dropdown.dart';
import 'package:vinculed_app_1/src/ui/widgets/elements/post_experiencia.dart';
import 'package:vinculed_app_1/src/ui/pages/candidato/crear_experiencia.dart';

class Experiencias extends StatefulWidget {
  const Experiencias({super.key});
  @override
  State<Experiencias> createState() => _ExperienciasState();
}

class _ExperienciasState extends State<Experiencias> {
  final _scrollCtrl = ScrollController();
  final usuario = FirebaseAuth.instance.currentUser;

  // Datos remotos
  final List<Map<String, dynamic>> _items = [];
  int _page = 1;
  int _totalPages = 1;
  bool _loading = false; // primera carga / recarga filtro
  bool _loadingMore = false; // paginación incremental
  bool _initialized = false;
  int? _idAlumno;

  // Filtro roles
  List<int> _selectedRoleIds = [];

  // Ocultar media cuando dropdown/modal abierto
  bool _anyModalOpen = false;

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_handleScroll);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _initLoad());
    }
  }

  @override
  void dispose() {
    _scrollCtrl..removeListener(_handleScroll)..dispose();
    super.dispose();
  }

  Future<void> _initLoad() async {
    final userProv = Provider.of<UserDataProvider>(context, listen: false);
    final id = userProv.idRol;
    if (id == null) return; // esperar a que esté disponible
    _idAlumno = id;
    setState(() { _loading = true; _items.clear(); _page = 1; });
    await _fetchPage(1);
    if (!mounted) return;
    setState(() { _initialized = true; _loading = false; });
  }

  Future<void> _fetchPage(int page) async {
    if (_idAlumno == null) return;
    if (page > 1) setState(() => _loadingMore = true);
    try {
      final userProv = Provider.of<UserDataProvider>(context, listen: false);
      final headers = await userProv.getAuthHeaders();
      final params = <String, String>{
        'id_alumno': '$_idAlumno',
        'page': '$page',
        'limit': '10',
      };
      if (_selectedRoleIds.isNotEmpty) {
        params['id_roltrabajo'] = _selectedRoleIds.join(',');
      }
      final url = Uri.parse('https://oda-talent-back-81413836179.us-central1.run.app/api/experiencias_alumnos/ver').replace(queryParameters: params);
      final res = await http.get(url, headers: headers);
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        final pag = body['paginacion'] as Map<String, dynamic>?;
        final list = (body['experiencias'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
        setState(() {
          _page = page;
          if (pag != null) {
            _totalPages = (pag['total_paginas'] as num?)?.toInt() ?? _totalPages;
          }
          _items.addAll(list);
        });
      } else {
        // ignore: avoid_print
        print('Error ${res.statusCode} al cargar experiencias');
      }
    } catch (e) {
      // ignore: avoid_print
      print('Excepción al cargar experiencias: $e');
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  Future<void> _applyRoleFilter(List<RoleOption> roles) async {
    _selectedRoleIds = roles.map((r) => r.id).toList();
    setState(() { _loading = true; _items.clear(); _page = 1; _totalPages = 1; });
    await _fetchPage(1);
    if (mounted) setState(() => _loading = false);
  }

  void _handleScroll() {
    if (!_scrollCtrl.hasClients) return;
    final pos = _scrollCtrl.position;
    if (!pos.hasPixels || !pos.hasContentDimensions) return;
    final atBottom = pos.pixels >= (pos.maxScrollExtent - 4);
    if (atBottom && !_loadingMore && _page < _totalPages) {
      _fetchPage(_page + 1);
    }
  }

  String _two(int v) => v.toString().padLeft(2, '0');
  String _formatDate(DateTime dt) {
    final d = dt.toLocal();
    return '${d.year}-${_two(d.month)}-${_two(d.day)} ${_two(d.hour)}:${_two(d.minute)}';
  }

  Widget _buildPost(Map<String, dynamic> e, bool isMobile) {
    final autor = (e['nombre'] ?? '').toString();
    final avatar = (e['url_foto_perfil'] ?? '').toString();
    final contenido = (e['contenido'] ?? '').toString();
    final titulo = (e['titulo'] ?? '').toString();
    final fechaStr = (e['fecha_publicacion'] ?? '').toString();
    final dt = DateTime.tryParse(fechaStr);
    final roles = (e['roles_relacionados'] as List<dynamic>? ?? [])
        .map((x) => (x as Map<String, dynamic>)['nombre'])
        .whereType<String>()
        .toList();
    final subtitle = [
      if (dt != null) _formatDate(dt),
      if (roles.length == 1) 'Rol:',
      if (roles.length > 1) 'Roles:',
      if (roles.isNotEmpty) roles.join(', '),
    ].join(' · ');

    final reacciones = (e['reacciones'] as num?)?.toInt() ?? 0;
    final comentarios = (e['comentarios'] as num?)?.toInt() ?? 0;
    final miReaccion = (e['mi_reaccion'])?.toString();
    final isLiked = miReaccion == 'upvote';
    final isDisliked = miReaccion == 'downvote';

    return Column(
      children: [
        ExperiencePost(
          authorName: autor.isEmpty ? 'Anónimo' : autor,
          avatarAsset: avatar.isEmpty ? 'assets/images/amlo.jpg' : avatar,
          currentUserAvatarAsset: usuario?.photoURL ?? '',
          subtitle: subtitle,
          content: titulo.isEmpty ? contenido : '$titulo\n\n$contenido',
          initialLikesCount: reacciones,
          idPublicacion: (e['id_publicacion'] as num?)?.toInt() ?? 0,
          idAlumno: _idAlumno ?? 0,
          initialIsLiked: isLiked,
          initialIsDisliked: isDisliked,
          commentCountText: comentarios > 0 ? '$comentarios Comentarios' : null,
            totalComments: comentarios,
          maxWidth: 560,
          mediaUrl: e['url_multimedia'] as String?,
          hideMediaOverlays: _anyModalOpen,
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;
    final w = MediaQuery.of(context).size.width;
    final isMobile = w < 720;

    return Scaffold(
      backgroundColor: theme.background(),
      body: SafeArea(
        child: SingleChildScrollView(
          controller: _scrollCtrl,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Encabezado: back + título + crear
              Row(
                children: [
                  // IconButton(
                  //   tooltip: 'Regresar',
                  //   onPressed: () => Navigator.maybePop(context),
                  //   icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                  // ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Experiencias',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: isMobile ? 24 : 28,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF22313F),
                      ),
                    ),
                  ),
                  Material(
                    color: theme.secundario(),
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const CreateExperiencePage()),
                        );
                      },
                      child: const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Icon(Icons.add, color: Colors.white, size: 22),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Filtro roles y botón crear (solo filtro aquí porque botón ya arriba)
              RolesMultiDropdown(
                label: 'Filtrar por roles',
                hintText: '',
                initialSelectedIds: _selectedRoleIds,
                onChanged: (roles) => _applyRoleFilter(roles),
                onOpen: () => setState(() => _anyModalOpen = true),
                onClose: () => setState(() => _anyModalOpen = false),
              ),
              const SizedBox(height: 20),

              // Contenido dinámico
              if (!_initialized || (_loading && _items.isEmpty))
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: CircularProgressIndicator(),
                )
              else if (_items.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Text('Sin experiencias'),
                )
              else
                Column(
                  children: [
                    for (final e in _items) _buildPost(e, isMobile),
                    if (_loadingMore)
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: LinearProgressIndicator(minHeight: 2),
                      ),
                  ],
                ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
