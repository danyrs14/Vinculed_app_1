import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:vinculed_app_1/src/core/controllers/theme_controller.dart';
import 'package:vinculed_app_1/src/ui/widgets/elements/footer.dart';
import 'package:vinculed_app_1/src/ui/widgets/elements/header3.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:vinculed_app_1/src/core/providers/user_provider.dart';
import 'package:vinculed_app_1/src/ui/widgets/elements/perfilAlumno/habilidad_clase.dart';
// Secciones
import 'package:vinculed_app_1/src/ui/widgets/elements/perfilAlumno/escolaridad_section.dart';
import 'package:vinculed_app_1/src/ui/widgets/elements/perfilAlumno/experiencia_section.dart';
import 'package:vinculed_app_1/src/ui/widgets/elements/perfilAlumno/cursos_section.dart';
import 'package:vinculed_app_1/src/ui/widgets/elements/perfilAlumno/certificado_section.dart';
import 'package:vinculed_app_1/src/ui/widgets/elements/perfilAlumno/habilidades_tipo_section.dart';
import 'package:vinculed_app_1/src/ui/widgets/elements/perfilAlumno/urls_section.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_storage/firebase_storage.dart' as fs;
import 'package:vinculed_app_1/src/ui/widgets/buttons/simple_buttons.dart';

class RecruiterCandidateProfilePage extends StatefulWidget {
  const RecruiterCandidateProfilePage({super.key, this.idAlumno});
  final int? idAlumno;

  @override
  State<RecruiterCandidateProfilePage> createState() => _RecruiterCandidateProfilePage();
}

class _RecruiterCandidateProfilePage extends State<RecruiterCandidateProfilePage> {
  final _scrollCtrl = ScrollController();
  bool _showFooter = false;
  final usuario = FirebaseAuth.instance.currentUser!;

  static const double _footerReservedSpace = EscomFooter.height;
  static const double _extraBottomPadding = 24.0;
  static const double _atEndThreshold = 4.0;


  // Estado de carga
  bool _loading = false;
  String? _error;
  AlumnoPerfil? _perfil;

  // POSTULACIONES section
  List<PostulacionRevision> _postulaciones = [];
  bool _loadingPostulaciones = false;
  String? _errorPostulaciones;
  bool _emptyPostulacionesNice = false; // mostrar vacío ilustrado en 404
  
  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_handleScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchPerfil();
      _fetchPostulacionesRevision();
      _handleScroll();
    });
  }

  Future<void> _fetchPerfil() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final int idAlumno = widget.idAlumno!;
    final provider = context.read<UserDataProvider>();
    final uri = Uri.parse('https://oda-talent-back-81413836179.us-central1.run.app/api/alumnos/perfil/vista_reclutador?id_alumno=$idAlumno');
    try {
      final headers = await provider.getAuthHeaders();
      final resp = await http.get(uri, headers:headers);
      if (resp.statusCode != 200) {
        setState(() {
          _error = 'Error ${resp.statusCode} al cargar perfil';
          _loading = false;
        });
        return;
      }
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final perfil = AlumnoPerfil.fromJson(data);
      setState(() {
        _perfil = perfil;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Excepción: $e';
        _loading = false;
      });
    }
  }

  Future<void> _fetchPostulacionesRevision() async {
    final idAlumno = widget.idAlumno;
    if (idAlumno == null) return;
    setState(() {
      _loadingPostulaciones = true;
      _errorPostulaciones = null;
      _emptyPostulacionesNice = false;
    });
    try {
      final provider = context.read<UserDataProvider>();
      final idReclutador = provider.idRol; // idRol del reclutador
      if (idReclutador == null) {
        setState(() {
          _errorPostulaciones = 'Sin id_reclutador';
          _loadingPostulaciones = false;
        });
        return;
      }
      final headers = await provider.getAuthHeaders();
      final uri = Uri.parse('https://oda-talent-back-81413836179.us-central1.run.app/api/reclutadores/postulaciones_revision?id_alumno=$idAlumno&id_reclutador=$idReclutador');
      final resp = await http.get(uri, headers: headers);
      if (resp.statusCode == 404) {
        setState(() {
          _postulaciones = [];
          _emptyPostulacionesNice = true;
          _loadingPostulaciones = false;
        });
        return;
      }
      if (resp.statusCode != 200) {
        setState(() {
          _errorPostulaciones = 'Error ${resp.statusCode} al cargar postulaciones';
          _loadingPostulaciones = false;
        });
        return;
      }
      final data = jsonDecode(resp.body) as List<dynamic>;
      final list = data.map((e) => PostulacionRevision.fromJson(e as Map<String, dynamic>)).toList();
      setState(() {
        _postulaciones = list;
        _loadingPostulaciones = false;
      });
    } catch (e) {
      setState(() {
        _errorPostulaciones = 'Excepción postulaciones: $e';
        _loadingPostulaciones = false;
      });
    }
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
  }

  @override
  void dispose() {
    _scrollCtrl
      ..removeListener(_handleScroll)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;
    final w = MediaQuery.of(context).size.width;
    final isMobile = w < 900;

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
              context.go('/reclutador/msg_rec');
              break;
          }
        },
      ),
      body: Stack(
        children: [
          Positioned.fill(child: _buildBody(isMobile, w)),
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
                child: EscomFooter(isMobile: w < 700),
              ),
            ),
          ),
        ],
      ),
    );
  }


  Future<void> _openCv(String? storedPathOrUrl) async {
    if (storedPathOrUrl == null || storedPathOrUrl.isEmpty) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No hay CV para visualizar')));
      return;
    }
    try {
      String viewUrl = storedPathOrUrl;
      if (!storedPathOrUrl.startsWith('http')) {
        // Es una ruta en Storage, obtener URL de descarga
        final ref = fs.FirebaseStorage.instance.ref().child(storedPathOrUrl);
        viewUrl = await ref.getDownloadURL();
      }
      final Uri uri = Uri.parse(viewUrl);
      if (await canLaunchUrl(uri)) {
        // externalApplication fuerza abrir en una nueva pestaña/navegador
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw 'No se pudo lanzar la URL: $viewUrl';
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No se pudo abrir el CV: $e')));
    }
  }

  Widget _buildPostulacionesEmptyNice() {
    final theme = ThemeController.instance;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: theme.background(),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.blueGrey.shade100),
              ),
              child: Icon(Icons.inbox_outlined, size: 44, color: Colors.blueGrey.shade300),
            ),
            const SizedBox(height: 14),
            const Text(
              'Este alumno no está postulado a ninguna de tus vacantes activas',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1F2A36)),
            ),
            const SizedBox(height: 6),
            const Text(
              'Cuando el alumno se postule, verás sus solicitudes aquí.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.black87),
            ),
            const SizedBox(height: 12),
            SizedBox(
              child: SimpleButton(
                title: 'Actualizar',
                onTap: _fetchPostulacionesRevision,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(bool isMobile, double w) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Text(_error!, style: const TextStyle(color: Colors.red)),
      );
    }
    if (_perfil == null) {
      return const Center(child: Text('Sin datos de perfil todavía.'));
    }

    final perfil = _perfil!;

    return LayoutBuilder(
      builder: (context, constraints) {
        return NotificationListener<ScrollNotification>(
          onNotification: (n) {
            if (n is ScrollUpdateNotification || n is UserScrollNotification || n is ScrollEndNotification) {
              _handleScroll();
            }
            return false;
          },
          child: SingleChildScrollView(
            controller: _scrollCtrl,
            padding: const EdgeInsets.only(bottom: _footerReservedSpace + _extraBottomPadding),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: MediaQuery.of(context).size.height - _footerReservedSpace - _extraBottomPadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _BannerSection(
                          isMobile: isMobile,
                          cvName: _cvName(perfil.urlCv),
                          urlFoto: perfil.urlFotoPerfil,
                          onViewCv: () async => _openCv(perfil.urlCv),
                        ),
                        const SizedBox(height: 18),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child:
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                perfil.nombre ?? usuario.displayName ?? 'Sin nombre',
                                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Color(0xFF1F2A36)),
                              ),
                              const SizedBox(height: 6),
                              const Text('Alumno', style: TextStyle(fontSize: 16, color: Colors.black87)),
                            ],
                          )
                        ),
                        const SizedBox(height: 22),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: isMobile
                              ? Column(
                                  children: [
                                    _InfoColumn(items: _leftItems(perfil), crossAxisStart: true),
                                    const SizedBox(height: 24),
                                    _InfoColumn(items: _rightItems(perfil), crossAxisStart: true),
                                  ],
                                )
                              : Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(child: _InfoColumn(items: _leftItems(perfil))),
                                    const SizedBox(width: 24),
                                    Expanded(child: _InfoColumn(items: _rightItems(perfil))),
                                  ],
                                ),
                        ),
                        const SizedBox(height: 28),
                        // Listas detalladas organizadas en filas
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: isMobile
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      "INFORMACIÓN CURRICULAR:",
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF1F2A36),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    // Escolaridad
                                    EscolaridadSection(
                                      items: perfil.escolaridad,
                                      emptyText: 'No especificado',
                                      onUpdated: () => _fetchPerfil(),
                                      readOnly: true,
                                    ),
                                    const SizedBox(height: 16),
                                    // Experiencia Laboral
                                    ExperienciaSection(
                                      items: perfil.experienciaLaboral.map((e) => ExperienciaItem(
                                        idExperiencia: e.idExperiencia,
                                        idAlumno: e.idAlumno,
                                        cargo: e.cargo,
                                        empresa: e.empresa,
                                        fechaInicio: e.fechaInicio,
                                        fechaFin: e.fechaFin,
                                        descripcion: e.descripcion,
                                        habilidadesDesarrolladas: e.habilidadesDesarrolladas,
                                      )).toList(),
                                      emptyText: 'No especificado',
                                      onUpdated: () => _fetchPerfil(),
                                      readOnly: true,
                                    ),
                                    const SizedBox(height: 16),
                                    // Cursos
                                    CursosSection(
                                      items: perfil.cursos,
                                      emptyText: 'No especificado',
                                      onUpdated: () => _fetchPerfil(),
                                      readOnly: true,
                                    ),
                                    const SizedBox(height: 16),
                                    // Certificados
                                    CertificadosSection(
                                      items: perfil.certificados,
                                      emptyText: 'No especificado',
                                      onUpdated: () => _fetchPerfil(),
                                      readOnly: true,
                                    ),
                                    const SizedBox(height: 16),
                                    // Habilidades Técnicas
                                    HabilidadesTipoSection(
                                      title: 'Habilidades Técnicas',
                                      tipoDisplay: 'Técnicas',
                                      idAlumno: perfil.idAlumno,
                                      items: perfil.habilidades.where((h) => _isTecnica(h)).toList(),
                                      emptyText: 'No espeficicado',
                                      onUpdated: () => _fetchPerfil(),
                                      readOnly: true,
                                    ),
                                    const SizedBox(height: 16),
                                    // Habilidades Blandas
                                    HabilidadesTipoSection(
                                      title: 'Habilidades Blandas',
                                      tipoDisplay: 'Blandas',
                                      idAlumno: perfil.idAlumno,
                                      items: perfil.habilidades.where((h) => _isBlanda(h)).toList(),
                                      emptyText: 'No especificado',
                                      onUpdated: () => _fetchPerfil(),
                                      readOnly: true,
                                    ),
                                    const SizedBox(height: 16),
                                    // Idiomas
                                    HabilidadesTipoSection(
                                      title: 'Idiomas',
                                      tipoDisplay: 'Idiomas',
                                      idAlumno: perfil.idAlumno,
                                      items: perfil.habilidades.where((h) => _isIdioma(h)).toList(),
                                      emptyText: 'No especificado',
                                      onUpdated: () => _fetchPerfil(),
                                      readOnly: true,
                                    ),
                                    const SizedBox(height: 16),
                                    UrlsSection(
                                      items: perfil.urlsExternas,
                                      emptyText: 'No especificado',
                                      onUpdated: () => _fetchPerfil(),
                                      readOnly: true,
                                    ),
                                  ],
                                )
                              : Column(
                                  children: [
                                    const Text(
                                      "INFORMACIÓN CURRICULAR:",
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF1F2A36),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: EscolaridadSection(
                                            items: perfil.escolaridad,
                                            emptyText: 'No especificado',
                                            onUpdated: () => _fetchPerfil(),
                                            readOnly: true,
                                          ),
                                        ),
                                        const SizedBox(width: 24),
                                        Expanded(
                                          child: // Experiencia Laboral
                                          ExperienciaSection(
                                            items: perfil.experienciaLaboral.map((e) => ExperienciaItem(
                                              idExperiencia: e.idExperiencia,
                                              idAlumno: e.idAlumno,
                                              cargo: e.cargo,
                                              empresa: e.empresa,
                                              fechaInicio: e.fechaInicio,
                                              fechaFin: e.fechaFin,
                                              descripcion: e.descripcion,
                                              habilidadesDesarrolladas: e.habilidadesDesarrolladas,
                                            )).toList(),
                                            emptyText: 'No especificado',
                                            onUpdated: () => _fetchPerfil(),
                                            readOnly: true,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: 
                                          // Cursos
                                          CursosSection(
                                            items: perfil.cursos,
                                            emptyText: 'No especificado',
                                            onUpdated: () => _fetchPerfil(),
                                            readOnly: true,
                                          ),
                                        ),
                                        const SizedBox(width: 24),
                                        Expanded(
                                          child: CertificadosSection(
                                            items: perfil.certificados,
                                            emptyText: 'No especificado',
                                            onUpdated: () => _fetchPerfil(),
                                            readOnly: true,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: HabilidadesTipoSection(
                                            title: 'Habilidades Técnicas',
                                            tipoDisplay: 'Técnicas',
                                            idAlumno: perfil.idAlumno,
                                            items: perfil.habilidades.where((h) => _isTecnica(h)).toList(),
                                            emptyText: 'No especificado',
                                            onUpdated: () => _fetchPerfil(),
                                            readOnly: true,
                                          ),
                                        ),
                                        
                                        const SizedBox(width: 24),
                                        Expanded(
                                          child: UrlsSection(
                                            items: perfil.urlsExternas,
                                            emptyText: 'No especificado',
                                            onUpdated: () => _fetchPerfil(),
                                            readOnly: true,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: HabilidadesTipoSection(
                                            title: 'Habilidades Blandas',
                                            tipoDisplay: 'Blandas',
                                            idAlumno: perfil.idAlumno,
                                            items: perfil.habilidades.where((h) => _isBlanda(h)).toList(),
                                            emptyText: 'No especificado',
                                            onUpdated: () => _fetchPerfil(),
                                            readOnly: true,
                                          ),
                                        ),
                                        const SizedBox(width: 24),
                                        Expanded(
                                          child: HabilidadesTipoSection(
                                            title: 'Idiomas',
                                            tipoDisplay: 'Idiomas',
                                            idAlumno: perfil.idAlumno,
                                            items: perfil.habilidades.where((h) => _isIdioma(h)).toList(),
                                            emptyText: 'No especificado',
                                            onUpdated: () => _fetchPerfil(),
                                            readOnly: true,
                                          ),
                                        ),
                                        
                                        
                                      ],
                                    ),
                                  ],
                                ),
                        ),
                        const SizedBox(height: 28),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'POSTULACIONES:',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1F2A36),
                                ),
                              ),
                              const SizedBox(height: 16),
                              if (_loadingPostulaciones)
                                const Center(child: CircularProgressIndicator())
                              else if (_errorPostulaciones != null)
                                Text(_errorPostulaciones!, style: const TextStyle(color: Colors.red))
                              else if (_emptyPostulacionesNice)
                                _buildPostulacionesEmptyNice()
                              else if (_postulaciones.isEmpty)
                                const Text('Sin postulaciones')
                              else
                                LayoutBuilder(
                                  builder: (context, c) {
                                    final isWide = c.maxWidth > 900;
                                    final cards = _postulaciones
                                        .map((p) => Padding(
                                              padding: const EdgeInsets.only(bottom: 18),
                                              child: _PostulacionCard(
                                                postulacion: p,
                                                onActionDone: () => _fetchPostulacionesRevision(),
                                              ),
                                            ))
                                        .toList();
                                    if (isWide) {
                                      // two columns
                                      final left = <Widget>[];
                                      final right = <Widget>[];
                                      for (var i = 0; i < cards.length; i++) {
                                        (i % 2 == 0 ? left : right).add(cards[i]);
                                      }
                                      return Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Expanded(child: Column(children: left)),
                                          const SizedBox(width: 24),
                                          Expanded(child: Column(children: right)),
                                        ],
                                      );
                                    }
                                    return Column(children: cards);
                                  },
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _cvName(String? urlCv) {
    if (urlCv == null || urlCv.isEmpty) return 'No hay CV para visualizar';
    final uri = Uri.tryParse(urlCv);
    if (uri == null) return 'No hay CV para visualizar';
    return uri.pathSegments.isNotEmpty ? uri.pathSegments.last : 'CV';
  }

  List<_InfoItem> _leftItems(AlumnoPerfil p) => [
        _InfoItem(label: 'Correo Electrónico:', value: _nullOr(p.correo, 'No especificado')),
        _InfoItem(label: 'Ciudad:', value: _nullOr(p.ciudad, 'No especificado')),
        _InfoItem(label: 'Entidad:', value: _nullOr(p.entidad, 'No especificado')),
        _InfoItem(label: 'Teléfono:', value: _nullOr(p.telefono, 'No especificado')),
        _InfoItem(label: 'Semestre Actual:', value: p.semestreActual?.toString() ?? 'No especificado',),
      ];

  List<_InfoItem> _rightItems(AlumnoPerfil p) => [
        _InfoItem(label: 'Descripción:', value: _nullOr(p.descripcion, 'No especificado'),),
        _InfoItem(label: 'Fecha de Nacimiento:', value: _nullOr(p.fechaNacimiento?.substring(0, (p.fechaNacimiento?.length ?? 0) >= 10 ? 10 : (p.fechaNacimiento?.length ?? 0)), 'No especificado'),),
      ];

  String _nullOr(String? v, String placeholder) => (v == null || v.trim().isEmpty) ? placeholder : v;

  // Helpers para clasificar habilidades
  String _norm(String? s) => (s ?? '')
      .toLowerCase()
      .replaceAll('á', 'a')
      .replaceAll('é', 'e')
      .replaceAll('í', 'i')
      .replaceAll('ó', 'o')
      .replaceAll('ú', 'u');
  bool _isTecnica(HabilidadItem h) {
    final t = _norm(h.tipo);
    return t.contains('tecnica');
  }
  bool _isBlanda(HabilidadItem h) {
    final t = _norm(h.tipo);
    return t.contains('blanda');
  }
  bool _isIdioma(HabilidadItem h) {
    final t = _norm(h.tipo);
    return t.contains('idioma');
  }


}

/* ════════════════════════ Modelos y parsing ════════════════════════ */

class AlumnoPerfil {
  final int idAlumno;
  final int idUsuario;
  final String? nombre;
  final String? correo;
  final String? fechaNacimiento;
  final String? telefono;
  final String? ciudad;
  final String? entidad;
  final String? descripcion;
  final String? urlCv;
  final int? semestreActual;
  final int? visualizaciones;
  final String? urlFotoPerfil;
  final int? completado;
  final List<EscolaridadItem> escolaridad;
  final List<ExperienciaItem> experienciaLaboral;
  final List<CursoItem> cursos;
  final List<CertificadoItem> certificados;
  final List<HabilidadItem> habilidades;
  final List<UrlItem> urlsExternas;

  AlumnoPerfil({
    required this.idAlumno,
    required this.idUsuario,
    required this.nombre,
    required this.correo,
    required this.fechaNacimiento,
    required this.telefono,
    required this.ciudad,
    required this.entidad,
    required this.descripcion,
    required this.urlCv,
    required this.semestreActual,
    required this.visualizaciones,
    required this.urlFotoPerfil,
    required this.completado,
    required this.escolaridad,
    required this.experienciaLaboral,
    required this.cursos,
    required this.certificados,
    required this.habilidades,
    required this.urlsExternas,
  });

  factory AlumnoPerfil.fromJson(Map<String, dynamic> j) => AlumnoPerfil(
        idAlumno: _asInt(j['id_alumno']),
        idUsuario: _asInt(j['id_usuario']),
        nombre: j['nombre'],
        correo: j['correo'],
        fechaNacimiento: j['fecha_nacimiento'],
        telefono: j['telefono'],
        ciudad: j['ciudad'],
        entidad: j['entidad'],
        descripcion: j['descripcion'],
        urlCv: j['url_cv'],
        semestreActual: _asIntNullable(j['semestre_actual']),
        visualizaciones: _asIntNullable(j['visualizaciones']),
        urlFotoPerfil: j['url_foto_perfil'],
        completado: _asIntNullable(j['completado']),
        escolaridad: (j['escolaridad'] as List? ?? []).map((e) => EscolaridadItem.fromJson(e)).toList(),
        experienciaLaboral: (j['experiencia_laboral'] as List? ?? []).map((e) => ExperienciaItem.fromJson(e)).toList(),
        cursos: (j['cursos'] as List? ?? []).map((e) => CursoItem.fromJson(e)).toList(),
        certificados: (j['certificados'] as List? ?? []).map((e) => CertificadoItem.fromJson(e)).toList(),
        habilidades: (j['habilidades'] as List? ?? []).map((e) => HabilidadItem.fromJson(e)).toList(),
        urlsExternas: (j['urls_externas'] as List? ?? []).map((e) => UrlItem.fromJson(e)).toList(),
      );
}

// ==== Safe parsing helpers (avoid type 'String' is not subtype of 'int') ====
int _asInt(dynamic v) {
  if (v is int) return v;
  if (v is String) return int.tryParse(v) ?? 0;
  return 0;
}
int? _asIntNullable(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is String) return int.tryParse(v);
  return null;
}

/* ════════════════════════ Secciones Visuales existentes adaptadas ════════════════════════ */

class _BannerSection extends StatelessWidget {
  const _BannerSection({
    required this.isMobile,
    required this.cvName,
    required this.urlFoto,
    this.onViewCv,
  });

  final bool isMobile;
  final String cvName;
  final String? urlFoto;
  final Future<void> Function()? onViewCv;

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;

    Widget _cvBox({required bool expand}) {
      return Container(
        margin: const EdgeInsets.only(bottom: 18),
        height: 44,
        constraints: expand ? null : const BoxConstraints(maxWidth: 330),
        decoration: BoxDecoration(
          color: theme.background(),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFBFD7E2), width: 1.4),
        ),
        child: Row(
          children: [
            const SizedBox(width: 12),
            const InkWell(
              child: const Icon(Icons.attach_file, size: 18, color: Colors.black54),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: cvName == 'No hay CV para visualizar'?
                Text(cvName,
                    style: const TextStyle(color: Colors.black54),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                )
                :InkWell(
                onTap: onViewCv,
                child: Text(
                 'Ver CV',
                  style: const TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
        ),
      );
    }

    if (isMobile) {
      return Container(
        height: 240,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/portada.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Align(
          alignment: Alignment.bottomLeft,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(58),
                child: CircleAvatar(
                  radius: 58,
                  backgroundColor: Colors.blue[50],
                  backgroundImage: urlFoto != null ? NetworkImage(urlFoto!) : null,
                  child: urlFoto == null ? const Icon(Icons.person, size: 58) : null,
                ),
              ),
              const SizedBox(height: 12),
              _cvBox(expand: true),
            ],
          ),
        ),
      );
    }

    return Stack(
      children: [
        AspectRatio(
          aspectRatio: 16 / 4.5,
          child: ClipRRect(
            child: Image.asset('assets/images/portada.jpg', fit: BoxFit.cover),
          ),
        ),
        Positioned.fill(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    margin: const EdgeInsets.only(bottom: 18),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(58),
                      child: CircleAvatar(
                        radius: 58,
                        backgroundColor: Colors.blue[50],
                        backgroundImage: urlFoto != null ? NetworkImage(urlFoto!) : null,
                        child: urlFoto == null ? const Icon(Icons.person, size: 58) : null,
                      ),
                    ),
                  ),
                  const Spacer(),
                  _cvBox(expand: false),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoColumn extends StatelessWidget {
  const _InfoColumn({required this.items, this.crossAxisStart = false});
  final List<_InfoItem> items;
  final bool crossAxisStart;
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: crossAxisStart ? CrossAxisAlignment.start : CrossAxisAlignment.stretch,
      children: [
        for (final it in items) ...[
          _InfoRow(item: it),
          const SizedBox(height: 16),
        ],
      ],
    );
  }
}

class _InfoItem {
  final String label;
  final String value;
  const _InfoItem({
    required this.label,
    required this.value,
  });
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.item});
  final _InfoItem item;
  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children:  [
        SizedBox(
          width: 190,
          child: Text(item.label, style: const TextStyle(fontWeight: FontWeight.w700)),
        ),
        Expanded(
          child: Text(item.value, style: item.value.contains('No especificado') ? const TextStyle(color: Colors.black45, height: 1.4) : const TextStyle(color: Colors.black87, height: 1.4)),
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}

class PostulacionRevision {
  final int idPostulacion;
  final int idAlumno;
  final int idVacante;
  final int idReclutador;
  final String titulo;
  final String fechaPublicacion;
  final String fechaLimite;
  final String estatus;
  PostulacionRevision({
    required this.idPostulacion,
    required this.idAlumno,
    required this.idVacante,
    required this.idReclutador,
    required this.titulo,
    required this.fechaPublicacion,
    required this.fechaLimite,
    required this.estatus,
  });
  factory PostulacionRevision.fromJson(Map<String, dynamic> j) => PostulacionRevision(
        idPostulacion: j['id_postulacion'] ?? 0,
        idAlumno: j['id_alumno'] ?? 0,
        idVacante: j['id_vacante'] ?? 0,
        idReclutador: j['id_reclutador'] ?? 0,
        titulo: j['titulo'] ?? '',
        fechaPublicacion: j['fecha_publicacion'] ?? '',
        fechaLimite: j['fecha_limite'] ?? '',
        estatus: j['estatus'] ?? '',
      );
}

class _PostulacionCard extends StatelessWidget {
  final PostulacionRevision postulacion;
  final Future<void> Function()? onActionDone;
  const _PostulacionCard({required this.postulacion, this.onActionDone});
  String _fmt(String s) => s.length >= 10 ? s.substring(0, 10) : s;

  Future<void> _aceptar(BuildContext context) async {
    try {
      final provider = context.read<UserDataProvider>();
      final headers = await provider.getAuthHeaders();
      final uri = Uri.parse('https://oda-talent-back-81413836179.us-central1.run.app/api/reclutadores/reclutar');
      final body = jsonEncode({
        'id_postulacion': postulacion.idPostulacion,
        'id_vacante': postulacion.idVacante,
        'estatus': 'Reclutado',
      });
      final resp = await http.put(uri, headers: headers, body: body);
      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Postulación aceptada')));
        if (onActionDone != null) onActionDone!();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al aceptar: ${resp.statusCode}')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Excepción al aceptar: $e')));
    }
  }

  Future<void> _rechazar(BuildContext context) async {
    try {
      final provider = context.read<UserDataProvider>();
      final headers = await provider.getAuthHeaders();
      final uri = Uri.parse('https://oda-talent-back-81413836179.us-central1.run.app/api/reclutadores/rechazar_postulacion');
      final body = jsonEncode({
        'id_postulacion': postulacion.idPostulacion,
        'estatus': 'Rechazado',
      });
      final resp = await http.put(uri, headers: headers, body: body);
      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Postulación rechazada')));
        if (onActionDone != null) onActionDone!();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al rechazar: ${resp.statusCode}')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Excepción al rechazar: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 22),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black54, width: 1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            postulacion.titulo,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Colors.black87),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text('Publicación: ${_fmt(postulacion.fechaPublicacion)}', style: const TextStyle(fontSize: 14, color: Colors.black87)),
          const SizedBox(height: 4),
          Text('Límite: ${_fmt(postulacion.fechaLimite)}', style: const TextStyle(fontSize: 14, color: Colors.black87)),
          const SizedBox(height: 14),
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.black54, width: 1.6),
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.expand_more, size: 18, color: Colors.black87),
          ),
          const SizedBox(height: 16),
            Text(
              postulacion.estatus.toUpperCase(),
              style: TextStyle(
                color: theme.secundario(),
                fontWeight: FontWeight.w800,
                letterSpacing: .2,
              ),
            ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SimpleButton(
                title: 'Aceptar',
                icon: Icons.check,
                backgroundColor: theme.secundario(),
                textColor: theme.primario(),
                onTap: () => _aceptar(context),
              ),
              const SizedBox(width: 12),
              SimpleButton(
                title: 'Rechazar',
                icon: Icons.close,
                backgroundColor: Colors.blueGrey,
                textColor: theme.primario(),
                onTap: () => _rechazar(context),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

