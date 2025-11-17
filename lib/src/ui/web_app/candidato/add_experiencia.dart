import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:vinculed_app_1/src/core/controllers/theme_controller.dart';
import 'package:vinculed_app_1/src/core/providers/user_provider.dart';
import 'package:vinculed_app_1/src/ui/widgets/elements/footer.dart';
import 'package:vinculed_app_1/src/ui/widgets/buttons/simple_buttons.dart';
import 'package:vinculed_app_1/src/ui/widgets/elements/header2.dart';
import 'package:vinculed_app_1/src/ui/widgets/text_inputs/roles_multi_dropdown.dart';
import 'package:vinculed_app_1/src/ui/widgets/text_inputs/text_form_field.dart';
import 'package:vinculed_app_1/src/ui/widgets/text_inputs/experience_text_area.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

class CreateExperiencePage extends StatefulWidget {
  const CreateExperiencePage({super.key});

  @override
  State<CreateExperiencePage> createState() => _CreateExperiencePageState();
}

class _CreateExperiencePageState extends State<CreateExperiencePage> {
  final _scrollCtrl = ScrollController();
  final _contentCtrl = TextEditingController();
  final _titleCtrl = TextEditingController();
  final _youtubeCtrl = TextEditingController();

  bool _showFooter = false;
  YoutubePlayerController? _ytController;
  bool _hideYoutube = false; // cuando el modal está abierto

  static const double _footerReservedSpace = EscomFooter.height;
  static const double _extraBottomPadding = 24.0;
  static const double _atEndThreshold = 4.0;

  // --- NUEVO: límite de caracteres ---
  static const int _maxChars = 5000;

  // --- NUEVO: Roles múltiples ---
  List<RoleOption> _selectedRoles = [];

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_handleScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _handleScroll());

    // para actualizar el contador en vivo
    _contentCtrl.addListener(() {
      if (mounted) setState(() {});
    });
  }

  void _handleScroll() {
    final pos = _scrollCtrl.position;
    if (!pos.hasPixels || !pos.hasContentDimensions) return;

    // Si el contenido cabe en la pantalla, oculta el footer
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
    _contentCtrl.dispose();
    _titleCtrl.dispose();
    _youtubeCtrl.dispose();
    _ytController?.close();
    super.dispose();
  }

  void _initYoutube(String url) {
    final id = YoutubePlayerController.convertUrlToId(url);
    if (id == null) {
      _ytController = null;
      return;
    }
    _ytController = YoutubePlayerController.fromVideoId(
      videoId: id,
      params: const YoutubePlayerParams(
        showFullscreenButton: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;
    final isMobile = MediaQuery.of(context).size.width < 720;

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
              context.go('/alumno/faq ');
              break;
            case "Preferencias":
              context.go('/alumno/preferences');
              break;
          }
        },
      ),
      body: Stack(
        children: [
          // Contenido scrolleable
          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final minBodyHeight =
                    constraints.maxHeight - _footerReservedSpace - _extraBottomPadding;

                return SingleChildScrollView(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.only(
                    bottom: _footerReservedSpace + _extraBottomPadding,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 900),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: minBodyHeight > 0 ? minBodyHeight : 0,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Título
                              Text(
                                'Crear Experiencia',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: isMobile ? 28 : 34,
                                  fontWeight: FontWeight.w900,
                                  color: const Color(0xFF22313F),
                                ),
                              ),
                              const SizedBox(height: 24),

                              // --- NUEVO: Campo Título ---
                              ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 560),
                                child: StyledTextFormField(
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

                              // --- NUEVO: Dropdown múltiple de Roles ---
                              ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 560),
                                child: RolesMultiDropdown(
                                  label: 'Roles relacionados',
                                  hintText: '',
                                  initialSelectedIds: const [],
                                  authToken: null, // Se tomarán headers del provider en POST
                                  onChanged: (roles) {
                                    setState(() => _selectedRoles = roles);
                                  },
                                  onOpen: () => setState(() => _hideYoutube = true),
                                  onClose: () => setState(() => _hideYoutube = false),
                                ),
                              ),
                              const SizedBox(height: 14),

                              // Campo URL YouTube
                              ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 560),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Expanded(
                                      child: StyledTextFormField(
                                        controller: _youtubeCtrl,
                                        title: 'URL de YouTube (opcional)',
                                        keyboardType: TextInputType.url,
                                        onChanged: (val) {
                                          setState(() {
                                            _initYoutube(val.trim());
                                          });
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Tooltip(
                                      message: 'Puedes añadir un enlace a un video de YouTube si quieres compartir más detalles de tu experiencia.',
                                      waitDuration: const Duration(milliseconds: 300),
                                      child: Icon(Icons.info_outline, color: Colors.black54),
                                    ),
                                  ],
                                ),
                              ),
                              if (_ytController != null) ...[
                                const SizedBox(height: 12),
                                // Envuelto en widget que permite ocultarlo cuando el modal está abierto
                                Offstage(
                                  offstage: _hideYoutube,
                                  child: ConstrainedBox(
                                    constraints: const BoxConstraints(maxWidth: 560, minHeight: 200),
                                    child: AspectRatio(
                                      aspectRatio: 16/9,
                                      child: YoutubePlayer(controller: _ytController!),
                                    ),
                                  ),
                                ),
                              ],
                              const SizedBox(height: 14),

                              // TextArea reutilizable y centrado (con límite 5000)
                              ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 560),
                                child: Column(
                                  children: [
                                    ExperienceTextArea(
                                      controller: _contentCtrl,
                                      hintText: '¿Qué nos quieres compartir?',
                                      height: 220,
                                      maxLength: _maxChars, // NUEVO
                                    ),
                                    const SizedBox(height: 8),
                                    // Contador de caracteres
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: Text(
                                        '${_contentCtrl.text.length}/$_maxChars',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Botón "Publicar"
                              ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 360),
                                child: SimpleButton(
                                  title: 'Publicar',
                                  onTap: _onPublish,
                                ),
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
      final idAlumno = userProv.idUsuario; // Usar id real del alumno
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
      if (resp.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Experiencia publicada')));
        context.go('/alumno/experiencias');
        return;
      } else if (resp.statusCode >= 200 && resp.statusCode < 300) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Experiencia publicada')));
        _titleCtrl.clear();
        _contentCtrl.clear();
        _youtubeCtrl.clear();
        setState(() {
          _selectedRoles = [];
          _ytController = null;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error ${resp.statusCode} al publicar')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Excepción: $e')));
    }
  }
}
