import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
// removed: import 'package:go_router/go_router.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:vinculed_app_1/src/ui/pages/candidato/busqueda.dart';
import 'package:vinculed_app_1/src/ui/pages/candidato/notificaciones.dart';
import 'package:vinculed_app_1/src/ui/pages/candidato/perfil.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import 'package:vinculed_app_1/src/core/controllers/theme_controller.dart';
import 'package:vinculed_app_1/src/core/providers/user_provider.dart';
// removed: import 'package:vinculed_app_1/src/ui/widgets/elements/footer.dart';
import 'package:vinculed_app_1/src/ui/widgets/buttons/simple_buttons.dart';
import 'package:vinculed_app_1/src/ui/widgets/text_inputs/roles_multi_dropdown.dart';
import 'package:vinculed_app_1/src/ui/widgets/text_inputs/text_form_field.dart';
import 'package:vinculed_app_1/src/ui/widgets/text_inputs/experience_text_area.dart';

class CreateExperiencePage extends StatefulWidget {
  const CreateExperiencePage({super.key});

  @override
  State<CreateExperiencePage> createState() => _CreateExperiencePageState();
}

class _CreateExperiencePageState extends State<CreateExperiencePage> {
  final _scrollCtrl = ScrollController();
  final _contentCtrl = TextEditingController();
  // Nuevos controladores para paridad con web
  final _titleCtrl = TextEditingController();
  final _youtubeCtrl = TextEditingController();
  YoutubePlayerController? _ytController;
  bool _hideYoutube = false; // ocultar preview cuando dropdown está abierto
  final usuario = FirebaseAuth.instance.currentUser!;

  // Roles múltiples seleccionados
  List<RoleOption> _selectedRoles = [];

  // Límite de caracteres
  static const int _maxChars = 5000;

  @override
  void initState() {
    super.initState();
    // removed scroll listener related to footer visibility
    _contentCtrl.addListener(() { if (mounted) setState(() {}); });
  }

  // removed _handleScroll()

  @override
  void dispose() {
    // simplified dispose
    _scrollCtrl.dispose();
    _contentCtrl.dispose();
    _titleCtrl.dispose();
    _youtubeCtrl.dispose();
    _ytController?.dispose();
    super.dispose();
  }

  void _initYoutube(String url) {
    final id = YoutubePlayer.convertUrlToId(url);
    if (id == null) {
      setState(() => _ytController = null);
      return;
    }
    _ytController = YoutubePlayerController(
      initialVideoId: id,
      flags: const YoutubePlayerFlags(
        autoPlay: false,
        mute: false,
        disableDragSeek: false,
        enableCaption: true,
        forceHD: false,
      ),
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;
    final isMobile = MediaQuery.of(context).size.width < 720;

    return Scaffold(
      backgroundColor: theme.background(),
      appBar: AppBar(
        backgroundColor: theme.background(),
        automaticallyImplyLeading: false,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Image.asset('assets/images/graduate.png', width: 50, height: 50),

            Row(
              children: [
                IconButton(
                  icon: Icon(Icons.search, color: theme.primario()),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => Busqueda()),
                    );
                  },
                ),
                IconButton(
                  icon: Icon(Icons.notifications_none, color: theme.primario()),
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => Notificaciones()),
                    );
                  },
                ),
                IconButton(
                  icon: CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.blue[50],
                    backgroundImage: usuario.photoURL != null ? NetworkImage(usuario.photoURL!) : null,
                    child: usuario.photoURL == null ? const Icon(Icons.person, size: 18, color: Colors.blueGrey) : null,
                  ),
                  onPressed: () {
                    // Acción para perfil
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const Perfil()),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
        elevation: 0,
      ),
      // removed AppBar (header)
      body: SafeArea(
        child: SingleChildScrollView(
          controller: _scrollCtrl,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  
                  Row(
                    children: [
                      IconButton(
                        tooltip: 'Regresar',
                        onPressed: () => Navigator.maybePop(context),
                        icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                      ),
                      Text(
                        'Crear Experiencia',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: isMobile ? 24 : 34,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF22313F),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Título
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: StyledTextFormField(
                      isRequired: true,
                      controller: _titleCtrl,
                      title: 'Título',
                      maxLength: 120,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Ingresa un título';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Roles múltiples
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: RolesMultiDropdown(
                      label: 'Roles relacionados',
                      hintText: '',
                      initialSelectedIds: _selectedRoles.map((r) => r.id).toList(),
                      onChanged: (roles) => setState(() => _selectedRoles = roles),
                      onOpen: () => setState(() => _hideYoutube = true),
                      onClose: () => setState(() => _hideYoutube = false),
                    ),
                  ),
                  const SizedBox(height: 14),
                  // URL YouTube
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: StyledTextFormField(
                            isRequired: false,
                            controller: _youtubeCtrl,
                            title: 'URL de YouTube (opcional)',
                            keyboardType: TextInputType.url,
                            onChanged: (val) => _initYoutube(val.trim()),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Tooltip(
                          message: 'Puedes añadir un enlace a un video de YouTube si quieres compartir más detalles de tu experiencia.',
                          //waitDuration: Duration(milliseconds: 300),
                          child: Icon(Icons.info_outline, color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                  if (_ytController != null) ...[
                    const SizedBox(height: 12),
                    Offstage(
                      offstage: _hideYoutube,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 560, minHeight: 200),
                        child: AspectRatio(
                          aspectRatio: 16 / 9,
                          child: YoutubePlayer(
                            controller: _ytController!,
                            showVideoProgressIndicator: true,
                            progressIndicatorColor: Colors.redAccent,
                            bottomActions: const [
                              CurrentPosition(),
                              SizedBox(width: 8),
                              ProgressBar(isExpanded: true),
                              RemainingDuration(),
                              FullScreenButton(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  // Contenido
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: Column(
                      children: [
                        ExperienceTextArea(
                          controller: _contentCtrl,
                          hintText: '¿Qué nos quieres compartir?',
                          height: 220,
                          maxLength: _maxChars,
                        ),
                        const SizedBox(height: 6),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            '${_contentCtrl.text.length}/$_maxChars',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  // Publicar
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 360),
                    child: SimpleButton(title: 'Publicar', onTap: _onPublish),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _onPublish() async {
    final titulo = _titleCtrl.text.trim();
    final contenido = _contentCtrl.text.trim();
    final url = _youtubeCtrl.text.trim();
    if (titulo.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ingresa un título.')));
      return;
    }
    if (contenido.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ingresa contenido.')));
      return;
    }
    if (contenido.length > _maxChars) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Máximo $_maxChars caracteres.')));
      return;
    }
    if (_selectedRoles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selecciona al menos un rol.')));
      return;
    }
    try {
      final userProv = Provider.of<UserDataProvider>(context, listen: false);
      final idAlumno = userProv.idRol;
      if (idAlumno == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No se encontró id_alumno')));
        return;
      }
      final headers = await userProv.getAuthHeaders();
      final body = jsonEncode({
        'id_alumno': idAlumno,
        'titulo': titulo,
        'contenido': contenido,
        if (url.isNotEmpty) 'url_multimedia': url,
        'roles_relacionados': _selectedRoles.map((r) => {'id_roltrabajo': r.id}).toList(),
      });
      final resp = await http.post(
        Uri.parse('https://oda-talent-back-81413836179.us-central1.run.app/api/experiencias_alumnos/crear_experiencia'),
        headers: headers,
        body: body,
      );
      if (resp.statusCode == 201 || (resp.statusCode >= 200 && resp.statusCode < 300)) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Experiencia publicada')));
        if (mounted) Navigator.maybePop(context);
        return;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error ${resp.statusCode} al publicar')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Excepción: $e')));
    }
  }
}
