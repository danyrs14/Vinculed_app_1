import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:vinculed_app_1/src/core/providers/auth_notifier.dart';
import 'package:vinculed_app_1/src/core/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:vinculed_app_1/src/core/controllers/theme_controller.dart';
import 'package:vinculed_app_1/src/ui/widgets/elements/footer.dart';
import 'package:vinculed_app_1/src/ui/widgets/buttons/simple_buttons.dart';
import 'package:vinculed_app_1/src/ui/widgets/elements/header2.dart';
import 'package:vinculed_app_1/src/ui/widgets/elements/post_experiencia.dart';
import 'package:vinculed_app_1/src/ui/widgets/text_inputs/roles_multi_dropdown.dart';

class ExperiencesPage extends StatefulWidget {
  const ExperiencesPage({super.key});

  @override
  State<ExperiencesPage> createState() => _ExperiencesPageState();
}

class _ExperiencesPageState extends State<ExperiencesPage> {
  final usuario = FirebaseAuth.instance.currentUser;
  final _scrollCtrl = ScrollController();
  bool _showFooter = false;

  static const double _footerReservedSpace = EscomFooter.height;
  static const double _extraBottomPadding = 24.0;
  static const double _atEndThreshold = 4.0;

  // --- Estado de carga remota ---
  final List<Map<String, dynamic>> _items = [];
  int _page = 1;
  int _totalPages = 1;
  bool _loading = false; // primera carga
  bool _loadingMore = false; // paginación
  bool _initialized = false;
  int? _idAlumno;

  // Filtro por roles seleccionados
  List<int> _selectedRoleIds = [];

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_handleScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _handleScroll());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _initLoad());
    }
  }

  Future<void> _initLoad() async {
    if (!mounted) return;
    final userProv = Provider.of<UserDataProvider>(context, listen: false);
    // El id del alumno actual debe ser el idRol según API
    final id = userProv.idRol;
    if (id == null) {
      return; // aún no disponible, se reintenta en próximo build
    }
    _idAlumno = id;
    setState(() => _loading = true);
    _items.clear();
    _page = 1;
    await _fetchPage(_page);
    if (!mounted) return;
    setState(() {
      _initialized = true;
      _loading = false;
    });
  }

  Future<void> _fetchPage(int page) async {
    if (_idAlumno == null) return;
    if (page > 1) setState(() => _loadingMore = true);
    try {
      final userProv = Provider.of<UserDataProvider>(context, listen: false);
      final headers = await userProv.getAuthHeaders(); // incluye idToken
      final params = <String, String>{
        'id_alumno': '$_idAlumno',
        'page': '$page',
        'limit': '10',
      };
      if (_selectedRoleIds.isNotEmpty) {
        params['id_roltrabajo'] = _selectedRoleIds.join(',');
      }
      final url = Uri.parse('https://oda-talent-back-81413836179.us-central1.run.app/api/experiencias_alumnos/ver')
          .replace(queryParameters: params);
      final res = await http.get(url, headers: headers);
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        final pag = (body['paginacion'] as Map<String, dynamic>?);
        final list = (body['experiencias'] as List<dynamic>? ?? [])
            .cast<Map<String, dynamic>>();
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
    setState(() {
      _loading = true;
      _items.clear();
      _page = 1;
      _totalPages = 1;
    });
    await _fetchPage(1);
    if (mounted) setState(() => _loading = false);
  }

  void _handleScroll() {
    final pos = _scrollCtrl.position;
    if (!pos.hasPixels || !pos.hasContentDimensions) return;

    if (pos.maxScrollExtent <= 0) {
      if (_showFooter) setState(() => _showFooter = false);
      return;
    }
    final atBottom = pos.pixels >= (pos.maxScrollExtent - _atEndThreshold);
    if (atBottom != _showFooter) setState(() => _showFooter = atBottom);

    // Cargar siguiente página si aplica
    if (atBottom && !_loadingMore && _page < _totalPages) {
      _fetchPage(_page + 1);
    }
  }

  @override
  void dispose() {
    _scrollCtrl
      ..removeListener(_handleScroll)
      ..dispose();
    super.dispose();
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
      crossAxisAlignment: CrossAxisAlignment.center,
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
          maxWidth: 720,
          mediaUrl: e['url_multimedia'] as String?,
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
      appBar: EscomHeader2(
        onLoginTap: () => context.go('/alumno/perfil_cand'),
        onNotifTap: () {},
        onMenuSelected: (label) {
          switch (label) {
            case "Inicio":
              context.go('/inicio');
              break;
            case "Postulaciones":
              context.go('/alumno/mis_postulaciones');
              break;
            case "Mensajes":
              context.go('/alumno/messages');
              break;
            case "Experiencias":
              context.go('/alumno/experiencias');
              break;
            case "FAQ":
              context.go('/alumno/faq');
              break;
            case "Preferencias":
              context.go('/alumno/preferences');
              break;
          }
        },
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final minBodyHeight = constraints.maxHeight - _footerReservedSpace - _extraBottomPadding;

                return SingleChildScrollView(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.only(
                    bottom: _footerReservedSpace + _extraBottomPadding,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 900),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: minBodyHeight > 0 ? minBodyHeight : 0,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Título centrado
                              Padding(
                                padding: const EdgeInsets.only(top: 8, bottom: 8),
                                child: Text(
                                  'Experiencias',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: isMobile ? 28 : 34,
                                    fontWeight: FontWeight.w900,
                                    color: const Color(0xFF22313F),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              // Filtros + botón Crear en una misma fila (dropdown a la izquierda)
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Expanded(
                                      child: RolesMultiDropdown(
                                        label: 'Filtrar por roles',
                                        hintText: '',
                                        initialSelectedIds: _selectedRoleIds,
                                        onChanged: (roles) => _applyRoleFilter(roles),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    SizedBox(
                                      width: 220,
                                      child: SimpleButton(
                                        title: 'Crear',
                                        onTap: () {
                                          context.go('/alumno/experiencias_create');
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),
                              // Lista dinámica de experiencias
                              if (!_initialized || (_loading && _items.isEmpty))
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 24),
                                  child: Center(child: CircularProgressIndicator()),
                                )
                              else if (_items.isEmpty)
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 24),
                                  child: Text('Sin experiencias'),
                                )
                              else
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
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
                    ),
                  ),
                );
              },
            ),
          ),

          // Footer animado
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: AnimatedSlide(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              offset: _showFooter ? Offset.zero : const Offset(0, 1),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 220),
                opacity: _showFooter ? 1 : 0,
                child: EscomFooter(isMobile: isMobile),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
