import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
//import 'dart:html' as html; // para abrir nueva pestaña en Web
import 'package:url_launcher/url_launcher.dart';

import 'package:vinculed_app_1/src/core/controllers/theme_controller.dart';
import 'package:vinculed_app_1/src/ui/widgets/elements/footer.dart';
import 'package:vinculed_app_1/src/ui/widgets/elements/header2.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:vinculed_app_1/src/core/providers/user_provider.dart';
import 'package:vinculed_app_1/src/ui/widgets/buttons/simple_buttons.dart';
import 'package:vinculed_app_1/src/ui/widgets/text_inputs/text_form_field.dart';
import 'package:vinculed_app_1/src/ui/widgets/text_inputs/dropdown.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart' as fs;

import 'package:vinculed_app_1/src/ui/widgets/elements/perfilAlumno/habilidad_clase.dart';
// Secciones
import 'package:vinculed_app_1/src/ui/widgets/elements/perfilAlumno/escolaridad_section.dart';
import 'package:vinculed_app_1/src/ui/widgets/elements/perfilAlumno/experiencia_section.dart';
import 'package:vinculed_app_1/src/ui/widgets/elements/perfilAlumno/cursos_section.dart';
import 'package:vinculed_app_1/src/ui/widgets/elements/perfilAlumno/certificado_section.dart';
import 'package:vinculed_app_1/src/ui/widgets/elements/perfilAlumno/habilidades_tipo_section.dart';
import 'package:vinculed_app_1/src/ui/widgets/elements/perfilAlumno/urls_section.dart';

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({super.key});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  final _scrollCtrl = ScrollController();
  bool _showFooter = false;
  final usuario = FirebaseAuth.instance.currentUser!;
  String? _fotoUrl; // URL de foto resuelta/saneada para mostrar

  static const double _footerReservedSpace = EscomFooter.height;
  static const double _extraBottomPadding = 24.0;
  static const double _atEndThreshold = 4.0;


  // Estado de carga
  bool _loading = false;
  String? _error;
  AlumnoPerfil? _perfil;

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_handleScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _tryFetch();
      _handleScroll();
    });
  }

  void _tryFetch() {
    final idAlumno = context.read<UserDataProvider>().idRol; // según petición
    //print( 'Intentando obtener perfil para id_alumno: $idAlumno');
    if (idAlumno != null) {
      _fetchPerfil(idAlumno);
    } else {
      // Si aún no está el id, reintentar tras breve delay
      Future.delayed(const Duration(milliseconds: 400), _tryFetch);
    }
  }

  Future<void> _fetchPerfil(int idAlumno) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final provider = context.read<UserDataProvider>();
    final uri = Uri.parse('https://oda-talent-back-81413836179.us-central1.run.app/api/alumnos/perfil?id_alumno=$idAlumno');
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
            case "Explorar Puestos en TI":
              context.go('/alumno/preferences');
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

  // Reemplazado: ahora recibe bytes en lugar de File y usa putData (compatible Web)
  Future<String> _uploadCvToStorage(Uint8List bytes, int idAlumno) async {
    final storage = fs.FirebaseStorage.instance;
    // Carpeta única por alumno (uid) y nombre fijo del archivo
    final baseFolder = 'cv/${usuario.uid}';
    final fileName = 'cv.pdf';
    final folderRef = storage.ref().child(baseFolder);

    // Borrar cualquier archivo previo (mantener solo uno)
    try {
      final existing = await folderRef.listAll();
      for (final item in existing.items) {
        // Si coincide con nombre anterior (o cualquiera) lo borramos
        await item.delete();
      }
    } catch (_) {
      // Ignorar errores (por ejemplo carpeta inexistente)
    }

    final path = '$baseFolder/$fileName';
    final ref = storage.ref().child(path);
    await ref.putData(bytes, fs.SettableMetadata(contentType: 'application/pdf'));
    // Obtener URL de descarga para mostrar/usar externamente (aunque backend sólo guarde path si así lo requiere)
    //final downloadUrl = await ref.getDownloadURL();
    return path; // retornamos URL pública
  }

  Future<void> _sendCvUrlToBackend(int idAlumno, String url) async {
    final provider = context.read<UserDataProvider>();
    final uri = Uri.parse('https://oda-talent-back-81413836179.us-central1.run.app/api/alumnos/perfil/subir_cv');
    final headers = await provider.getAuthHeaders();
    final resp = await http.put(
      uri,
      headers: headers,
      //body: jsonEncode({'id_alumno': idAlumno, 'url_cv': url}),
      body: jsonEncode({'url_cv': url}),
    );
    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      throw Exception('HTTP ${data['message']}');
    }
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

  Future<String> _uploadFotoToStorage(Uint8List bytes, String ext) async {
    final storage = fs.FirebaseStorage.instance;
    final baseFolder = 'foto_perfil/${usuario.uid}';
    final folderRef = storage.ref().child(baseFolder);
    // Eliminar anteriores (solo una foto vigente)
    try {
      final existing = await folderRef.listAll();
      for (final item in existing.items) {
        await item.delete();
      }
    } catch (_) {}
    final path = '$baseFolder/avatar.$ext';
    final contentType = ext == 'png' ? 'image/png' : 'image/jpeg';
    final ref = storage.ref().child(path);
    await ref.putData(bytes, fs.SettableMetadata(contentType: contentType));
    final downloadUrl = await ref.getDownloadURL();
    return downloadUrl;
  }

  Future<void> _sendFotoUrlToBackend(int idAlumno, String url) async {
    final provider = context.read<UserDataProvider>();
    final uri = Uri.parse('https://oda-talent-back-81413836179.us-central1.run.app/api/alumnos/perfil/actualizar_foto');
    final headers = await provider.getAuthHeaders();
    final resp = await http.put(
      uri,
      headers: headers,
      body: jsonEncode({'id_alumno':idAlumno,'url_foto': url}),
    );
    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw Exception('HTTP ${resp.statusCode}');
    }
  }

  Future<void> _openFoto() async {
    try {
      final ref = fs.FirebaseStorage.instance.ref().child('foto_perfil/${usuario.uid}/avatar.jpg');
      final url = await ref.getDownloadURL();
      final Uri uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw 'No se pudo lanzar la URL de la foto';
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No se pudo abrir la foto: $e')));
    }
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
                          onUploadCv: () async {
                            String? uploadedPath;
                            try {
                              final idAlumno = perfil.idAlumno;
                              final result = await FilePicker.platform.pickFiles(
                                type: FileType.custom,
                                allowedExtensions: ['pdf'],
                                withData: true,
                              );
                              if (result == null || result.files.isEmpty) return;
                              final fileBytes = result.files.first.bytes;
                              final name = result.files.first.name.toLowerCase();
                              if (fileBytes == null) return;
                              if (!name.endsWith('.pdf')) {
                                if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selecciona un archivo PDF')));
                                return;
                              }
                              if (fileBytes.length > 1024 * 1024) {
                                if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('El archivo debe pesar máximo 1MB')));
                                return;
                              }
                              // Subida directa con bytes (un solo archivo por alumno)
                              uploadedPath = await _uploadCvToStorage(fileBytes, idAlumno); // esto es la URL
                              await _sendCvUrlToBackend(idAlumno, uploadedPath);
                              if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('CV actualizado')));
                              await _fetchPerfil(idAlumno);
                            } on fs.FirebaseException catch (e) {
                              if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al subir CV a Firebase: ${e.message}')));
                            } on Exception catch (e) {
                              // rollback si error backend tras subir
                              if (uploadedPath != null && e.toString().contains('HTTP')) {
                                try {
                                  // Como guardamos sólo un archivo, lo eliminamos buscando cv.pdf
                                  final storage = fs.FirebaseStorage.instance;
                                  final baseFolder = 'cv/${usuario.uid}';
                                  final ref = storage.ref().child('$baseFolder/cv.pdf');
                                  await ref.delete();
                                } catch (_) {}
                              }
                              if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al subir CV: $e')));
                            }
                          },
                          onViewCv: () async => _openCv(perfil.urlCv),
                          onUploadPhoto: () async {
                            String? downloadUrl;
                            String? ext;
                            try {
                              final idAlumno = perfil.idAlumno;
                              final result = await FilePicker.platform.pickFiles(
                                type: FileType.custom,
                                allowedExtensions: ['png', 'jpg', 'jpeg'],
                                withData: true,
                              );
                              if (result == null || result.files.isEmpty) return;
                              final file = result.files.first;
                              final bytes = file.bytes;
                              if (bytes == null) return;
                              ext = file.extension?.toLowerCase();
                              if (ext == 'jpeg') ext = 'jpg';
                              if (ext == null || !(ext == 'png' || ext == 'jpg')) {
                                if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Formato inválido (usa PNG/JPG)')));
                                return;
                              }
                              if (bytes.length > 2 * 1024 * 1024) {
                                if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('La imagen debe pesar máximo 2MB')));
                                return;
                              }
                              downloadUrl = await _uploadFotoToStorage(bytes, ext);
                              await _sendFotoUrlToBackend(idAlumno, downloadUrl);
                              try { await usuario.updatePhotoURL(downloadUrl); await usuario.reload(); } catch (_) {}
                              if (mounted) setState(() => _fotoUrl = downloadUrl);
                              if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Foto de perfil actualizada')));
                              await _fetchPerfil(idAlumno);
                            } on fs.FirebaseException catch (e) {
                              if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error Firebase: ${e.message}')));
                              try {
                                if (ext != null) {
                                  final storage = fs.FirebaseStorage.instance;
                                  final path = 'foto_perfil/${usuario.uid}/avatar.$ext';
                                  await storage.ref().child(path).delete();
                                }
                              } catch (_) {}
                            } catch (e) {
                              if (ext != null && e.toString().contains('HTTP')) {
                                try {
                                  final storage = fs.FirebaseStorage.instance;
                                  final path = 'foto_perfil/${usuario.uid}/avatar.$ext';
                                  await storage.ref().child(path).delete();
                                } catch (_) {}
                              }
                              if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al subir foto: $e')));
                            }
                          },
                        ),
                        const SizedBox(height: 18),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: perfil.completado == 1 ?
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
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                perfil.nombre ?? usuario.displayName ?? 'Sin nombre',
                                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Color(0xFF1F2A36)),
                              ),
                              const SizedBox(height: 6),
                              const Text('Alumno', style: TextStyle(fontSize: 16, color: Colors.black87)),
                              const SizedBox(height: 6),
                              const Row(
                                children: [
                                  Icon(Icons.info_outline_rounded, color: Colors.redAccent, size: 16),
                                  SizedBox(width: 6),
                                  Expanded(child: Text('Completa tu perfil para poder postularte a vacantes y así los reclutadores se fijen en tí. Al menos llena los siguientes datos: Descripción, Ciudad, Entidad, Semestre Actual y agrega una habilidad.', style: TextStyle(fontSize: 14, color: Colors.redAccent))),
                                ],
                              )
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
                                      emptyText: 'Agrega dónde has estudiado',
                                      onUpdated: () => _fetchPerfil(perfil.idAlumno),
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
                                      emptyText: 'Agrega tu experiencia laboral',
                                      onUpdated: () => _fetchPerfil(perfil.idAlumno),
                                    ),
                                    const SizedBox(height: 16),
                                    // Cursos (reemplazado por sección editable)
                                    CursosSection(
                                      items: perfil.cursos,
                                      emptyText: 'Agrega tus cursos',
                                      onUpdated: () => _fetchPerfil(perfil.idAlumno),
                                    ),
                                    const SizedBox(height: 16),
                                    // Certificados (reemplazado por sección editable)
                                    CertificadosSection(
                                      items: perfil.certificados,
                                      emptyText: 'Agrega tus certificados',
                                      onUpdated: () => _fetchPerfil(perfil.idAlumno),
                                    ),
                                    const SizedBox(height: 16),
                                    // Habilidades Técnicas
                                    HabilidadesTipoSection(
                                      title: 'Habilidades Técnicas',
                                      tipoDisplay: 'Técnicas',
                                      idAlumno: perfil.idAlumno,
                                      items: perfil.habilidades.where((h) => _isTecnica(h)).toList(),
                                      emptyText: 'Agrega tus habilidades técnicas',
                                      onUpdated: () => _fetchPerfil(perfil.idAlumno),
                                    ),
                                    const SizedBox(height: 16),
                                    // Habilidades Blandas
                                    HabilidadesTipoSection(
                                      title: 'Habilidades Blandas',
                                      tipoDisplay: 'Blandas',
                                      idAlumno: perfil.idAlumno,
                                      items: perfil.habilidades.where((h) => _isBlanda(h)).toList(),
                                      emptyText: 'Agrega tus habilidades blandas',
                                      onUpdated: () => _fetchPerfil(perfil.idAlumno),
                                    ),
                                    const SizedBox(height: 16),
                                    // Idiomas
                                    HabilidadesTipoSection(
                                      title: 'Idiomas',
                                      tipoDisplay: 'Idiomas',
                                      idAlumno: perfil.idAlumno,
                                      items: perfil.habilidades.where((h) => _isIdioma(h)).toList(),
                                      emptyText: 'Agrega tus idiomas',
                                      onUpdated: () => _fetchPerfil(perfil.idAlumno),
                                    ),
                                    const SizedBox(height: 16),
                                    UrlsSection(
                                      items: perfil.urlsExternas,
                                      emptyText: 'Agrega tus Enlaces personales (LinkedIn, GitHub, Portafolio, etc.)',
                                      onUpdated: () => _fetchPerfil(perfil.idAlumno),
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
                                            emptyText: 'Agrega dónde has estudiado',
                                            onUpdated: () => _fetchPerfil(perfil.idAlumno),
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
                                            emptyText: 'Agrega tu experiencia laboral',
                                            onUpdated: () => _fetchPerfil(perfil.idAlumno),
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
                                          // Cursos (reemplazado por sección editable)
                                          CursosSection(
                                            items: perfil.cursos,
                                            emptyText: 'Agrega tus cursos',
                                            onUpdated: () => _fetchPerfil(perfil.idAlumno),
                                          ),
                                        ),
                                        const SizedBox(width: 24),
                                        Expanded(
                                          child: CertificadosSection(
                                            items: perfil.certificados,
                                            emptyText: 'Agrega tus certificados',
                                            onUpdated: () => _fetchPerfil(perfil.idAlumno),
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
                                            emptyText: 'Agrega tus habilidades técnicas',
                                            onUpdated: () => _fetchPerfil(perfil.idAlumno),
                                          ),
                                        ),
                                        
                                        const SizedBox(width: 24),
                                        Expanded(
                                          child: UrlsSection(
                                            items: perfil.urlsExternas,
                                            emptyText: 'Agrega tus Enlaces personales (LinkedIn, GitHub, Portafolio, etc.)',
                                            onUpdated: () => _fetchPerfil(perfil.idAlumno),
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
                                            emptyText: 'Agrega tus habilidades blandas',
                                            onUpdated: () => _fetchPerfil(perfil.idAlumno),
                                          ),
                                        ),
                                        const SizedBox(width: 24),
                                        Expanded(
                                          child: HabilidadesTipoSection(
                                            title: 'Idiomas',
                                            tipoDisplay: 'Idiomas',
                                            idAlumno: perfil.idAlumno,
                                            items: perfil.habilidades.where((h) => _isIdioma(h)).toList(),
                                            emptyText: 'Agrega los idiomas que hablas',
                                            onUpdated: () => _fetchPerfil(perfil.idAlumno),
                                          ),
                                        ),
                                        
                                        
                                      ],
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
    if (urlCv == null || urlCv.isEmpty) return 'Sube tu CV';
    final uri = Uri.tryParse(urlCv);
    if (uri == null) return 'CV';
    return uri.pathSegments.isNotEmpty ? uri.pathSegments.last : 'CV';
  }

  List<_InfoItem> _leftItems(AlumnoPerfil p) => [
        _InfoItem(label: 'Correo Electrónico:', value: _nullOr(p.correo, 'Ingresa tu correo'), editable: false, icon: null),
        _InfoItem(label: 'Ciudad:', value: _nullOr(p.ciudad, 'Ingresa tu ciudad'), editable: true, icon: Icons.edit_outlined, onEdit: () => _openEditCiudadEntidad(p)),
        _InfoItem(label: 'Entidad:', value: _nullOr(p.entidad, 'Ingresa tu entidad'), editable: true, icon: Icons.edit_outlined, onEdit: () => _openEditCiudadEntidad(p)),
        _InfoItem(label: 'Teléfono:', value: _nullOr(p.telefono, 'Ingresa tu número de teléfono'), editable: true, icon: Icons.edit_outlined, onEdit: () => _openEditTelefono(p)),
        _InfoItem(label: 'Semestre Actual:', value: p.semestreActual?.toString() ?? 'Ingresa tu semestre', editable: true, icon: Icons.edit_outlined, onEdit: () => _openEditSemestre(p)),
      ];

  List<_InfoItem> _rightItems(AlumnoPerfil p) => [
        _InfoItem(label: 'Descripción:', value: _nullOr(p.descripcion, 'Agrega una descripción'), editable: true, icon: Icons.edit_outlined, multiLine: true, onEdit: () => _openEditDescripcion(p)),
        _InfoItem(label: 'Fecha de Nacimiento:', value: _nullOr(p.fechaNacimiento?.substring(0, (p.fechaNacimiento?.length ?? 0) >= 10 ? 10 : (p.fechaNacimiento?.length ?? 0)), 'Agrega tu fecha de nacimiento'), editable: true, icon: Icons.edit_outlined, onEdit: () => _openEditFechaNacimiento(p)),
        _InfoItem(label: 'Visualizaciones:', value: p.visualizaciones?.toString() ?? '0', editable: false, icon: Icons.visibility),
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

  Future<void> _saveCiudadEntidad({required int idAlumno, required String ciudad, required String entidad}) async {
    final provider = context.read<UserDataProvider>();
    final uri = Uri.parse('https://oda-talent-back-81413836179.us-central1.run.app/api/alumnos/perfil/actualizar_ciudad_entidad');
    final headers = await provider.getAuthHeaders();
    final resp = await http.put(
      uri,
      headers: headers,
      body: jsonEncode({'id_alumno': idAlumno, 'ciudad': ciudad, 'entidad': entidad}),
    );
    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw Exception('HTTP ${resp.statusCode}');
    }
  }

  Future<void> _saveTelefono({required int idAlumno, required String telefono}) async {
    final provider = context.read<UserDataProvider>();
    final uri = Uri.parse('https://oda-talent-back-81413836179.us-central1.run.app/api/alumnos/perfil/actualizar_telefono');
    final headers = await provider.getAuthHeaders();
    final resp = await http.put(
      uri,
      headers: headers,
      body: jsonEncode({'id_alumno': idAlumno, 'telefono': telefono}),
    );
    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw Exception('HTTP ${resp.statusCode}');
    }
  }

  Future<void> _saveSemestre({required int idAlumno, required String semestre}) async {
    final provider = context.read<UserDataProvider>();
    final uri = Uri.parse('https://oda-talent-back-81413836179.us-central1.run.app/api/alumnos/perfil/actualizar_semestre');
    final headers = await provider.getAuthHeaders();
    final resp = await http.put(
      uri,
      headers: headers,
      body: jsonEncode({'id_alumno': idAlumno, 'semestre_actual': semestre}),
    );
    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw Exception('HTTP ${resp.statusCode}');
    }
  }

  Future<void> _saveDescripcion({required int idAlumno, required String descripcion}) async {
    final provider = context.read<UserDataProvider>();
    final uri = Uri.parse('https://oda-talent-back-81413836179.us-central1.run.app/api/alumnos/perfil/actualizar_descripcion');
    final headers = await provider.getAuthHeaders();
    final resp = await http.put(
      uri,
      headers: headers,
      body: jsonEncode({'id_alumno': idAlumno, 'descripcion': descripcion}),
    );
    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw Exception('HTTP ${resp.statusCode}');
    }
  }

  Future<void> _saveFechaNacimiento({required int idAlumno, required String fecha}) async {
    final provider = context.read<UserDataProvider>();
    final uri = Uri.parse('https://oda-talent-back-81413836179.us-central1.run.app/api/alumnos/perfil/actualizar_fecha_nacimiento');
    final headers = await provider.getAuthHeaders();
    final resp = await http.put(
      uri,
      headers: headers,
      body: jsonEncode({'id_alumno': idAlumno, 'fecha_nacimiento': fecha}),
    );
    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw Exception('HTTP ${resp.statusCode}');
    }
  }

  Future<void> _openEditCiudadEntidad(AlumnoPerfil p) async {
    final formKey = GlobalKey<FormState>();
    final ciudadCtrl = TextEditingController(text: p.ciudad ?? '');
    final entidadCtrl = TextEditingController(text: p.entidad ?? '');
    bool saving = false;
    await showDialog(
      context: context,
      builder: (dctx) => StatefulBuilder(
        builder: (ctx, setState) {
          final isMobile = MediaQuery.of(ctx).size.width < 700;
          final cancelarBtn = SimpleButton(title: 'Cancelar', icon: Icons.close_outlined, backgroundColor: Colors.blueGrey, textColor: Colors.white, onTap: () => Navigator.pop(dctx));
          final guardarBtn = SimpleButton(
            title: saving ? 'Guardando...' : 'Guardar',
            icon: Icons.save_outlined,
            onTap: saving
                ? null
                : () async {
                    if (!formKey.currentState!.validate()) return;
                    setState(() => saving = true);
                    try {
                      await _saveCiudadEntidad(idAlumno: p.idAlumno, ciudad: ciudadCtrl.text.trim(), entidad: entidadCtrl.text.trim());
                      Navigator.pop(dctx);
                      await _fetchPerfil(p.idAlumno);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ciudad/Entidad actualizadas')));
                    } catch (e) {
                      setState(() => saving = false);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                    }
                  },
          );
          return AlertDialog(
            title: const Text('Editar Ciudad y Entidad'),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  StyledTextFormField(
                    isRequired: true,
                    title: 'Ciudad',
                    controller: ciudadCtrl,
                    validator: (v) {
                      final had = (p.ciudad != null && p.ciudad!.trim().isNotEmpty);
                      if (had && (v == null || v.trim().isEmpty)) return 'No puede quedar vacío';
                      return null;
                    },
                  ),
                  StyledTextFormField(
                    isRequired: true,
                    title: 'Entidad',
                    controller: entidadCtrl,
                    validator: (v) {
                      final had = (p.entidad != null && p.entidad!.trim().isNotEmpty);
                      if (had && (v == null || v.trim().isEmpty)) return 'No puede quedar vacío';
                      return null;
                    },
                  ),
                ],
              ),
            ),
            actions: isMobile
                ? [
                    Center(
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 12,
                        runSpacing: 8,
                        children: [cancelarBtn, guardarBtn],
                      ),
                    ),
                  ]
                : [cancelarBtn, guardarBtn],
          );
        },
      ),
    );
  }

  Future<void> _openEditTelefono(AlumnoPerfil p) async {
    final formKey = GlobalKey<FormState>();
    final telCtrl = TextEditingController(text: p.telefono ?? '');
    bool saving = false;
    await showDialog(
      context: context,
      builder: (dctx) => StatefulBuilder(
        builder: (ctx, setState) {
          final isMobile = MediaQuery.of(ctx).size.width < 700;
          final cancelarBtn = SimpleButton(title: 'Cancelar', icon: Icons.close_outlined, backgroundColor: Colors.blueGrey, textColor: Colors.white, onTap: () => Navigator.pop(dctx));
          final guardarBtn = SimpleButton(
            title: saving ? 'Guardando...' : 'Guardar',
            icon: Icons.save_outlined,
            onTap: saving
                ? null
                : () async {
                    if (!formKey.currentState!.validate()) return;
                    setState(() => saving = true);
                    try {
                      await _saveTelefono(idAlumno: p.idAlumno, telefono: telCtrl.text.trim());
                      Navigator.pop(dctx);
                      await _fetchPerfil(p.idAlumno);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Teléfono actualizado')));
                    } catch (e) {
                      setState(() => saving = false);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                    }
                  },
          );
          return AlertDialog(
            title: const Text('Editar Teléfono'),
            content: Form(
              key: formKey,
              child: StyledTextFormField(
                isRequired: true,
                title: 'Teléfono',
                controller: telCtrl,
                validator: (v) {
                  // simple validation optional
                  if (v != null && v.trim().isNotEmpty && !RegExp(r'^[0-9+\-\s]{10}$').hasMatch(v.trim())) {
                    return 'Teléfono inválido';
                  }
                  return null;
                },
              ),
            ),
            actions: isMobile
                ? [
                    Center(
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 12,
                        runSpacing: 8,
                        children: [cancelarBtn, guardarBtn],
                      ),
                    ),
                  ]
                : [cancelarBtn, guardarBtn],
          );
        },
      ),
    );
  }

  Future<void> _openEditSemestre(AlumnoPerfil p) async {
    String? selected = p.semestreActual?.toString();
    bool saving = false;
    await showDialog(
      context: context,
      builder: (dctx) => StatefulBuilder(
        builder: (ctx, setState) {
          final isMobile = MediaQuery.of(ctx).size.width < 700;
          final cancelarBtn = SimpleButton(title: 'Cancelar', icon: Icons.close_outlined, backgroundColor: Colors.blueGrey, textColor: Colors.white, onTap: () => Navigator.pop(dctx));
          final guardarBtn = SimpleButton(
            title: saving ? 'Guardando...' : 'Guardar',
            icon: Icons.save_outlined,
            onTap: saving
                ? null
                : () async {
                    final had = p.semestreActual != null; // si ya tenía valor, no permitir vacío
                    if (had && (selected == null || selected!.trim().isEmpty)) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('El semestre no puede quedar vacío')));
                      return;
                    }
                    if (selected == null || selected!.trim().isEmpty) {
                      // permitir si no tenía; pero si no selecciona nada, no hacemos PUT
                      Navigator.pop(dctx);
                      return;
                    }
                    setState(() => saving = true);
                    try {
                      await _saveSemestre(idAlumno: p.idAlumno, semestre: selected!);
                      Navigator.pop(dctx);
                      await _fetchPerfil(p.idAlumno);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Semestre actualizado')));
                    } catch (e) {
                      setState(() => saving = false);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                    }
                  },
          );
          return AlertDialog(
            title: const Text('Editar Semestre Actual'),
            content: DropdownInput<String>(
              value: selected,
              title: 'Selecciona semestre (1-12)',
              items: [for (var i = 1; i <= 12; i++) DropdownMenuItem(value: '$i', child: Text('$i'))],
              onChanged: (v) => setState(() => selected = v),
            ),
            actions: isMobile
                ? [
                    Center(
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 12,
                        runSpacing: 8,
                        children: [cancelarBtn, guardarBtn],
                      ),
                    ),
                  ]
                : [cancelarBtn, guardarBtn],
          );
        },
      ),
    );
  }

  Future<void> _openEditDescripcion(AlumnoPerfil p) async {
    final formKey = GlobalKey<FormState>();
    final descCtrl = TextEditingController(text: p.descripcion ?? '');
    bool saving = false;
    await showDialog(
      context: context,
      builder: (dctx) => StatefulBuilder(
        builder: (ctx, setState) {
          final isMobile = MediaQuery.of(ctx).size.width < 700;
          final cancelarBtn = SimpleButton(title: 'Cancelar', icon: Icons.close_outlined, backgroundColor: Colors.blueGrey, textColor: Colors.white, onTap: () => Navigator.pop(dctx));
          final guardarBtn = SimpleButton(
            title: saving ? 'Guardando...' : 'Guardar',
            icon: Icons.save_outlined,
            onTap: saving
                ? null
                : () async {
                    if (!formKey.currentState!.validate()) return;
                    setState(() => saving = true);
                    try {
                      await _saveDescripcion(idAlumno: p.idAlumno, descripcion: descCtrl.text.trim());
                      Navigator.pop(dctx);
                      await _fetchPerfil(p.idAlumno);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Descripción actualizada')));
                    } catch (e) {
                      setState(() => saving = false);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                    }
                  },
          );
          return AlertDialog(
            title: const Text('Editar Descripción'),
            content: Form(
              key: formKey,
              child: SizedBox(
                width: 500,
                child: StyledTextFormField(
                  isRequired: true,
                  title: 'Descripción',
                  controller: descCtrl,
                  maxLines: 6,
                  validator: (v) {
                    final had = (p.descripcion != null && p.descripcion!.trim().isNotEmpty);
                    if (had && (v == null || v.trim().isEmpty)) return 'No puede quedar vacío';
                    return null;
                  },
                ),
              ),
            ),
            actions: isMobile
                ? [
                    Center(
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 12,
                        runSpacing: 8,
                        children: [cancelarBtn, guardarBtn],
                      ),
                    ),
                  ]
                : [cancelarBtn, guardarBtn],
          );
        },
      ),
    );
  }

  Future<void> _openEditFechaNacimiento(AlumnoPerfil p) async {
    DateTime? selected;
    if (p.fechaNacimiento != null && p.fechaNacimiento!.length >= 10) {
      selected = DateTime.tryParse(p.fechaNacimiento!.substring(0, 10));
    }
    bool saving = false;
    await showDialog(
      context: context,
      builder: (dctx) => StatefulBuilder(
        builder: (ctx, setState) {
          final isMobile = MediaQuery.of(ctx).size.width < 700;
          final cancelarBtn = SimpleButton(title: 'Cancelar', icon: Icons.close_outlined, backgroundColor: Colors.blueGrey, textColor: Colors.white, onTap: () => Navigator.pop(dctx));
          final guardarBtn = SimpleButton(
            title: saving ? 'Guardando...' : 'Guardar',
            icon: Icons.save_outlined,
            onTap: saving
                ? null
                : () async {
                    final had = (p.fechaNacimiento != null && p.fechaNacimiento!.trim().isNotEmpty);
                    if (had && selected == null) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('La fecha no puede quedar vacía')));
                      return;
                    }
                    if (selected == null) { Navigator.pop(dctx); return; }
                    setState(() => saving = true);
                    try {
                      await _saveFechaNacimiento(idAlumno: p.idAlumno, fecha: _fmtDate(selected!));
                      Navigator.pop(dctx);
                      await _fetchPerfil(p.idAlumno);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fecha de nacimiento actualizada')));
                    } catch (e) {
                      setState(() => saving = false);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                    }
                  },
          );
          return AlertDialog(
            title: const Text('Editar Fecha de Nacimiento'),
            content: SizedBox(
              width: 360,
              child: Row(
                children: [
                  Expanded(
                    child: Text(selected != null ? _fmtDate(selected!) : 'Sin fecha', style: const TextStyle(color: Colors.black87)),
                  ),
                  IconButton(
                    tooltip: 'Seleccionar fecha',
                    icon: const Icon(Icons.calendar_today_outlined),
                    onPressed: () async {
                      final now = DateTime.now();
                      final init = selected ?? DateTime(now.year - 20, now.month, now.day);
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: init,
                        firstDate: DateTime(1950, 1, 1),
                        lastDate: DateTime(now.year, now.month, now.day),
                      );
                      if (picked != null) setState(() => selected = picked);
                    },
                  ),
                ],
              ),
            ),
            actions: isMobile
                ? [
                    Center(
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 12,
                        runSpacing: 8,
                        children: [cancelarBtn, guardarBtn],
                      ),
                    ),
                  ]
                : [cancelarBtn, guardarBtn],
          );
        },
      ),
    );
  }

  String _fmtDate(DateTime d) => '${d.year.toString().padLeft(4,'0')}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';
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
        idAlumno: j['id_alumno'] ?? 0,
        idUsuario: j['id_usuario'] ?? 0,
        nombre: j['nombre'],
        correo: j['correo'],
        fechaNacimiento: j['fecha_nacimiento'],
        telefono: j['telefono'],
        ciudad: j['ciudad'],
        entidad: j['entidad'],
        descripcion: j['descripcion'],
        urlCv: j['url_cv'],
        semestreActual: j['semestre_actual'],
        visualizaciones: j['visualizaciones'],
        urlFotoPerfil: j['url_foto_perfil'],
        completado: j['completado'],
        escolaridad: (j['escolaridad'] as List? ?? []).map((e) => EscolaridadItem.fromJson(e)).toList(),
        experienciaLaboral: (j['experiencia_laboral'] as List? ?? []).map((e) => ExperienciaItem.fromJson(e)).toList(),
        cursos: (j['cursos'] as List? ?? []).map((e) => CursoItem.fromJson(e)).toList(),
        certificados: (j['certificados'] as List? ?? []).map((e) => CertificadoItem.fromJson(e)).toList(),
        habilidades: (j['habilidades'] as List? ?? []).map((e) => HabilidadItem.fromJson(e)).toList(),
        urlsExternas: (j['urls_externas'] as List? ?? []).map((e) => UrlItem.fromJson(e)).toList(),
      );
}








/* ════════════════════════ Secciones Visuales existentes adaptadas ════════════════════════ */

class _BannerSection extends StatelessWidget {
  const _BannerSection({
    required this.isMobile,
    required this.cvName,
    required this.urlFoto,
    this.onUploadCv,
    this.onViewCv,
    this.onUploadPhoto,
  });

  final bool isMobile;
  final String cvName;
  final String? urlFoto;
  final Future<void> Function()? onUploadCv;
  final Future<void> Function()? onViewCv;
  final Future<void> Function()? onUploadPhoto;

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
            InkWell(
              onTap: onUploadCv,
              child: const Icon(Icons.attach_file, size: 18, color: Colors.black54),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: InkWell(
                onTap: onViewCv,
                child: Text(
                  cvName,
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
                onTap: onUploadPhoto,
                borderRadius: BorderRadius.circular(58),
                child: CircleAvatar(
                  radius: 58,
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
                      onTap: onUploadPhoto,
                      borderRadius: BorderRadius.circular(58),
                      child: CircleAvatar(
                        radius: 58,
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
  final bool editable;
  final bool multiLine;
  final IconData? icon;
  final VoidCallback? onEdit;
  const _InfoItem({
    required this.label,
    required this.value,
    required this.editable,
    required this.icon,
    this.multiLine = false,
    this.onEdit,
  });
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.item});
  final _InfoItem item;
  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: item.multiLine ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children:  [
        SizedBox(
          width: 190,
          child: Text(item.label, style: const TextStyle(fontWeight: FontWeight.w700)),
        ),
        Expanded(
          child: Text(item.value, style: item.value.contains('Ingresa') || item.value.contains('Agrega') ? const TextStyle(color: Colors.black54, height: 1.4): const TextStyle(color: Colors.black87, height: 1.4)),
        ),
        const SizedBox(width: 8),
        if (item.icon != null)
          IconButton(
            tooltip: item.editable ? 'Editar' : null,
            icon: Icon(item.icon, size: 18, color: Colors.black54),
            onPressed: item.editable && item.onEdit != null ? item.onEdit : null,
          ),
      ],
    );
  }
}

