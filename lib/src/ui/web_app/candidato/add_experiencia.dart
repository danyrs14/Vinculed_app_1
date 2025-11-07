import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';

import 'package:vinculed_app_1/src/core/controllers/theme_controller.dart';
import 'package:vinculed_app_1/src/ui/widgets/elements/header.dart';
import 'package:vinculed_app_1/src/ui/widgets/elements/footer.dart';
import 'package:vinculed_app_1/src/ui/widgets/buttons/simple_buttons.dart';
import 'package:vinculed_app_1/src/ui/widgets/elements/header2.dart';
import 'package:vinculed_app_1/src/ui/widgets/text_inputs/experience_text_area.dart';

class CreateExperiencePage extends StatefulWidget {
  const CreateExperiencePage({super.key});

  @override
  State<CreateExperiencePage> createState() => _CreateExperiencePageState();
}

class _CreateExperiencePageState extends State<CreateExperiencePage> {
  final _scrollCtrl = ScrollController();
  final _contentCtrl = TextEditingController();

  bool _showFooter = false;

  static const double _footerReservedSpace = EscomFooter.height;
  static const double _extraBottomPadding = 24.0;
  static const double _atEndThreshold = 4.0;

  // --- NUEVO: Dropdown de rol ---
  final List<String> _roles = const <String>[
    'Desarrollador/a',
    'Analista',
    'QA / Tester',
    'Project Manager',
    'Diseñador/a UI/UX',
    'DevOps',
    'Data Engineer',
    'Soporte Técnico',
    'Otro',
  ];
  String? _selectedRole;

  // --- NUEVO: Archivos adjuntos ---
  List<PlatformFile> _pickedFiles = [];

  // --- NUEVO: límite de caracteres ---
  static const int _maxChars = 5000;

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
    super.dispose();
  }

  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      withReadStream: false,
      withData: false,
    );
    if (result != null) {
      setState(() {
        _pickedFiles = result.files;
      });
    }
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

                              // --- NUEVO: Dropdown de Rol (arriba del textarea) ---
                              ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 560),
                                child: DropdownButtonFormField<String>(
                                  value: _selectedRole,
                                  decoration: InputDecoration(
                                    labelText: 'Rol de trabajo',
                                    hintText: 'Selecciona el rol para esta experiencia',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 12,
                                    ),
                                  ),
                                  items: _roles
                                      .map((r) => DropdownMenuItem(
                                    value: r,
                                    child: Text(r),
                                  ))
                                      .toList(),
                                  onChanged: (v) => setState(() => _selectedRole = v),
                                ),
                              ),
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
                              const SizedBox(height: 16),

                              // --- NUEVO: Botón para adjuntar archivos + lista de archivos ---
                              ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 560),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    OutlinedButton.icon(
                                      onPressed: _pickFiles,
                                      icon: const Icon(Icons.attach_file),
                                      label: const Text('Adjuntar archivos'),
                                    ),
                                    if (_pickedFiles.isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      Container(
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(
                                            color: theme.secundario(),
                                            width: 1.0,
                                          ),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 10,
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'Archivos seleccionados:',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            ..._pickedFiles.map(
                                                  (f) => Padding(
                                                padding: const EdgeInsets.symmetric(vertical: 2),
                                                child: Row(
                                                  children: [
                                                    const Icon(Icons.insert_drive_file, size: 16),
                                                    const SizedBox(width: 6),
                                                    Expanded(
                                                      child: Text(
                                                        f.name,
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                    if (f.size != null)
                                                      Text(
                                                        _fmtSize(f.size),
                                                        style: const TextStyle(fontSize: 12),
                                                      ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
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

  void _onPublish() {
    final text = _contentCtrl.text.trim();

    if (_selectedRole == null || _selectedRole!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona el rol de trabajo.')),
      );
      return;
    }

    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escribe algo para publicar.')),
      );
      return;
    }

    if (text.length > _maxChars) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('El máximo es de $_maxChars caracteres.')),
      );
      return;
    }

    // TODO: Envía el contenido, el rol y los archivos a tu backend aquí.
    // Ejemplo:
    // await api.createExperience(
    //   role: _selectedRole!,
    //   content: text,
    //   files: _pickedFiles,
    // );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Experiencia publicada')),
    );
    _contentCtrl.clear();
    setState(() {
      _selectedRole = null;
      _pickedFiles = [];
    });
  }

  // --- util tamaño legible ---
  String _fmtSize(int? bytes) {
    if (bytes == null) return '';
    const units = ['B', 'KB', 'MB', 'GB'];
    double size = bytes.toDouble();
    int idx = 0;
    while (size >= 1024 && idx < units.length - 1) {
      size /= 1024;
      idx++;
    }
    return '${size.toStringAsFixed(1)} ${units[idx]}';
  }
}
