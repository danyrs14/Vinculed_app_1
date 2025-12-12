import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:vinculed_app_1/src/core/controllers/theme_controller.dart';
import 'package:vinculed_app_1/src/core/providers/user_provider.dart';
import 'package:vinculed_app_1/src/ui/widgets/elements/footer.dart';
import 'package:vinculed_app_1/src/ui/widgets/elements/header4.dart';
import 'package:vinculed_app_1/src/ui/widgets/elements/media.dart';
import 'package:vinculed_app_1/src/ui/widgets/buttons/simple_buttons.dart';
import 'package:vinculed_app_1/src/ui/widgets/text_inputs/dropdown.dart';
import 'package:vinculed_app_1/src/ui/widgets/text_inputs/text_form_field.dart';

/* ============================ Modelos ============================ */
class Paginacion {
  final int totalAlumnos;
  final int totalPaginas;
  final int paginaActual;
  final int tamanoPagina;
  final int totalAlumnosInactivos;

  const Paginacion({
    required this.totalAlumnos,
    required this.totalPaginas,
    required this.paginaActual,
    required this.tamanoPagina,
    required this.totalAlumnosInactivos,
  });

  factory Paginacion.fromJson(Map<String, dynamic> json) {
    int _toInt(dynamic v) {
      if (v is int) return v;
      return int.tryParse('$v') ?? 0;
    }

    return Paginacion(
      totalAlumnos: _toInt(json['total_alumnos']),
      totalPaginas: _toInt(json['total_paginas']),
      paginaActual: _toInt(json['pagina_actual']),
      tamanoPagina: _toInt(json['tamano_pagina']),
      totalAlumnosInactivos: _toInt(json['total_alumnos_inactivos']),
    );
  }
}

class AlumnoItem {
  final int idUsuario;
  final int idAlumno;
  final String nombre;
  final String correo;
  final String genero;
  final String urFotoPerfil;
  final String uidFirebase;
  //final DateTime ultimoAcceso;

  const AlumnoItem({
    required this.idUsuario,
    required this.idAlumno,
    required this.nombre,
    required this.correo,
    required this.genero,
    required this.urFotoPerfil,
    required this.uidFirebase,
    //required this.ultimoAcceso,
  });

  factory AlumnoItem.fromJson(Map<String, dynamic> json) {
    int _toInt(dynamic v) {
      if (v is int) return v;
      return int.tryParse('$v') ?? 0;
    }

    return AlumnoItem(
      idUsuario: _toInt(json['id_usuario']),
      idAlumno: _toInt(json['id_alumno']),
      nombre: (json['nombre'] ?? '').toString(),
      correo: (json['correo'] ?? '').toString(),
      genero: (json['genero'] ?? '').toString(),
      urFotoPerfil: (json['url_foto_perfil'] ?? '').toString(),
      uidFirebase: (json['uid_firebase'] ?? '').toString(),
      //ultimoAcceso: DateTime.tryParse((json['ultimo_acceso'] ?? '').toString())?.toLocal() ?? DateTime.april,
    );
  }
}

/* ============================ Página ============================ */
class AdminGestionAlumnosPage extends StatefulWidget {
  const AdminGestionAlumnosPage({Key? key}) : super(key: key);

  @override
  State<AdminGestionAlumnosPage> createState() => _AdminGestionAlumnosPageState();
}

class _AdminGestionAlumnosPageState extends State<AdminGestionAlumnosPage> {
  static const String _endpoint = 'http://localhost:3000/api/usuarios/ver_alumnos';
  static const String _delUrl = 'http://localhost:3000/api/usuarios/eliminar_alumno';
  static const String _createUrl = 'http://localhost:3000/api/usuarios/crear_alumno';

  // Datos y paginación
  List<AlumnoItem> _alumnos = const [];
  Paginacion? _paginacion;
  Map<String, dynamic>? _rawResponse; // Guarda TODOS los datos recibidos
  int _page = 1;
  final int _limit = 10;
  bool _loading = false;
  String? _error;

  // Footer animado estilo dashboard
  final ScrollController _scrollCtrl = ScrollController();
  bool _showFooter = false;
  static const double _footerReservedSpace = EscomFooter.height;
  static const double _extraBottomPadding = 24.0;
  static const double _atEndThreshold = 4.0;

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _onScroll());
    _loadPage(1); // carga primeros 10 alumnos
  }

  @override
  void dispose() {
    _scrollCtrl
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  // Muestra el JSON completo recibido
  void _showRawDialog() {
    if (_rawResponse == null) return;
    final pretty = const JsonEncoder.withIndent('  ').convert(_rawResponse);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Respuesta del servidor'),
        content: SizedBox(
          width: 600,
          child: SingleChildScrollView(child: SelectableText(pretty)),
        ),
        actions: [
          SimpleButton(
            title: 'Cerrar',
            primaryColor: false,
            backgroundColor: Colors.grey.shade200,
            textColor: Colors.black87,
            onTap: () => Navigator.of(ctx).pop(),
          ),
        ],
      ),
    );
  }

  void _onScroll() {
    if (!_scrollCtrl.hasClients) return;
    final pos = _scrollCtrl.position;
    if (!pos.hasPixels || !pos.hasContentDimensions) return;

    if (pos.maxScrollExtent <= 0) {
      if (_showFooter) setState(() => _showFooter = false);
      return;
    }

    final atBottom = pos.pixels >= (pos.maxScrollExtent - _atEndThreshold);
    if (atBottom != _showFooter) setState(() => _showFooter = atBottom);
  }

  Future<void> _loadPage(int page) async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final headers = await context.read<UserDataProvider>().getAuthHeaders();
      final uri = Uri.parse('$_endpoint?page=$page&limit=$_limit');
      final res = await http.get(uri, headers: headers);

      if (res.statusCode >= 400) {
        throw Exception('Error ${res.statusCode}: ${res.body}');
      }

      final decoded = json.decode(res.body);
      if (decoded is! Map<String, dynamic>) {
        throw Exception('Formato inesperado');
      }

      final pag = Paginacion.fromJson(Map<String, dynamic>.from(decoded['paginacion'] ?? {}));
      final list = (decoded['alumnos'] as List? ?? [])
          .map((e) => AlumnoItem.fromJson(Map<String, dynamic>.from(e)))
          .toList();

      setState(() {
        _page = pag.paginaActual;
        _paginacion = pag;
        _alumnos = list;
        _rawResponse = decoded; // Guardamos todo
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _refresh() async {
    await _loadPage(_page);
    WidgetsBinding.instance.addPostFrameCallback((_) => _onScroll());
  }

  // =============== UI Helpers ===============
  String _formatDate(DateTime d) {
    String two(int x) => x.toString().padLeft(2, '0');
    return '${two(d.day)}/${two(d.month)}/${d.year} ${two(d.hour)}:${two(d.minute)}';
  }

  Widget _badge(String text, {Color? bg, Color? fg, EdgeInsets padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 6)}) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: bg ?? Colors.grey.shade200,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: (fg ?? Colors.black54).withOpacity(0.2)),
      ),
      child: Text(text, style: TextStyle(color: fg ?? Colors.black87, fontWeight: FontWeight.w600, fontSize: 12)),
    );
  }

  Widget _cardAlumno(AlumnoItem e) {
    final theme = ThemeController.instance;
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: e.urFotoPerfil.isNotEmpty ? Image.network(
                e.urFotoPerfil,
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 80,
                  height: 80,
                  color: Colors.grey.shade200,
                  alignment: Alignment.center,
                  child: const Icon(Icons.image_not_supported),
                ),
              ) : Container(
                width: 80,
                height: 80,
                color: Colors.grey.shade200,
                alignment: Alignment.center,
                child: const Icon(Icons.person_2_outlined),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(e.nombre, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Text(e.correo, style: const TextStyle(fontSize: 14, color: Colors.black54)),
                  const SizedBox(height: 6),
                  Text(e.genero, style: const TextStyle(fontSize: 14, color: Colors.black54)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12, // espacio vertical cuando se apilan en móvil
                    children: [
                      // SimpleButton(
                      //   title: 'Editar',
                      //   icon: Icons.edit,
                      //   onTap: () => _openEditarAlumno(e),
                      // ),
                      SimpleButton(
                        title: 'Eliminar',
                        icon: Icons.delete_forever,
                        backgroundColor: Colors.red,
                        textColor: Colors.white,
                        onTap: () => _confirmEliminar(e.idUsuario, e.idAlumno, e.uidFirebase),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _paginationBar() {
    final pag = _paginacion;
    final totalPages = pag?.totalPaginas ?? 1;
    final total = pag?.totalAlumnos ?? _alumnos.length;
    final totalInactivos = pag?.totalAlumnosInactivos ?? 0;

    final bool canPrev = _page > 1 && !_loading;
    final bool canNext = _page < totalPages && !_loading;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Text('Total: $total'),
              const Spacer(),
              SimpleButton(
                title: 'Anterior',
                icon: Icons.chevron_left,
                backgroundColor: canPrev ? null : Colors.grey.shade300,
                textColor: canPrev ? null : Colors.grey.shade600,
                onTap: canPrev ? () => _loadPage(_page - 1) : null,
              ),
              const SizedBox(width: 8),
              Text('Página $_page de $totalPages'),
              const SizedBox(width: 8),
              SimpleButton(
                title: 'Siguiente',
                icon: Icons.chevron_right,
                backgroundColor: canNext ? null : Colors.grey.shade300,
                textColor: canNext ? null : Colors.grey.shade600,
                onTap: canNext ? () => _loadPage(_page + 1) : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openCrearAlumno() {
    showDialog(
      context: context,
      builder: (ctx) => _AlumnoFormDialog(
        title: 'Agregar Alumno',
        onSubmit: (nombre, correo, genero, correoProvisional) => _crearAlumno(nombre, correo, genero, correoProvisional),
      ),
    );
  }

  Future<void> _crearAlumno(nombre, correo, genero, correoProvisional) async {
    final headers = await context.read<UserDataProvider>().getAuthHeaders();
    final res = await http.post(
      Uri.parse(_createUrl),
      headers: headers,
      body: jsonEncode({
        'nombre': nombre,
        'email': correo,
        'genero': genero,
        'correo_provisional': correoProvisional,
      }),
    );
    if (res.statusCode >= 200 && res.statusCode < 300) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Alumno creado')));
      await _loadPage(_page);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al crear: ${res.statusCode}')));
    }
  }

  void _confirmEliminar(int idUsuario, int idAlumno, String uidFirebase) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar alumno'),
        content: const Text('¿Confirmas eliminar este alumno?'),
        actions: [
          SimpleButton(
            title: 'Cancelar',
            primaryColor: false,
            backgroundColor: Colors.blueGrey,
            textColor: Colors.black87,
            onTap: () => Navigator.pop(ctx),
          ),
          SimpleButton(
            title: 'Eliminar',
            icon: Icons.delete_forever,
            backgroundColor: Colors.red,
            textColor: Colors.white,
            onTap: () { Navigator.pop(ctx); _eliminarAlumno(idUsuario, idAlumno, uidFirebase); },
          ),
        ],
      ),
    );
  }

  Future<void> _eliminarAlumno(int idUsuario, int idAlumno, String uidFirebase) async {
    final headers = await context.read<UserDataProvider>().getAuthHeaders();
    final res = await http.delete(Uri.parse(_delUrl), headers: headers, body: jsonEncode({'id_usuario':idUsuario,'id_alumno': idAlumno, 'uid_alumno': uidFirebase}));
    if (res.statusCode >= 200 && res.statusCode < 300) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Alumno eliminado')));
      await _loadPage(_page);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al eliminar: ${res.statusCode}')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 700;

    return Scaffold(
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
          }
        },
      ),
      floatingActionButton: SimpleButton(
        title: 'Nuevo Alumno',
        icon: Icons.add_business,
        onTap: _openCrearAlumno,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final minBodyHeight = constraints.maxHeight - _footerReservedSpace - _extraBottomPadding;
                return NotificationListener<ScrollNotification>(
                  onNotification: (n) {
                    if (n is ScrollUpdateNotification || n is UserScrollNotification || n is ScrollEndNotification) {
                      _onScroll();
                    }
                    return false;
                  },
                  child: RefreshIndicator(
                    onRefresh: _refresh,
                    child: SingleChildScrollView(
                      controller: _scrollCtrl,
                      physics: const ClampingScrollPhysics(),
                      padding: const EdgeInsets.only(
                        top: 12,
                        bottom: _footerReservedSpace + _extraBottomPadding,
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1000),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            child: ConstrainedBox(
                              constraints: BoxConstraints(minHeight: minBodyHeight > 0 ? minBodyHeight : 0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Text(
                                        'Alumnos Registrados',
                                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                                      ),
                                      const Spacer(),
                                      if (_rawResponse != null)
                                        SimpleButton(
                                          title: 'Ver JSON',
                                          icon: Icons.data_object,
                                          backgroundColor: Colors.grey.shade200,
                                          textColor: Colors.black87,
                                          onTap: _showRawDialog,
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  if (_paginacion != null)
                                    Text(
                                      'Total: ${_paginacion!.totalAlumnos}  •  Página: ${_paginacion!.paginaActual}/${_paginacion!.totalPaginas}  •  Tamaño: ${_paginacion!.tamanoPagina}  •  Total de Alumnos Inactivos: ${_paginacion!.totalAlumnosInactivos}',
                                      style: const TextStyle(color: Colors.black54),
                                    ),
                                  const SizedBox(height: 12),

                                  if (_loading)
                                    const Padding(
                                      padding: EdgeInsets.only(top: 80),
                                      child: Center(child: CircularProgressIndicator()),
                                    )
                                  else if (_error != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 60),
                                      child: Column(
                                        children: [
                                          const Icon(Icons.error_outline, color: Colors.red),
                                          const SizedBox(height: 8),
                                          Text('Error: $_error', textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
                                        ],
                                      ),
                                    )
                                  else if (_alumnos.isEmpty)
                                    const Padding(
                                      padding: EdgeInsets.only(top: 80),
                                      child: Center(child: Text('No hay alumnos con cuenta activa en firebase.')),
                                    )
                                  else
                                    Column(
                                      children: [
                                        for (final r in _alumnos) _cardAlumno(r),
                                        const SizedBox(height: 8),
                                        _paginationBar(),
                                      ],
                                    ),
                                ],
                              ),
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


class _AlumnoFormDialog extends StatefulWidget {
  final String title;
  final AlumnoItem? initial;
  final Future<void> Function(String nombre, String correo, String genero, String correoProvisional) onSubmit;
  const _AlumnoFormDialog({required this.title, this.initial, required this.onSubmit});
  @override
  State<_AlumnoFormDialog> createState() => _AlumnoFormDialogState();
}

class _AlumnoFormDialogState extends State<_AlumnoFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nombreCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _emailProvCtrl;
  late TextEditingController _generoCtrl;
  late TextEditingController _confirmEmailCtrl;
  Uint8List? _pickedBytes;
  String? _pickedName;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _nombreCtrl = TextEditingController(text: widget.initial?.nombre ?? '');
    _emailCtrl   = TextEditingController(text: widget.initial?.correo ?? '');
    _confirmEmailCtrl   = TextEditingController(text: widget.initial?.correo ?? '');
    _emailProvCtrl   = TextEditingController(text: widget.initial?.correo ?? '');
    _generoCtrl    = TextEditingController(text: widget.initial?.genero ?? '');
  }

  @override
  void dispose() {
    _nombreCtrl.dispose(); _emailCtrl.dispose(); _generoCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(()=>_sending=true);
    final nombre = _nombreCtrl.text.trim();
    final correo = _emailCtrl.text.trim();
    final correoProvisional = _emailProvCtrl.text.trim();
    final genero = _generoCtrl.text.trim();
  
    await widget.onSubmit(nombre, correo, genero, correoProvisional);
    if (mounted) { setState(()=>_sending=false); Navigator.of(context).maybePop(); }
  }

  String? _validNotEmpty(String? v) => (v==null||v.trim().isEmpty) ? 'Requerido' : null;
  String? _validWeb(String? v) {
    if (v==null||v.trim().isEmpty) return 'Requerido';
    final uri = Uri.tryParse(v.trim());
    if (uri==null || !uri.hasAbsolutePath || !(uri.scheme=='http'||uri.scheme=='https')) return 'URL inválida';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;
    return AlertDialog(
      title: Text(widget.title),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StyledTextFormField(
                  isRequired: true,
                  controller: _nombreCtrl,
                  title: "Nombre completo",
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'El nombre es obligatorio.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                DropdownInput<String>(
                  title: "Género",
                  required: true,
                  items: const [
                    DropdownMenuItem(value: "masculino", child: Text("Masculino")),
                    DropdownMenuItem(value: "femenino", child: Text("Femenino")),
                    DropdownMenuItem(value: "otro", child: Text("Otro")),
                  ],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'El género es obligatorio.';
                    }
                    return null;
                  },
                  onChanged: (valor) {
                    setState(() {
                      _generoCtrl.text = valor ?? "";
                    });
                  },
                ),
                const SizedBox(height: 12),
                StyledTextFormField(
                  isRequired: true,
                  controller: _emailCtrl,
                  title: "Correo institucional",
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'El correo es obligatorio.';
                    }
                    final emailRegex = RegExp(r'^[^@]+@alumno.ipn.mx$');
                    if (!emailRegex.hasMatch(value)) {
                      return 'Ingrese un correo válido.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                StyledTextFormField(
                  isRequired: true,
                  controller: _confirmEmailCtrl,
                  title: "Confirma el correo",
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty || 
                    !identical(value.trim(), _emailCtrl.text.trim())) {
                      return 'El correo debe coincidir con el proporcionado anteriormente.';
                    }
                    final emailRegex = RegExp(r'^[^@]+@alumno.ipn.mx$');
                    if (!emailRegex.hasMatch(value)) {
                      return 'Ingrese un correo válido.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                StyledTextFormField(
                  isRequired: true,
                  title: 'Correo provisional',
                  controller: _emailProvCtrl,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, ingresa tu correo.';
                    }
                    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                    if (!emailRegex.hasMatch(value)) {
                      return 'Ingresa un correo válido.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
      actions: [
        SimpleButton(
          title: 'Cancelar',
          primaryColor: false,
          backgroundColor: Colors.blueGrey,
          textColor: Colors.black87,
          onTap: _sending? null : () => Navigator.of(context).maybePop(),
        ),
        SimpleButton(
          title: _sending ? 'Agregando...' : 'Agregar',
          icon: Icons.save,
          onTap: _sending? null : _submit,
        ),
      ],
    );
  }
}
