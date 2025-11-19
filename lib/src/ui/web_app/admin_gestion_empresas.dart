import 'dart:convert';
import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart' as fs;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:vinculed_app_1/src/core/controllers/theme_controller.dart';
import 'package:vinculed_app_1/src/core/providers/user_provider.dart';
import 'package:vinculed_app_1/src/ui/widgets/elements/header4.dart';
import 'package:vinculed_app_1/src/ui/widgets/elements/footer.dart';
import 'package:vinculed_app_1/src/ui/widgets/buttons/simple_buttons.dart';

class EmpresaItem {
  final int idEmpresa;
  final String nombre;
  final String descripcion;
  final String sitioWeb;
  final String urlLogo;

  EmpresaItem({
    required this.idEmpresa,
    required this.nombre,
    required this.descripcion,
    required this.sitioWeb,
    required this.urlLogo,
  });

  factory EmpresaItem.fromJson(Map<String,dynamic> j) => EmpresaItem(
    idEmpresa: (j['id'] is int) ? j['id'] : int.tryParse('${j['id']}') ?? 0,
    nombre: (j['nombre'] ?? '').toString(),
    descripcion: (j['descripcion'] ?? '').toString(),
    sitioWeb: (j['sitio_web'] ?? '').toString(),
    urlLogo: (j['url_logo'] ?? '').toString(),
  );

  Map<String,dynamic> toJsonCreate(String? logoUrlOverride) => {
    'nombre': nombre,
    'descripcion': descripcion,
    'sitio_web': sitioWeb,
    'url_logo': logoUrlOverride ?? urlLogo,
  };

  Map<String,dynamic> toJsonUpdate(String? logoUrlOverride) => {
    'id_empresa': idEmpresa,
    'nombre': nombre,
    'descripcion': descripcion,
    'sitio_web': sitioWeb,
    'url_logo': logoUrlOverride ?? urlLogo,
  };
}

class AdminGestionEmpresasPage extends StatefulWidget {
  const AdminGestionEmpresasPage({super.key});
  @override
  State<AdminGestionEmpresasPage> createState() => _AdminGestionEmpresasPageState();
}

class _AdminGestionEmpresasPageState extends State<AdminGestionEmpresasPage> {
  static const _getUrl = 'https://oda-talent-back-81413836179.us-central1.run.app/api/empresas/obtener_empresas';
  static const _postUrl = 'https://oda-talent-back-81413836179.us-central1.run.app/api/empresas/agregar_empresa';
  static const _putUrl  = 'https://oda-talent-back-81413836179.us-central1.run.app/api/empresas/actualizar_empresa';
  static const _delUrl  = 'https://oda-talent-back-81413836179.us-central1.run.app/api/empresas/eliminar_empresa';

  List<EmpresaItem> _empresas = [];
  bool _loading = false;
  String? _error;

  final ScrollController _scrollCtrl = ScrollController();
  bool _showFooter = false;
  static const double _footerReservedSpace = EscomFooter.height;
  static const double _extraBottomPadding = 24;
  static const double _atEndThreshold = 4;
  final usuario = FirebaseAuth.instance.currentUser!;

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _onScroll());
    _fetchEmpresas();
  }

  @override
  void dispose() {
    _scrollCtrl.removeListener(_onScroll); _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollCtrl.hasClients) return;
    final pos = _scrollCtrl.position;
    if (!pos.hasPixels || !pos.hasContentDimensions) return;
    if (pos.maxScrollExtent <= 0) { if (_showFooter) setState(()=>_showFooter=false); return; }
    final atBottom = pos.pixels >= (pos.maxScrollExtent - _atEndThreshold);
    if (atBottom != _showFooter) setState(()=>_showFooter = atBottom);
  }

  Future<void> _fetchEmpresas() async {
    setState(()=>_loading=true); _error=null;
    try {
      final headers = await context.read<UserDataProvider>().getAuthHeaders();
      final res = await http.get(Uri.parse(_getUrl), headers: headers);
      if (res.statusCode >= 400) throw Exception('Error ${res.statusCode}: ${res.body}');
      final data = json.decode(res.body);
      if (data is! List) throw Exception('Formato inesperado');
      _empresas = data.map((e)=>EmpresaItem.fromJson(Map<String,dynamic>.from(e))).toList();
    } catch (e) { _error = e.toString(); }
    finally { if (mounted) setState(()=>_loading=false); }
  }

  Future<String?> _uploadLogo(Uint8List bytes, String filename) async {
    try {
      final lowerCaseFilename = filename.toLowerCase();
      String contentType = 'image/png';
      if (lowerCaseFilename.endsWith('.jpg') || lowerCaseFilename.endsWith('.jpeg')) {
        contentType= 'image/jpeg';
      }
      if (lowerCaseFilename.endsWith('.png')) {
        contentType= 'image/png';
      }
      if (lowerCaseFilename.endsWith('.gif')) {
        contentType= 'image/gif';
      }
      if (lowerCaseFilename.endsWith('.webp')) {
        contentType=  'image/webp';
      }
      if (lowerCaseFilename.endsWith('.svg')) {
        contentType= 'image/svg+xml';
      }
      final path ='logo_empresa/${usuario.uid}/${DateTime.now().millisecondsSinceEpoch}_$filename';
      final storage = fs.FirebaseStorage.instance;
      final ref = storage.ref().child(path);
      await ref.putData(bytes, SettableMetadata(contentType: contentType));
      return await ref.getDownloadURL();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error subiendo logo: $e')));
      return null;
    }
  }

  Future<void> _crearEmpresa(EmpresaItem base, Uint8List? logoBytes, String? fileName) async {
    final headers = await context.read<UserDataProvider>().getAuthHeaders();
    String? logoUrl;
    if (logoBytes != null && fileName != null) {
      logoUrl = await _uploadLogo(logoBytes, fileName);
      if (logoUrl == null) return; // Falló subida
    }
    final body = jsonEncode(base.toJsonCreate(logoUrl));
    final res = await http.post(Uri.parse(_postUrl), headers: headers, body: body);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Empresa creada')));
      await _fetchEmpresas();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al crear: ${res.statusCode}')));
    }
  }

  Future<void> _actualizarEmpresa(EmpresaItem base, Uint8List? logoBytes, String? fileName) async {
    final headersBase = await context.read<UserDataProvider>().getAuthHeaders();
    final headers = {...headersBase, 'Content-Type': 'application/json'};
    String? logoUrl;
    if (logoBytes != null && fileName != null) {
      logoUrl = await _uploadLogo(logoBytes, fileName);
      if (logoUrl == null) return;
    }
    final body = jsonEncode(base.toJsonUpdate(logoUrl));
    final res = await http.put(Uri.parse(_putUrl), headers: headers, body: body);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Empresa actualizada')));
      await _fetchEmpresas();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al actualizar: ${res.statusCode}')));
    }
  }

  Future<void> _eliminarEmpresa(int id) async {
    final headersBase = await context.read<UserDataProvider>().getAuthHeaders();
    final headers = {...headersBase, 'Content-Type': 'application/json'};
    final res = await http.delete(Uri.parse(_delUrl), headers: headers, body: jsonEncode({'id_empresa': id}));
    if (res.statusCode >= 200 && res.statusCode < 300) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Empresa eliminada')));
      await _fetchEmpresas();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al eliminar: ${res.statusCode}')));
    }
  }

  void _openCrearEmpresa() {
    showDialog(
      context: context,
      builder: (ctx) => _EmpresaFormDialog(
        title: 'Agregar Empresa',
        onSubmit: (item, bytes, name) => _crearEmpresa(item, bytes, name),
      ),
    );
  }

  void _openEditarEmpresa(EmpresaItem e) {
    showDialog(
      context: context,
      builder: (ctx) => _EmpresaFormDialog(
        title: 'Editar Empresa',
        initial: e,
        onSubmit: (item, bytes, name) => _actualizarEmpresa(item, bytes, name),
      ),
    );
  }

  Widget _cardEmpresa(EmpresaItem e) {
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
              child: e.urlLogo.isNotEmpty ? Image.network(
                e.urlLogo,
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
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(e.nombre, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Text(e.descripcion),
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: () {},
                    child: Text(e.sitioWeb, style: TextStyle(color: theme.primario(), decoration: TextDecoration.underline)),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12, // espacio vertical cuando se apilan en móvil
                    children: [
                      SimpleButton(
                        title: 'Editar',
                        icon: Icons.edit,
                        onTap: () => _openEditarEmpresa(e),
                      ),
                      SimpleButton(
                        title: 'Eliminar',
                        icon: Icons.delete_forever,
                        backgroundColor: Colors.red,
                        textColor: Colors.white,
                        onTap: () => _confirmEliminar(e.idEmpresa),
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

  void _confirmEliminar(int id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar empresa'),
        content: const Text('¿Confirmas eliminar esta empresa?'),
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
            onTap: () { Navigator.pop(ctx); _eliminarEmpresa(id); },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width; final isMobile = width < 700;
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
          }
        },
      ),
      floatingActionButton: SimpleButton(
        title: 'Nueva Empresa',
        icon: Icons.add_business,
        onTap: _openCrearEmpresa,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final minBodyHeight = constraints.maxHeight - _footerReservedSpace - _extraBottomPadding;
                return RefreshIndicator(
                  onRefresh: _fetchEmpresas,
                  child: SingleChildScrollView(
                    controller: _scrollCtrl,
                    physics: const ClampingScrollPhysics(),
                    padding: const EdgeInsets.only(top: 12, bottom: _footerReservedSpace + _extraBottomPadding),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 500),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(minHeight: minBodyHeight > 0 ? minBodyHeight : 0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Text('Gestión de Empresas', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                                    const Spacer(),
                                    if (_loading) const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 3)),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                if (_error != null) Padding(
                                  padding: const EdgeInsets.only(top: 40),
                                  child: Center(child: Text('Error: $_error', style: const TextStyle(color: Colors.red))),
                                )
                                else if (_empresas.isEmpty && !_loading) Padding(
                                  padding: const EdgeInsets.only(top: 60),
                                  child: const Center(child: Text('No hay empresas registradas.')),)
                                else ...[
                                  for (final e in _empresas) _cardEmpresa(e),
                                ],
                                const SizedBox(height: 40),
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
          Positioned(
            left: 0, right: 0, bottom: 0,
            child: AnimatedSlide(
              duration: const Duration(milliseconds: 220), curve: Curves.easeOut,
              offset: _showFooter ? Offset.zero : const Offset(0,1),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 220), opacity: _showFooter ? 1 : 0,
                child: EscomFooter(isMobile: isMobile),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmpresaFormDialog extends StatefulWidget {
  final String title;
  final EmpresaItem? initial;
  final Future<void> Function(EmpresaItem item, Uint8List? logoBytes, String? fileName) onSubmit;
  const _EmpresaFormDialog({required this.title, this.initial, required this.onSubmit});
  @override
  State<_EmpresaFormDialog> createState() => _EmpresaFormDialogState();
}

class _EmpresaFormDialogState extends State<_EmpresaFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nombreCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _webCtrl;
  late TextEditingController _logoCtrl; // muestra URL final
  Uint8List? _pickedBytes;
  String? _pickedName;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _nombreCtrl = TextEditingController(text: widget.initial?.nombre ?? '');
    _descCtrl   = TextEditingController(text: widget.initial?.descripcion ?? '');
    _webCtrl    = TextEditingController(text: widget.initial?.sitioWeb ?? '');
    _logoCtrl   = TextEditingController(text: widget.initial?.urlLogo ?? '');
  }

  @override
  void dispose() {
    _nombreCtrl.dispose(); _descCtrl.dispose(); _webCtrl.dispose(); _logoCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickLogo() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image, withData: true);
    if (result != null && result.files.single.bytes != null) {
      setState(() {
        _pickedBytes = result.files.single.bytes;
        _pickedName  = result.files.single.name;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(()=>_sending=true);
    final item = EmpresaItem(
      idEmpresa: widget.initial?.idEmpresa ?? 0,
      nombre: _nombreCtrl.text.trim(),
      descripcion: _descCtrl.text.trim(),
      sitioWeb: _webCtrl.text.trim(),
      urlLogo: _logoCtrl.text.trim(),
    );
    await widget.onSubmit(item, _pickedBytes, _pickedName);
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
                TextFormField(
                  controller: _nombreCtrl,
                  decoration: const InputDecoration(labelText: 'Nombre'),
                  validator: _validNotEmpty,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Descripción'),
                  validator: _validNotEmpty,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _webCtrl,
                  decoration: const InputDecoration(labelText: 'Sitio Web'),
                  validator: _validWeb,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _logoCtrl,
                  decoration: const InputDecoration(labelText: 'URL logo (opcional si subes archivo)'),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    SimpleButton(
                      title: 'Subir logo',
                      icon: Icons.upload,
                      onTap: _pickLogo,
                    ),
                    const SizedBox(width: 12),
                    if (_pickedBytes != null) Text('Archivo listo: ${_pickedName}', style: TextStyle(color: theme.primario())),
                  ],
                ),
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
