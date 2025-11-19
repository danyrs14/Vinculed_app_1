import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:vinculed_app_1/src/core/providers/user_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:vinculed_app_1/src/core/controllers/theme_controller.dart';
import 'package:vinculed_app_1/src/ui/widgets/elements/footer.dart';
import 'package:vinculed_app_1/src/ui/widgets/elements/header3.dart';
import 'package:vinculed_app_1/src/ui/widgets/buttons/simple_buttons.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:lottie/lottie.dart';

class HomeRecruiterPage extends StatefulWidget {
  const HomeRecruiterPage({super.key});

  @override
  State<HomeRecruiterPage> createState() => _HomeRecruiterPageState();
}

class _HomeRecruiterPageState extends State<HomeRecruiterPage> {
  final usuario = FirebaseAuth.instance.currentUser!;
  final _scrollCtrl = ScrollController();
  bool _showFooter = false;

  static const double _footerReservedSpace = EscomFooter.height;
  static const double _extraBottomPadding = 24.0;
  static const double _atEndThreshold = 4.0;

  // --- nuevos estados para alumnos reclutados ---
  List<_RecruitedStudent> _students = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _onScroll();
      _fetchRecruitedStudents();
    });
  }

  Future<void> _fetchRecruitedStudents() async {
    setState(() { _loading = true; _error = null; });
    try {
      final userProv = context.read<UserDataProvider>();
      final headers = await userProv.getAuthHeaders();
      final idRol = userProv.idRol;
      final uri = Uri.parse('http://localhost:3000/api/reclutadores/alumnos_reclutados')
          .replace(queryParameters: { 'id_reclutador': '$idRol' });
      final resp = await http.get(uri, headers: headers);
      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        final data = jsonDecode(resp.body);
        final List list = (data is List) ? data : const [];
        _students = list.map<_RecruitedStudent>((e) => _RecruitedStudent.fromJson(e as Map<String, dynamic>)).toList();
        setState(() { _loading = false; });
      } else if (resp.statusCode == 404) {
        setState(() { _students = []; _loading = false; });
      } else {
        setState(() { _loading = false; _error = 'Error ${resp.statusCode}: ${resp.body}'; });
      }
    } catch (e) {
      setState(() { _loading = false; _error = 'Error al cargar: $e'; });
    }
  }

  void _onScroll() {
    final pos = _scrollCtrl.position;
    if (!pos.hasPixels || !pos.hasContentDimensions) return;

    if (pos.maxScrollExtent <= 0) {
      if (_showFooter) setState(() => _showFooter = false);
      return;
    }
    final atBottom = pos.pixels >= (pos.maxScrollExtent - _atEndThreshold);
    if (atBottom != _showFooter) setState(() => _showFooter = atBottom);
  }

  @override
  void dispose() {
    _scrollCtrl
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;
    final w = MediaQuery.of(context).size.width;
    final isMobile = w < 700;

    return Scaffold(
      backgroundColor: theme.background(),
      appBar: EscomHeader3(
        onLoginTap: () => context.go('/reclutador/perfil_rec'),
        onNotifTap: () {},
        onMenuSelected: (label) {
          switch (label) {
            case "Inicio":
              context.go('/inicio');
              break;
            case "Crear Vacante":
              context.go('/reclutador/new_vacancy');
              break;
            case "Mis Vacantes":
              context.go('/reclutador/postulaciones');
              break;
            case "FAQ":
              context.go('/reclutador/faq_rec');
              break;
            case "Mensajes":
              context.go('/reclutador/msg_rec ');
              break;
          }
        },
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final minBodyHeight =
                    constraints.maxHeight - _footerReservedSpace - _extraBottomPadding;

                return NotificationListener<ScrollNotification>(
                  onNotification: (n) {
                    if (n is ScrollUpdateNotification ||
                        n is UserScrollNotification ||
                        n is ScrollEndNotification) {
                      _onScroll();
                    }
                    return false;
                  },
                  child: SingleChildScrollView(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.only(
                      bottom: _footerReservedSpace + _extraBottomPadding,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1200),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: minBodyHeight > 0 ? minBodyHeight : 0,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Saludo con avatar
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 58,
                                      backgroundImage: usuario.photoURL != null ? NetworkImage(usuario.photoURL!) : null,
                                      child: usuario.photoURL == null ? const Icon(Icons.person, size: 58) : null,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'Bienvenido de Nuevo – ${context.select((UserDataProvider model) => model.nombreUsuario ?? 'Reclutador')}',
                                        style: TextStyle(
                                          fontSize: isMobile ? 22 : 28,
                                          fontWeight: FontWeight.w800,
                                          color: const Color(0xFF22313F),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 28),

                                // Lista de alumnos reclutados
                                if (_loading) ...[
                                  const Center(child: CircularProgressIndicator()),
                                ] else if (_error != null) ...[
                                  Center(
                                    child: Column(
                                      children: [
                                        const Icon(Icons.error_outline, color: Colors.redAccent),
                                        const SizedBox(height: 8),
                                        Text(_error!, textAlign: TextAlign.center),
                                        const SizedBox(height: 12),
                                        SizedBox(
                                          height: 40,
                                          child: SimpleButton(title: 'Reintentar', onTap: _fetchRecruitedStudents),
                                        ),
                                      ],
                                    ),
                                  ),
                                ] else if (_students.isEmpty) ...[
                                  Center(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 32),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          SizedBox(
                                            height: isMobile ? 180 : 230,
                                            child: Lottie.asset(
                                              'assets/images/dashboard.json',
                                              fit: BoxFit.contain,
                                              repeat: true,
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          Text(
                                            'Aún no hay alumnos reclutados',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: isMobile ? 18 : 20,
                                              fontWeight: FontWeight.w800,
                                              color: const Color(0xFF22313F),
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            'Cuando reclutes alumnos, sus tarjetas aparecerán aquí.',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: isMobile ? 13.5 : 14.5,
                                              color: Colors.black87,
                                            ),
                                          ),
                                          const SizedBox(height: 14),
                                          SizedBox(
                                            height: 40,
                                            child: SimpleButton(
                                              title: 'Actualizar',
                                              onTap: _fetchRecruitedStudents,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ] else ...[
                                  LayoutBuilder(
                                    builder: (_, c) {
                                      final maxExtent = c.maxWidth < 820 ? 580.0 : 520.0;
                                      final aspect = 0.6; // taller tiles to avoid overflow
                                      return GridView.builder(
                                        shrinkWrap: true,
                                        physics: const NeverScrollableScrollPhysics(),
                                        itemCount: _students.length,
                                        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                                          maxCrossAxisExtent: maxExtent,
                                          mainAxisSpacing: 16,
                                          crossAxisSpacing: 16,
                                          childAspectRatio: aspect,
                                        ),
                                        itemBuilder: (_, i) => _RecruitedCandidateCard(
                                          data: _students[i],
                                          onCompleted: (id) {
                                            setState(() {
                                              _students.removeWhere((s) => s.idPostulacion == id);
                                            });
                                          },
                                        ),
                                      );
                                    },
                                  ),
                                ],

                                const SizedBox(height: 20),
                              ],
                            ),
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

// =================== MODELO ===================
class _RecruitedStudent {
  final int idUsuario;
  final int idAlumno;
  final int idPostulacion;
  final int idVacante;
  final String nombre;
  final int? semestreActual;
  final List<_Habilidad> habilidades;
  final String? urlFotoPerfil;
  final String estatus;
  final String nombreVacante;

  _RecruitedStudent({
    required this.idUsuario,
    required this.idAlumno,
    required this.idPostulacion,
    required this.idVacante,
    required this.nombre,
    required this.semestreActual,
    required this.habilidades,
    required this.urlFotoPerfil,
    required this.estatus,
    required this.nombreVacante,
  });

  factory _RecruitedStudent.fromJson(Map<String, dynamic> j) {
    final List habs = (j['habilidades'] is List) ? j['habilidades'] : const [];
    return _RecruitedStudent(
      idUsuario: j['id_usuario'] is int ? j['id_usuario'] : int.tryParse('${j['id_usuario']}') ?? 0,
      idAlumno: j['id_alumno'] is int ? j['id_alumno'] : int.tryParse('${j['id_alumno']}') ?? 0,
      idPostulacion: j['id_postulacion'] is int ? j['id_postulacion'] : int.tryParse('${j['id_postulacion']}') ?? 0,
      idVacante: j['id_vacante'] is int ? j['id_vacante'] : int.tryParse('${j['id_vacante']}') ?? 0,
      nombre: (j['nombre'] ?? '').toString(),
      semestreActual: (j['semestre_actual'] == null) ? null : (j['semestre_actual'] is int ? j['semestre_actual'] : int.tryParse('${j['semestre_actual']}')),
      habilidades: habs.map<_Habilidad>((e) => _Habilidad.fromJson(Map<String, dynamic>.from(e))).toList(),
      urlFotoPerfil: (j['url_foto_perfil']?.toString().isNotEmpty ?? false) ? j['url_foto_perfil'].toString() : null,
      estatus: (j['estatus'] ?? '').toString(),
      nombreVacante: (j['nombre_vacante'] ?? '').toString(),
    );
  }
}

class _Habilidad {
  final int idHabilidad; final String categoria; final String tipo; final String habilidad;
  _Habilidad({required this.idHabilidad, required this.categoria, required this.tipo, required this.habilidad});
  factory _Habilidad.fromJson(Map<String, dynamic> j) => _Habilidad(
    idHabilidad: j['id_habilidad'] is int ? j['id_habilidad'] : int.tryParse('${j['id_habilidad']}') ?? 0,
    categoria: (j['categoria'] ?? '').toString(),
    tipo: (j['tipo'] ?? '').toString(),
    habilidad: (j['habilidad'] ?? '').toString(),
  );
}

// =================== CARD ===================
class _RecruitedCandidateCard extends StatelessWidget {
  const _RecruitedCandidateCard({required this.data, required this.onCompleted});
  final _RecruitedStudent data;
  final void Function(int idPostulacion) onCompleted;

  // Construye la imagen de perfil soportando data URI (base64) y URL sin esquema
  Widget _buildProfileImage() {
    final url = data.urlFotoPerfil;
    if (url == null || url.isEmpty) {
      return Container(
        alignment: Alignment.center,
        color: Colors.grey.shade200,
        child: const Icon(Icons.person, size: 48),
      );
    }

    if (url.startsWith('data:image')) {
      try {
        final i = url.indexOf(',');
        final b64 = i >= 0 ? url.substring(i + 1) : url;
        final bytes = base64Decode(b64);
        return Image.memory(bytes, fit: BoxFit.cover);
      } catch (_) {
        return Container(
          alignment: Alignment.center,
          color: Colors.grey.shade200,
          child: const Icon(Icons.person, size: 48),
        );
      }
    }

    // Asegura esquema para URLs como //cdn... o sin http
    final resolved = url.startsWith('http') ? url : 'https://${url.replaceFirst(RegExp(r'^/+'), '')}';
    return Image.network(
      resolved,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        alignment: Alignment.center,
        color: Colors.grey.shade200,
        child: const Icon(Icons.person, size: 48),
      ),
    );
  }

  Future<void> _markCompleted(BuildContext context) async {
    try {
      final uri = Uri.parse('http://localhost:3000/api/reclutadores/marcar_completada_postulacion');
      final userProv = context.read<UserDataProvider>();
      final headers = await userProv.getAuthHeaders();
      headers['Content-Type'] = 'application/json';
      final resp = await http.put(
        uri,
        headers: headers,
        body: jsonEncode({'id_postulacion': data.idPostulacion, 'estatus': 'Completado'}),
      );
      if (resp.statusCode == 200) {
        onCompleted(data.idPostulacion);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Postulación marcada como completada')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error ${resp.statusCode}: ${resp.body}')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;
    // Limit skills to max 3
    final skillsList = data.habilidades
        .map((e) => e.habilidad)
        .where((e) => e.isNotEmpty)
        .toList();
    final skills = (skillsList.length > 3 ? skillsList.take(3) : skillsList).join(', ');
    final estudianteInfo = data.semestreActual == null
        ? 'Estudiante ESCOM'
        : 'ESCOM · ${data.semestreActual}° Semestre';

    final statusLower = data.estatus.toLowerCase();
    final Color badgeColor = statusLower.contains('reclut') ? Colors.green : theme.secundario();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x11000000)),
        boxShadow: const [
          BoxShadow(blurRadius: 10, spreadRadius: 0, offset: Offset(0, 2), color: Color(0x0F000000)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Foto ocupa espacio disponible superior (clic para ir al perfil)
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: AspectRatio(
                aspectRatio: 4/3,
                child: GestureDetector(
                  onTap: () => context.go('/reclutador/perfil_candidato/${data.idAlumno}'),
                  child: _buildProfileImage(),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Nombre y badge de estatus
          Row(
            children: [
              Expanded(
                child: Text(
                  data.nombre,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.black87),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: badgeColor.withOpacity(.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: badgeColor.withOpacity(.35)),
                ),
                child: Text(
                  data.estatus,
                  style: TextStyle(color: badgeColor, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Vacante
          Text(data.nombreVacante.isEmpty ? 'Vacante no especificada' : data.nombreVacante,
              style: const TextStyle(color: Colors.black87)),
          const SizedBox(height: 10),

          // Estudiante y habilidades
          _detailRow('Estudiante:', estudianteInfo),
          const SizedBox(height: 6),
          _detailRow('Habilidades:', skills.isEmpty ? 'No especificadas' : skills),

          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: SizedBox(
              height: 40,
              child: SimpleButton(
                title: 'Marcar como Completada',
                onTap: () => _markCompleted(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return RichText(
      text: TextSpan(
        text: '$label ',
        style: const TextStyle(
          color: Colors.black87,
          fontWeight: FontWeight.w700,
          fontSize: 13.5,
        ),
        children: [
          TextSpan(
            text: value,
            style: const TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
