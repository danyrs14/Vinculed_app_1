import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:vinculed_app_1/src/core/controllers/theme_controller.dart';
import 'package:vinculed_app_1/src/core/providers/user_provider.dart';
import 'package:vinculed_app_1/src/ui/widgets/elements/header4.dart';
import 'package:vinculed_app_1/src/ui/widgets/elements/media.dart';
import 'package:vinculed_app_1/src/ui/widgets/buttons/simple_buttons.dart';
import 'package:vinculed_app_1/src/ui/widgets/text_inputs/dropdown.dart';
import 'package:vinculed_app_1/src/ui/widgets/text_inputs/text_form_field.dart';

/* ============================ Modelos ============================ */
class Paginacion {
  final int totalReclutadores;
  final int totalPaginas;
  final int paginaActual;
  final int tamanoPagina;

  const Paginacion({
    required this.totalReclutadores,
    required this.totalPaginas,
    required this.paginaActual,
    required this.tamanoPagina,
  });

  factory Paginacion.fromJson(Map<String, dynamic> json) {
    int _toInt(dynamic v) {
      if (v is int) return v;
      return int.tryParse('$v') ?? 0;
    }

    return Paginacion(
      totalReclutadores: _toInt(json['total_reclutadores']),
      totalPaginas: _toInt(json['total_paginas']),
      paginaActual: _toInt(json['pagina_actual']),
      tamanoPagina: _toInt(json['tamano_pagina']),
    );
  }
}

class ReclutadorItem {
  final int idUsuario;
  final int idReclutador;
  final String nombre;
  final String correo;
  final String genero;
  final String urFotoPerfil;
  final String uidFirebase;
  final int idEmpresa;
  final String empresa;
  //final DateTime ultimoAcceso;

  const ReclutadorItem({
    required this.idUsuario,
    required this.idReclutador,
    required this.nombre,
    required this.correo,
    required this.genero,
    required this.urFotoPerfil,
    required this.uidFirebase,
    required this.idEmpresa,
    required this.empresa,
    //required this.ultimoAcceso,
  });

  factory ReclutadorItem.fromJson(Map<String, dynamic> json) {
    int _toInt(dynamic v) {
      if (v is int) return v;
      return int.tryParse('$v') ?? 0;
    }

    return ReclutadorItem(
      idUsuario: _toInt(json['id_usuario']),
      idReclutador: _toInt(json['id_reclutador']),
      nombre: (json['nombre'] ?? '').toString(),
      correo: (json['correo'] ?? '').toString(),
      genero: (json['genero'] ?? '').toString(),
      urFotoPerfil: (json['url_foto_perfil'] ?? '').toString(),
      uidFirebase: (json['uid_firebase'] ?? '').toString(),
      idEmpresa: _toInt(json['id_empresa'] ?? 0),
      empresa: (json['empresa'] ?? '').toString(),
      //ultimoAcceso: DateTime.tryParse((json['ultimo_acceso'] ?? '').toString())?.toLocal() ?? DateTime.april,
    );
  }
}

/* ============================ Página ============================ */
class AdminGestionReclutadoresMovilPage extends StatefulWidget {
  const AdminGestionReclutadoresMovilPage({Key? key}) : super(key: key);

  @override
  State<AdminGestionReclutadoresMovilPage> createState() => _AdminGestionReclutadoresMovilPageState();
}

class _AdminGestionReclutadoresMovilPageState extends State<AdminGestionReclutadoresMovilPage> {
  static const String _endpoint = 'http://10.0.2.2:3000/api/usuarios/ver_reclutadores';
  static const String _delUrl = 'http://10.0.2.2:3000/api/usuarios/eliminar_reclutador';
  static const String _createUrl = 'http://10.0.2.2:3000/api/usuarios/crear_reclutador';
  static const String _putUrl = 'http://10.0.2.2:3000/api/usuarios/editar_usuario';

  // Datos y paginación
  List<ReclutadorItem> _Reclutadores = const [];
  Paginacion? _paginacion;
  Map<String, dynamic>? _rawResponse; // Guarda TODOS los datos recibidos
  int _page = 1;
  final int _limit = 10;
  bool _loading = false;
  String? _error;

  List<dynamic> _rawDataEmpresas = [];
  List<DropdownMenuItem<String>> empresasItems = [];

  final ScrollController _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchEmpresas();
    _loadPage(1); // carga primeros 10 Reclutadores
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
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
      final list = (decoded['reclutadores'] as List? ?? [])
          .map((e) => ReclutadorItem.fromJson(Map<String, dynamic>.from(e)))
          .toList();

      setState(() {
        _page = pag.paginaActual;
        _paginacion = pag;
        _Reclutadores = list;
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
  }

  void _cargarEmpresasItemsDeJson(List<dynamic> jsonList) {
    final items = jsonList.map<DropdownMenuItem<String>>((e) {
      final id = (e['id'] ?? '').toString();
      final label = (e['nombre'] ?? id).toString();
      return DropdownMenuItem(value: id, child: Text(label));
    }).toList();

    setState(() {empresasItems = items;});
  }

  Future<void> _fetchEmpresas() async {
    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:3000/api/empresas/obtener_empresas'),
      );

      if (response.statusCode == 200 && mounted) {
        _rawDataEmpresas = jsonDecode(response.body);
        _cargarEmpresasItemsDeJson(_rawDataEmpresas);
      } else {
        throw Exception("Error al cargar empresas");
      }
    } catch (e) {
      _showError(e.toString());

    }
  }
  void _showError(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.red),
      );
    }
  }

  // =============== UI Helpers ===============



  Widget _cardReclutador(ReclutadorItem e) {
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
            Container(
              constraints: const BoxConstraints(
                maxWidth: 82,
                maxHeight: 164,
              ),
              child: Column(
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
                  const SizedBox(height: 4),
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
                      child: const Icon(Icons.business),
                    ),
                  ),
                ],
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
                  const SizedBox(height: 6),
                  Text(e.empresa, style: const TextStyle(fontSize: 14, color: Colors.black54)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12, // espacio vertical cuando se apilan en móvil
                    children: [
                      SimpleButton(
                        title: 'Editar',
                        icon: Icons.edit,
                        onTap: () => _openEditarReclutador(e),
                      ),
                      SimpleButton(
                        title: 'Eliminar',
                        icon: Icons.delete_forever,
                        backgroundColor: Colors.red,
                        textColor: Colors.white,
                        onTap: () => _confirmEliminar(e.idUsuario, e.uidFirebase),
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

    final bool canPrev = _page > 1 && !_loading;
    final bool canNext = _page < totalPages && !_loading;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
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

  void _openCrearReclutador() {
    showDialog(
      context: context,
      builder: (ctx) => _ReclutadorFormDialog(
        title: 'Agregar Reclutador',
        data: _rawDataEmpresas,
        empresasItems: empresasItems,
        onSubmit: (item) => _crearReclutador(item),
      ),
    );
  }

  //Future<void> _crearReclutador(ReclutadorItem item, String? correoProvisional) async {
  Future<void> _crearReclutador(ReclutadorItem item) async {
    final headers = await context.read<UserDataProvider>().getAuthHeaders();
    final res = await http.post(
      Uri.parse(_createUrl),
      headers: headers,
      body: jsonEncode({
        'nombre': item.nombre,
        'correo': item.correo,
        'genero': item.genero,
        'id_empresa': item.idEmpresa,
      }),
    );
    if (res.statusCode >= 200 && res.statusCode < 300) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reclutador creado')));
      await _loadPage(_page);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al crear: ${res.statusCode}')));
    }
  }

  void _openEditarReclutador(ReclutadorItem e) {
    showDialog(
      context: context,
      builder: (ctx) => _ReclutadorFormDialog(
        title: 'Editar Reclutador',
        initial: e,
        data: _rawDataEmpresas,
        empresasItems: empresasItems,
        onSubmit: (item) => _actualizarReclutador(item),
      ),
    );
  }

  Future<void> _actualizarReclutador(ReclutadorItem base) async {
    final headers = await context.read<UserDataProvider>().getAuthHeaders();

    final body = jsonEncode({
      'id_usuario': base.idUsuario,
      'nombre': base.nombre,
      'correo': base.correo,
      'genero': base.genero,
      'id_empresa': base.idEmpresa,
    });
    final res = await http.put(Uri.parse(_putUrl), headers: headers, body: body);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reclutador actualizado')));
      await _loadPage(_page);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al actualizar: ${res.statusCode}')));
    }
  }

  void _confirmEliminar(int idUsuario,String uidFirebase) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar Reclutador'),
        content: const Text('¿Confirmas eliminar este Reclutador?'),
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
            onTap: () { Navigator.pop(ctx); _eliminarReclutador(idUsuario, uidFirebase); },
          ),
        ],
      ),
    );
  }

  Future<void> _eliminarReclutador(int idUsuario, String uidFirebase) async {
    final headers = await context.read<UserDataProvider>().getAuthHeaders();
    final res = await http.delete(Uri.parse(_delUrl), headers: headers, body: jsonEncode({'id_usuario':idUsuario, 'uid_reclutador': uidFirebase}));
    if (res.statusCode >= 200 && res.statusCode < 300) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reclutador eliminado')));
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
      floatingActionButton: SimpleButton(
        title: 'Nuevo Reclutador',
        icon: Icons.person_add_alt,
        onTap: _openCrearReclutador,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Removed footer reserved space usage
                final minBodyHeight = constraints.maxHeight;
                return RefreshIndicator(
                  onRefresh: _refresh,
                  child: SingleChildScrollView(
                    controller: _scrollCtrl,
                    physics: const ClampingScrollPhysics(),
                    padding: const EdgeInsets.only(
                      top: 12,
                      bottom: 12,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 500),
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
                                      'Reclutadores Registrados',
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
                                    'Total: ${_paginacion!.totalReclutadores}  •  Página: ${_paginacion!.paginaActual}/${_paginacion!.totalPaginas}  •  Tamaño: ${_paginacion!.tamanoPagina}',
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
                                else if (_Reclutadores.isEmpty)
                                  const Padding(
                                    padding: EdgeInsets.only(top: 80),
                                    child: Center(child: Text('No hay Reclutadores con cuenta activa en firebase.')),
                                  )
                                else
                                  Column(
                                    children: [
                                      for (final r in _Reclutadores) _cardReclutador(r),
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
                );
              },
            ),
          ),

          // Removed footer widget
        ],
      ),
    );
  }
}


class _ReclutadorFormDialog extends StatefulWidget {
  final String title;
  final ReclutadorItem? initial;
  final Future<void> Function(ReclutadorItem item) onSubmit;
  final List<dynamic> data;
  final List<DropdownMenuItem<String>> empresasItems;
  const _ReclutadorFormDialog({required this.title, this.initial, required this.onSubmit, required this.data, required this.empresasItems, Key? key}) : super(key: key);
  @override
  State<_ReclutadorFormDialog> createState() => _ReclutadorFormDialogState();
}

class _ReclutadorFormDialogState extends State<_ReclutadorFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nombreCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _generoCtrl;
  late TextEditingController _confirmEmailCtrl;
  final _empresaNombreCtrl = TextEditingController();
  String? _empresaSeleccionada;
  bool _sending = false;

  List<DropdownMenuItem<String>> empresasItems = [];
  List<dynamic> data = [];

  @override
  void initState() {
    super.initState();
    _nombreCtrl = TextEditingController(text: widget.initial?.nombre ?? '');
    _emailCtrl   = TextEditingController(text: widget.initial?.correo ?? '');
    _confirmEmailCtrl   = TextEditingController(text: widget.initial?.correo ?? '');
    _generoCtrl    = TextEditingController(text: widget.initial?.genero ?? '');
    empresasItems = widget.empresasItems;
    data = widget.data;
  }

 

  @override
  void dispose() {
    _nombreCtrl.dispose(); _emailCtrl.dispose(); _generoCtrl.dispose(); _confirmEmailCtrl.dispose(); _empresaNombreCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(()=>_sending=true);
    final nombre = _nombreCtrl.text.trim();
    final correo = _emailCtrl.text.trim();
    final genero = _generoCtrl.text.trim();
    final empresa = _empresaNombreCtrl.text.trim();
    final idEmpresa = int.tryParse(_empresaSeleccionada?? '') ?? 0;
    final item = ReclutadorItem(
      idUsuario: widget.initial?.idUsuario ?? 0,
      idReclutador: widget.initial?.idReclutador ?? 0,
      nombre: nombre,
      correo: correo,
      genero: genero,
      urFotoPerfil: widget.initial?.urFotoPerfil ?? '',
      uidFirebase: widget.initial?.uidFirebase ?? '',
      idEmpresa: idEmpresa,
      empresa: empresa,
    );
  
    await widget.onSubmit(item);
    if (mounted) { setState(()=>_sending=false); Navigator.of(context).maybePop(); }
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
                  title: "Correo electrónico",
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'El correo es obligatorio.';
                    }
                    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
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
                    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                    if (!emailRegex.hasMatch(value)) {
                      return 'Ingrese un correo válido.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                DropdownInput<String>(
                  title: "Empresa",
                  required: true,
                  items: empresasItems,
                  value: _empresaSeleccionada,
                  validator: (value) {
                    if (value == null || value.isEmpty ) return 'La empresa es obligatoria.';
                    return null;
                  },
                  onChanged: (valor) {
                    if (valor == null) return;
                    final valorInt = int.tryParse(valor);
                    final itemEncontrado = data.firstWhere(
                      (elemento) => elemento['id'] == valorInt
                    );
                    setState(() {
                      _empresaSeleccionada = valor;
                      _empresaNombreCtrl.text = itemEncontrado['nombre'] ?? '';
                    });
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
          title: _sending ? 'Guardando...' : 'Guardar',
          icon: Icons.save,
          onTap: _sending? null : _submit,
        ),
      ],
    );
  }
}
