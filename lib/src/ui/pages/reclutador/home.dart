import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:lottie/lottie.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:vinculed_app_1/src/core/controllers/theme_controller.dart';
import 'package:vinculed_app_1/src/core/providers/user_provider.dart';
import 'package:vinculed_app_1/src/ui/widgets/buttons/simple_buttons.dart';
import 'package:vinculed_app_1/src/core/services/notification_service.dart';

class HomeRec extends StatefulWidget {
  const HomeRec({super.key});

  @override
  State<HomeRec> createState() => _HomeRecState();
}

class _HomeRecState extends State<HomeRec> {
  final usuario = FirebaseAuth.instance.currentUser!;
  final ScrollController _scrollCtrl = ScrollController();

  List<_RecruitedStudent> _students = [];
  bool _loading = true;
  String? _error;
  String _currentTab = 'Reclutado'; // 'Reclutado' | 'Completado'

  static bool _welcomeShown = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!_welcomeShown) {
        _welcomeShown = true;

        final userProv = context.read<UserDataProvider>();
        final nombre =
            userProv.nombreUsuario ?? (usuario.displayName ?? 'Reclutador');

        NotificationService.instance.initPush();
        NotificationService.instance.startListeningToIncomingMessages();
        await NotificationService.instance.addNotification(
          userId: usuario.uid,
          title: '¡Bienvenido $nombre!',
          body: 'Has iniciado sesión correctamente.',
        );
      }

      _fetchRecruitedStudents();
    });
  }

  Future<void> _fetchRecruitedStudents() async {
    setState(() { _loading = true; _error = null; });
    try {
      final userProv = context.read<UserDataProvider>();
      final headers = await userProv.getAuthHeaders();
      final idRol = userProv.idRol;
      final uri = Uri.parse('https://oda-talent-back-81413836179.us-central1.run.app/api/reclutadores/alumnos_reclutados')
          .replace(queryParameters: { 'id_reclutador': '$idRol', 'estado': _currentTab });
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
  
  void _changeTab(String tab) {
    if (_currentTab == tab) {
      _fetchRecruitedStudents();
      return;
    }
    setState(() => _currentTab = tab);
    _fetchRecruitedStudents();
  }

  Widget _tabButton(String label, bool isMobile) {
    final selected = _currentTab == label;
    final theme = ThemeController.instance;
    final accent = theme.secundario();
    final baseBg = Colors.blueGrey.shade200;
    return ElevatedButton(
      onPressed: () => _changeTab(label),
      style: ElevatedButton.styleFrom(
        elevation: selected ? 2 : 0,
        backgroundColor: selected ? accent : baseBg,
        foregroundColor: theme.primario(),
        padding: EdgeInsets.symmetric(horizontal: isMobile ? 18 : 28, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: TextStyle(
          fontSize: isMobile ? 14 : 16,
          fontWeight: FontWeight.w700,
          letterSpacing: .4,
        ),
      ),
      child: Text(label),
    );
  }


  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;
    final w = MediaQuery.of(context).size.width;
    final isMobile = w < 700; // se conserva por estilos

    return Scaffold(
      backgroundColor: theme.background(),
      body: SafeArea(
        child: SingleChildScrollView(
          controller: _scrollCtrl,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Saludo con avatar
              Row(
                children: [
                  CircleAvatar(
                    radius: 58,
                    backgroundColor: Colors.blue[50],
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

                // Pestañas Reclutado / Completado
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _tabButton('Reclutado', isMobile),
                    const SizedBox(width: 16),
                    _tabButton('Completado', isMobile),
                ],
              ),
              const SizedBox(height: 24),

              // Contenido dinámico
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
                          _currentTab == 'Reclutado'
                          ? 'Aún no hay alumnos reclutados'
                          : 'Tus becarios aún no han completado sus prácticas',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: isMobile ? 18 : 20,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF22313F),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _currentTab == 'Reclutado'
                            ? 'Cuando reclutes alumnos, sus tarjetas aparecerán aquí.'
                            : 'Los becarios cuya postulación hayas marcado como Completada aparecerán en esta sección.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: isMobile ? 13.5 : 14.5,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
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
                Column(
                  children: [
                    for (final s in _students)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _RecruitedCandidateCard(
                          data: s,
                          showMarkCompleted: _currentTab == 'Reclutado',
                          onCompleted: (id) {
                            setState(() {
                              _students.removeWhere((e) => e.idPostulacion == id);
                            });
                          },
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
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
      semestreActual: (j['semestre_actual'] == null)
          ? null
          : (j['semestre_actual'] is int
          ? j['semestre_actual']
          : int.tryParse('${j['semestre_actual']}')),
      habilidades: habs
          .map<_Habilidad>((e) => _Habilidad.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      urlFotoPerfil:
      (j['url_foto_perfil']?.toString().isNotEmpty ?? false) ? j['url_foto_perfil'].toString() : null,
      estatus: (j['estatus'] ?? '').toString(),
      nombreVacante: (j['nombre_vacante'] ?? '').toString(),
    );
  }
}

class _Habilidad {
  final int idHabilidad;
  final String categoria;
  final String tipo;
  final String habilidad;
  _Habilidad({
    required this.idHabilidad,
    required this.categoria,
    required this.tipo,
    required this.habilidad,
  });
  factory _Habilidad.fromJson(Map<String, dynamic> j) => _Habilidad(
    idHabilidad: j['id_habilidad'] is int ? j['id_habilidad'] : int.tryParse('${j['id_habilidad']}') ?? 0,
    categoria: (j['categoria'] ?? '').toString(),
    tipo: (j['tipo'] ?? '').toString(),
    habilidad: (j['habilidad'] ?? '').toString(),
  );
}

// =================== CARD ===================
class _RecruitedCandidateCard extends StatelessWidget {
  const _RecruitedCandidateCard({required this.data, required this.onCompleted, this.showMarkCompleted = true});
  final _RecruitedStudent data;
  final void Function(int idPostulacion) onCompleted;
  final bool showMarkCompleted;

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
    final resolved = url.startsWith('http')
        ? url
        : 'https://${url.replaceFirst(RegExp(r'^/+'), '')}';
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
      final uri = Uri.parse(
          'https://oda-talent-back-81413836179.us-central1.run.app/api/reclutadores/marcar_completada_postulacion');
      final userProv = context.read<UserDataProvider>();
      final headers = await userProv.getAuthHeaders();
      headers['Content-Type'] = 'application/json';
      final resp = await http.put(
        uri,
        headers: headers,
        body: jsonEncode(
            {'id_postulacion': data.idPostulacion, 'estatus': 'Completado'}),
      );
      if (resp.statusCode == 200) {
        onCompleted(data.idPostulacion);
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Postulación marcada como completada')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error ${resp.statusCode}: ${resp.body}')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;
    final skillsList =
    data.habilidades.map((e) => e.habilidad).where((e) => e.isNotEmpty).toList();
    final skills =
    (skillsList.length > 3 ? skillsList.take(3) : skillsList).join(', ');
    final estudianteInfo = data.semestreActual == null
        ? 'Estudiante ESCOM'
        : 'ESCOM · ${data.semestreActual}° Semestre';

    final statusLower = data.estatus.toLowerCase();
    final Color badgeColor =
    statusLower.contains('reclut') ? Colors.green : theme.secundario();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x11000000)),
        boxShadow: const [
          BoxShadow(
              blurRadius: 10,
              spreadRadius: 0,
              offset: Offset(0, 2),
              color: Color(0x0F000000)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: AspectRatio(
              aspectRatio: 4 / 3,
              child: GestureDetector(
                onTap: () =>
                    context.go('/reclutador/perfil_candidato/${data.idAlumno}'),
                child: _buildProfileImage(),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  data.nombre,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.black87),
                ),
              ),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: badgeColor.withOpacity(.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: badgeColor.withOpacity(.35)),
                ),
                child: Text(
                  data.estatus,
                  style: TextStyle(
                      color: badgeColor, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            data.nombreVacante.isEmpty
                ? 'Vacante no especificada'
                : data.nombreVacante,
            style: const TextStyle(color: Colors.black87),
          ),
          const SizedBox(height: 10),
          _detailRow('Estudiante:', estudianteInfo),
          const SizedBox(height: 6),
          _detailRow(
              'Habilidades:', skills.isEmpty ? 'No especificadas' : skills),
          const SizedBox(height: 12),
          if (showMarkCompleted)
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
