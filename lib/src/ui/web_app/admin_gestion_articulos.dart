import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:vinculed_app_1/src/ui/widgets/buttons/simple_buttons.dart';
import 'package:vinculed_app_1/src/ui/widgets/elements/header4.dart';
import 'package:vinculed_app_1/src/ui/widgets/text_inputs/roles_multi_dropdown.dart';
import 'package:vinculed_app_1/src/core/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:vinculed_app_1/src/core/controllers/theme_controller.dart';
import 'package:vinculed_app_1/src/ui/widgets/elements/footer.dart';
import 'package:vinculed_app_1/src/ui/widgets/elements/header2.dart';

class AdminGestionArticulosWebPage extends StatefulWidget {
  const AdminGestionArticulosWebPage({super.key});

  @override
  State<AdminGestionArticulosWebPage> createState() => _AdminGestionArticulosWebPageState();
}

class _AdminGestionArticulosWebPageState extends State<AdminGestionArticulosWebPage> {
  final _scrollCtrl = ScrollController();
  bool _showFooter = false;

  static const double _footerReservedSpace = EscomFooter.height;
  static const double _extraBottomPadding = 24.0;
  static const double _atEndThreshold = 4.0;

  RoleOption? _selectedRol;
  String? _markdownContent;
  String? _tituloArticulo; // Título del artículo cargado
  int? _idArticulo; // ID del artículo cargado
  bool _loadingArticulo = false;
  String? _errorArticulo;

  // Formulario publicar/editar artículo
  final _editFormKey = GlobalKey<FormState>();
  final _editTituloController = TextEditingController();
  final _editContenidoController = TextEditingController();
  bool _editandoArticulo = false;

  // Formulario publicar artículo
  final _formKey = GlobalKey<FormState>();
  RoleOption? _formSelectedRol;
  final _tituloController = TextEditingController();
  final _contenidoController = TextEditingController();
  bool _enviandoArticulo = false;

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _onScroll());
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

  Future<void> _fetchArticulo(int idRol) async {
    setState(() {
      _loadingArticulo = true;
      _errorArticulo = null;
      _markdownContent = null;
      _tituloArticulo = null;
      _idArticulo = null;
    });
    try {
      final url = Uri.parse('https://oda-talent-back-81413836179.us-central1.run.app/api/roles_trabajo/articulos/$idRol');
      // Usa headers autenticados si están disponibles
      Map<String, String>? headers;
      try {
        final userProv = Provider.of<UserDataProvider>(context, listen: false);
        headers = await userProv.getAuthHeaders();
      } catch (_) {
        headers = {};
      }
      final res = await http.get(url, headers: headers);
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final data = jsonDecode(res.body) as List<dynamic>;
        if (data.isNotEmpty) {
          final first = data.first as Map<String, dynamic>;
          _markdownContent = (first['contenido'] ?? '') as String;
          _tituloArticulo = (first['titulo'] ?? '') as String;
          _idArticulo = first['id_articulo'] as int?;
        } else {
          _errorArticulo = 'Sin contenido.';
        }
      } else if (res.statusCode == 404) {
        _errorArticulo = 'Lo sentimos, no contamos con un artículo de ese rol de trabajo.';
      } else {
        _errorArticulo = 'Error ${res.statusCode}';
      }
    } catch (e) {
      _errorArticulo = 'Error: $e';
    } finally {
      if (mounted) {
        setState(() {
          _loadingArticulo = false;
        });
      }
    }
  }

  Future<void> _publicarArticulo() async {
    if (!_formKey.currentState!.validate() || _formSelectedRol == null) return;

    setState(() => _enviandoArticulo = true);

    try {
      final userProv = Provider.of<UserDataProvider>(context, listen: false);
      final headers = await userProv.getAuthHeaders();
      final idAdmin = userProv.idRol;

      final body = jsonEncode({
        'id_roltrabajo': _formSelectedRol!.id,
        'id_admin': idAdmin,
        'titulo': _tituloController.text.trim(),
        'contenido': _contenidoController.text,
      });

      final res = await http.post(
        Uri.parse('https://oda-talent-back-81413836179.us-central1.run.app/api/roles_trabajo/publicar_articulo'),
        headers: headers,
        body: body,
      );

      if (res.statusCode >= 200 && res.statusCode < 300) {
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Artículo publicado exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
          // Limpiar formulario
          _formSelectedRol = null;
          _tituloController.clear();
          _contenidoController.clear();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al publicar: ${res.statusCode}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _enviandoArticulo = false);
    }
  }

  void _abrirFormularioPublicar() {
    final theme = ThemeController.instance;
    final w = MediaQuery.of(context).size.width;
    final isMobile = w < 700;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          insetPadding: EdgeInsets.symmetric(
            horizontal: isMobile ? 16 : 40,
            vertical: 24,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700, maxHeight: 700),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      //color: theme.secundario().withOpacity(0.1),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.article_outlined, color: theme.secundario()),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Publicar Nuevo Artículo',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: theme.fuente(),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(ctx).pop(),
                        ),
                      ],
                    ),
                  ),
                  // Form content
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Selector de rol
                          RolesMultiDropdown(
                            label: 'Rol de trabajo *',
                            hintText: '',
                            singleSelection: true,
                            initialSelectedIds: _formSelectedRol != null
                                ? [_formSelectedRol!.id]
                                : const [],
                            onChanged: (roles) {
                              setDialogState(() {
                                _formSelectedRol =
                                    roles.isNotEmpty ? roles.first : null;
                              });
                            },
                            onOpen: () {},
                            onClose: () {},
                            errorText: _formSelectedRol == null
                                ? null
                                : null,
                          ),
                          const SizedBox(height: 16),
                          // Título
                          TextFormField(
                            controller: _tituloController,
                            decoration: InputDecoration(
                              labelText: 'Título *',
                              hintText: 'Ej: ¿Qué Hace un Consultor de Sistemas?',
                              border: const OutlineInputBorder(),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: theme.secundario()),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: theme.secundario(),
                                  width: 2,
                                ),
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'El título es requerido';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          // Contenido
                          TextFormField(
                            controller: _contenidoController,
                            maxLines: 10,
                            maxLength: 65530,
                            decoration: InputDecoration(
                              labelText: 'Contenido *',
                              hintText: 'Escribe el contenido del artículo (soporta Markdown)',
                              alignLabelWithHint: true,
                              border: const OutlineInputBorder(),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: theme.secundario()),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: theme.secundario(),
                                  width: 2,
                                ),
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'El contenido es requerido';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Máximo 65,530 caracteres. Puedes usar formato Markdown.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Actions
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(color: Colors.grey.withOpacity(0.2)),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        SimpleButton(
                          title: 'Cancelar',
                          onTap: _enviandoArticulo
                              ? null
                              : () => Navigator.of(ctx).pop(),
                          backgroundColor: Colors.blueGrey,
                          textColor: Colors.white,
                        ),
                        const SizedBox(width: 12),
                        SimpleButton(
                          title: _enviandoArticulo ? 'Publicando...' : 'Publicar',
                          onTap: () async {
                                  await _publicarArticulo();
                                },
                          backgroundColor: theme.secundario(),
                          //textColor: Colors.white,
                          icon: Icons.publish,
                          
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
    );
  }

  Future<void> _actualizarArticulo() async {
    if (!_editFormKey.currentState!.validate() || _idArticulo == null) return;

    setState(() => _editandoArticulo = true);

    try {
      final userProv = Provider.of<UserDataProvider>(context, listen: false);
      final headers = await userProv.getAuthHeaders();

      final body = jsonEncode({
        'id_articulo': _idArticulo,
        'titulo': _editTituloController.text.trim(),
        'contenido': _editContenidoController.text,
      });

      final res = await http.put(
        Uri.parse('https://oda-talent-back-81413836179.us-central1.run.app/api/roles_trabajo/editar_articulo'),
        headers: headers,
        body: body,
      );

      if (res.statusCode >= 200 && res.statusCode < 300) {
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Artículo actualizado exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
          // Recargar el artículo
          _fetchArticulo(_selectedRol!.id);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al actualizar: ${res.statusCode}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _editandoArticulo = false);
    }
  }

  void _abrirFormularioEditar() {
    if (_selectedRol == null || _markdownContent == null) return;

    final theme = ThemeController.instance;
    final w = MediaQuery.of(context).size.width;
    final isMobile = w < 700;

    // Pre-cargar los datos actuales
    _editTituloController.text = _tituloArticulo ?? '';
    _editContenidoController.text = _markdownContent ?? '';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          insetPadding: EdgeInsets.symmetric(
            horizontal: isMobile ? 16 : 40,
            vertical: 24,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700, maxHeight: 700),
            child: Form(
              key: _editFormKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.edit_document, color: theme.secundario()),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Editar Artículo',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: theme.fuente(),
                            ),
                          ),
                        ),
                        // IconButton(
                        //   icon: const Icon(Icons.close),
                        //   onPressed: () => Navigator.of(ctx).pop(),
                        // ),
                      ],
                    ),
                  ),
                  // Form content
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Rol de trabajo (solo lectura)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade400),
                              borderRadius: BorderRadius.circular(4),
                              //color: Colors.grey.shade100,
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.lock_outline, size: 18, color: Colors.grey.shade600),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Rol de trabajo',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        _selectedRol!.nombre,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: theme.fuente(),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Título
                          TextFormField(
                            controller: _editTituloController,
                            decoration: InputDecoration(
                              labelText: 'Título *',
                              hintText: 'Ej: ¿Qué Hace un Consultor de Sistemas?',
                              border: const OutlineInputBorder(),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: theme.secundario()),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: theme.secundario(),
                                  width: 2,
                                ),
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'El título es requerido';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          // Contenido
                          TextFormField(
                            controller: _editContenidoController,
                            maxLines: 10,
                            maxLength: 65530,
                            decoration: InputDecoration(
                              labelText: 'Contenido *',
                              hintText: 'Escribe el contenido del artículo (soporta Markdown)',
                              alignLabelWithHint: true,
                              border: const OutlineInputBorder(),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: theme.secundario()),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: theme.secundario(),
                                  width: 2,
                                ),
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'El contenido es requerido';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Máximo 65,530 caracteres. Puedes usar formato Markdown.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Actions
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(color: Colors.grey.withOpacity(0.2)),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        SimpleButton(
                          title: 'Cancelar',
                          onTap: _editandoArticulo
                              ? null
                              : () => Navigator.of(ctx).pop(),
                          backgroundColor: Colors.blueGrey,
                          textColor: Colors.white,
                        ),
                        const SizedBox(width: 12),
                        SimpleButton(
                          title: _editandoArticulo ? 'Guardando...' : 'Guardar Cambios',
                          onTap: () async {
                            await _actualizarArticulo();
                          },
                          backgroundColor: theme.secundario(),
                          icon: Icons.save,
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
    );
  }

  @override
  void dispose() {
    _scrollCtrl
      ..removeListener(_onScroll)
      ..dispose();
    _tituloController.dispose();
    _contenidoController.dispose();
    _editTituloController.dispose();
    _editContenidoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;
    final w = MediaQuery.of(context).size.width;
    final isMobile = w < 700;

    return Scaffold(
      backgroundColor: theme.background(),
      appBar: EscomHeader4(
        onLoginTap: () => context.go('/admin/reportes'),
        onNotifTap: () {},
        onMenuSelected: (label) {
          switch (label) {
            case "Inicio":
              context.go('/inicio');
              break;
            case "Empresas":
              context.go('/admin/empresas');
              break;
            case "Alumnos":
              context.go('/admin/alumnos');
              break;
            case "Reclutadores":
              context.go('/admin/reclutadores');
              break;
            case "Artículos":
              context.go('/admin/articulos');
              break;
            case "Vacantes":
              context.go('/admin/vacantes');
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
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // ---------- Título ----------
                                Text(
                                  'Explorar Puestos en TI',
                                  style: TextStyle(
                                    fontSize: isMobile ? 26 : 34,
                                    fontWeight: FontWeight.w900,
                                    color: const Color(0xFF22313F),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Selecciona el puesto de trabajo del que te gustaría saber información. Al confirmar se cargará un artículo detallado.',
                                  style: TextStyle(
                                    fontSize: isMobile ? 14 : 16,
                                    color: Colors.black87,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                RolesMultiDropdown(
                                  label: 'Elegir rol de trabajo',
                                  hintText: '',
                                  singleSelection: true,
                                  initialSelectedIds: _selectedRol != null ? [_selectedRol!.id] : const [],
                                  onChanged: (roles) {
                                    final r = roles.isNotEmpty ? roles.first : null;
                                    setState(() {
                                      _selectedRol = r;
                                    });
                                    if (r != null) {
                                      _fetchArticulo(r.id);
                                    } else {
                                      setState(() {
                                        _markdownContent = null;
                                      });
                                    }
                                  },
                                  onOpen: () {},
                                  onClose: () {},
                                ),
                                const SizedBox(height: 12),
                                // Botón de editar alineado a la derecha
                                if (_markdownContent != null && _selectedRol != null)
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: SimpleButton(
                                      title: 'Editar artículo',
                                      icon: Icons.edit,
                                      backgroundColor: theme.secundario(),
                                      onTap: _abrirFormularioEditar,
                                    ),
                                  ),
                                const SizedBox(height: 16),
                                if (_loadingArticulo)
                                  const LinearProgressIndicator(minHeight: 3),
                                if (_errorArticulo != null)
                                  Container(
                                    margin: const EdgeInsets.only(bottom: 16),
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: theme.secundario().withOpacity(0.08),
                                      border: Border.all(
                                        color: theme.secundario().withOpacity(0.35),
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Icon(
                                          Icons.info_outline,
                                          color: theme.secundario(),
                                          size: 22,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Contenido no disponible',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                  color: theme.fuente(),
                                                ),
                                              ),
                                              const SizedBox(height: 6),
                                              Text(
                                                _errorArticulo!,
                                                style: const TextStyle(
                                                  color: Colors.black87,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              const Text(
                                                'Sugerencia: intenta seleccionando otro rol por ahora.',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontStyle: FontStyle.italic,
                                                  color: Colors.black54,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                if (_markdownContent != null)
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      Markdown(
                                        data: _markdownContent!,
                                        shrinkWrap: true,
                                        physics: const NeverScrollableScrollPhysics(),
                                      ),
                                      const SizedBox(height: 16),
                                      Container(
                                        decoration: BoxDecoration(
                                          color: Colors.grey.withOpacity(0.08),
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(color: Colors.grey.withOpacity(0.25)),
                                        ),
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.center,
                                          children: const [
                                            Icon(Icons.auto_awesome, size: 16, color: Colors.grey),
                                            SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                'Aviso sobre el uso de IA: Este texto se creó con la ayuda de ChatGPT',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontStyle: FontStyle.italic,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
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
            ),
          ),

          // Footer animado (aparece al final)
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
      floatingActionButton: SimpleButton(
        onTap: _abrirFormularioPublicar,
        backgroundColor: theme.secundario(),
        icon: Icons.add,
        title: 'Publicar Artículo',
      ),
    );
  }
}
