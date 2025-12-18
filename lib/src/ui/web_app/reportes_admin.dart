import 'dart:convert';
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

/* ============================ Modelos ============================ */
class Paginacion {
  final int totalReportes;
  final int totalPaginas;
  final int paginaActual;
  final int tamanoPagina;

  const Paginacion({
    required this.totalReportes,
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
      totalReportes: _toInt(json['total_reportes']),
      totalPaginas: _toInt(json['total_paginas']),
      paginaActual: _toInt(json['pagina_actual']),
      tamanoPagina: _toInt(json['tamano_pagina']),
    );
  }
}

class ReporteItem {
  final int idReporte;
  final int idContenido;
  final String tipoContenido;
  final String razon;
  final String descripcion;
  final DateTime fechaReporte;
  final String estado; // "Resuelto" | "En espera"

  const ReporteItem({
    required this.idReporte,
    required this.idContenido,
    required this.tipoContenido,
    required this.razon,
    required this.descripcion,
    required this.fechaReporte,
    required this.estado,
  });

  factory ReporteItem.fromJson(Map<String, dynamic> json) {
    int _toInt(dynamic v) {
      if (v is int) return v;
      return int.tryParse('$v') ?? 0;
    }

    return ReporteItem(
      idReporte: _toInt(json['id_reporte']),
      idContenido: _toInt(json['id_contenido']),
      tipoContenido: (json['tipo_contenido'] ?? '').toString(),
      razon: (json['razon'] ?? '').toString(),
      descripcion: (json['descripcion'] ?? '').toString(),
      fechaReporte: DateTime.tryParse((json['fecha_reporte'] ?? '').toString())?.toLocal() ?? DateTime.now(),
      estado: (json['estado'] ?? '').toString(),
    );
  }
}

class PublicacionDetalle {
  final int idPublicacion;
  final int idAlumno;
  final String autorNombre;
  final String autorAvatar;
  final String contenido;
  final String mediaUrl;
  final DateTime? fecha;

  const PublicacionDetalle({
    required this.idPublicacion,
    required this.idAlumno,
    required this.autorNombre,
    required this.autorAvatar,
    required this.contenido,
    required this.mediaUrl,
    required this.fecha,
  });

  factory PublicacionDetalle.fromJson(Map<String, dynamic> root) {
    // Permite que el JSON sea directamente la publicación o anidado bajo alguna clave
    final Map<String, dynamic> j = (root['publicacion'] is Map)
        ? Map<String, dynamic>.from(root['publicacion'])
        : root;

    T _get<T>(List<String> keys, T def) {
      for (final k in keys) {
        if (j[k] != null) {
          final v = j[k];
          if (v is T) return v;
          // Intento parse básico
          if (T == int && v is String) return int.tryParse(v) as T? ?? def;
          if (T == String) return v.toString() as T;
        }
      }
      return def;
    }

    String _nestedString(List<List<String>> paths, String def) {
      for (final path in paths) {
        dynamic cur = j;
        bool ok = true;
        for (final seg in path) {
          if (cur is Map && cur[seg] != null) {
            cur = cur[seg];
          } else {
            ok = false; break;
          }
        }
        if (ok) return cur.toString();
      }
      return def;
    }

    DateTime? _date(List<String> keys) {
      for (final k in keys) {
        final raw = j[k];
        if (raw != null) {
          final d = DateTime.tryParse(raw.toString());
          if (d != null) return d.toLocal();
        }
      }
      return null;
    }

    return PublicacionDetalle(
      idPublicacion: _get<int>(['id_publicacion', 'idPublicacion', 'id'], 0),
      idAlumno: _get<int>(['id_alumno', 'autor_id', 'idAutor'], 0),
      autorNombre: _nestedString([
        ['autor', 'nombre'],
        ['usuario', 'nombre'],
        ['nombre']
      ], ''),
      autorAvatar: _nestedString([
        ['autor', 'url_foto_perfil'],
        ['usuario', 'url_foto_perfil'],
        ['url_foto_perfil'],
        ['avatar']
      ], ''),
      contenido: _get<String>(['contenido', 'descripcion', 'texto'], ''),
      mediaUrl: _get<String>(['media_url', 'media', 'url_multimedia'], ''),
      fecha: _date(['fecha', 'fecha_publicacion', 'createdAt']),
    );
  }
}

/* ============================ Página ============================ */
class ReportesAdminPage extends StatefulWidget {
  const ReportesAdminPage({Key? key}) : super(key: key);

  @override
  State<ReportesAdminPage> createState() => _ReportesAdminPageState();
}

class _ReportesAdminPageState extends State<ReportesAdminPage> {
  static const String _endpoint = 'https://oda-talent-back-81413836179.us-central1.run.app/api/reportes/ver_reportes';

  // Datos y paginación
  List<ReporteItem> _reportes = const [];
  Paginacion? _paginacion;
  Map<String, dynamic>? _rawResponse; // Guarda TODOS los datos recibidos
  int _page = 1;
  final int _limit = 10;
  bool _loading = false;
  String? _error;
  String _estado = 'pendiente'; // filtro actual

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
    _loadPage(1); // carga pendientes por defecto
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
      final uri = Uri.parse('$_endpoint?page=$page&limit=$_limit&estado=$_estado');
      final res = await http.get(uri, headers: headers);

      if (res.statusCode >= 400) {
        throw Exception('Error ${res.statusCode}: ${res.body}');
      }

      final decoded = json.decode(res.body);
      if (decoded is! Map<String, dynamic>) {
        throw Exception('Formato inesperado');
      }

      final pag = Paginacion.fromJson(Map<String, dynamic>.from(decoded['paginacion'] ?? {}));
      final list = (decoded['reportes'] as List? ?? [])
          .map((e) => ReporteItem.fromJson(Map<String, dynamic>.from(e)))
          .toList();

      setState(() {
        _page = pag.paginaActual;
        _paginacion = pag;
        _reportes = list;
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

  void _setEstado(String nuevo) {
    if (_estado == nuevo) return;
    setState(() {
      _estado = nuevo;
      _page = 1; // reinicia paginación
    });
    _loadPage(1);
  }

  bool _isEnEspera(String s) {
    final e = s.toLowerCase();
    return e.contains('espera') || e.contains('pend');
  }

  Future<PublicacionDetalle> _fetchPublicacionDetalle(int idContenido) async {
    final headers = await context.read<UserDataProvider>().getAuthHeaders();
    final uri = Uri.parse('https://oda-talent-back-81413836179.us-central1.run.app/api/experiencias_alumnos/ver/$idContenido');
    final res = await http.get(uri, headers: headers);
    if (res.statusCode >= 400) {
      throw Exception('Error ${res.statusCode}: ${res.body}');
    }
    final decoded = json.decode(res.body);
    if (decoded is Map<String, dynamic>) {
      return PublicacionDetalle.fromJson(decoded);
    }
    throw Exception('Formato inesperado en detalle de publicación');
  }

  void _onReporteTap(ReporteItem r) {
    if (!_isEnEspera(r.estado)) return;
    if (r.tipoContenido.toLowerCase() != 'publicacion') return;
    _openPublicacionModal(r);
  }

  void _openPublicacionModal(ReporteItem r) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: FutureBuilder<PublicacionDetalle>(
            future: _fetchPublicacionDetalle(r.idContenido),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return SizedBox(
                  width: 720,
                  height: 420,
                  child: const Center(child: CircularProgressIndicator()),
                );
              }
              if (snap.hasError) {
                return SizedBox(
                  width: 520,
                  height: 200,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text('Error al cargar: ${snap.error}', textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
                    ),
                  ),
                );
              }
              final d = snap.data!;
              return _PublicacionModalContent(
                detalle: d,
                idReporte: r.idReporte,
                onUpdate: () {
                  Navigator.of(context).maybePop();
                  _refresh();
                },
              );
            },
          ),
        );
      },
    );
  }

  // =============== UI Helpers ===============
  String _formatDate(DateTime d) {
    String two(int x) => x.toString().padLeft(2, '0');
    return '${two(d.day)}/${two(d.month)}/${d.year} ${two(d.hour)}:${two(d.minute)}';
  }

  Color _estadoColorBg(String estado, ThemeController theme) {
    final e = estado.toLowerCase();
    if (e.contains('resuelto')) return Colors.green.withOpacity(0.15);
    if (e.contains('espera') || e.contains('pend')) return Colors.amber.withOpacity(0.2);
    return theme.primario().withOpacity(0.15);
  }

  Color _estadoColorText(String estado, ThemeController theme) {
    final e = estado.toLowerCase();
    if (e.contains('resuelto')) return Colors.green.shade700;
    if (e.contains('espera') || e.contains('pend')) return Colors.amber.shade800;
    return theme.primario();
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

  Widget _cardReporte(ReporteItem r) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _onReporteTap(r),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Reporte #${r.idReporte}',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                      ),
                      Text(_formatDate(r.fechaReporte), style: const TextStyle(color: Colors.black54)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _badge(
                        r.estado,
                        bg: _estadoColorBg(r.estado, ThemeController.instance),
                        fg: _estadoColorText(r.estado, ThemeController.instance),
                      ),
                      _badge(
                        r.razon,
                        bg: Colors.purple.withOpacity(0.12),
                        fg: Colors.purple.shade700,
                      ),
                      _badge(
                        r.tipoContenido,
                        bg: Colors.blue.withOpacity(0.12),
                        fg: Colors.blue.shade700,
                      ),
                      _badge('ID Contenido: ${r.idContenido}', bg: Colors.grey.shade100, fg: Colors.black87),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    r.descripcion,
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _paginationBar() {
    final pag = _paginacion;
    final totalPages = pag?.totalPaginas ?? 1;
    final total = pag?.totalReportes ?? _reportes.length;

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

  Widget _estadoToggle() {
    final theme = ThemeController.instance;
    final bool pendientesSel = _estado == 'pendiente';
    final bool resueltosSel = _estado == 'resuelto';

    Color bg(bool sel) => sel ? theme.secundario().withOpacity(0.85) : theme.primario().withOpacity(0.15);
    Color fg(bool sel) => sel ? theme.primario() : theme.primario();

    return Center(
      child: Wrap(
        spacing: 16,
        children: [
          SimpleButton(
            title: 'Pendientes',
            backgroundColor: bg(pendientesSel),
            textColor: fg(pendientesSel),
            onTap: _loading ? null : () => _setEstado('pendiente'),
          ),
          SimpleButton(
            title: 'Resueltos',
            backgroundColor: bg(resueltosSel),
            textColor: fg(resueltosSel),
            onTap: _loading ? null : () => _setEstado('resuelto'),
          ),
        ],
      ),
    );
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
            case "Reclutadores":
              context.go('/admin/reclutadores');
              break;
            case "Artículos":
              context.go('/admin/articulos');
              break;
          }
        },
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
                                        'Reportes',
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
                                  const SizedBox(height: 10),
                                  _estadoToggle(), // botones de filtro
                                  const SizedBox(height: 16),
                                  if (_paginacion != null)
                                    Text(
                                      'Total: ${_paginacion!.totalReportes}  •  Página: ${_paginacion!.paginaActual}/${_paginacion!.totalPaginas}  •  Tamaño: ${_paginacion!.tamanoPagina}  •  Estado: $_estado',
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
                                  else if (_reportes.isEmpty)
                                    const Padding(
                                      padding: EdgeInsets.only(top: 80),
                                      child: Center(child: Text('No hay reportes disponibles.')),
                                    )
                                  else
                                    Column(
                                      children: [
                                        for (final r in _reportes) _cardReporte(r),
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

class _PublicacionModalContent extends StatelessWidget {
  final PublicacionDetalle detalle;
  final int idReporte;
  final VoidCallback? onUpdate;
  const _PublicacionModalContent({required this.detalle, required this.idReporte, this.onUpdate});

  Widget _avatar(String url, double radius) {
    final size = radius * 2;
    if (url.isEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFE0E0E0)),
        alignment: Alignment.center,
        child: Icon(Icons.person, size: radius, color: Colors.grey.shade700),
      );
    }
    if (url.startsWith('http')) {
      return ClipOval(
        child: Image.network(url, width: size, height: size, fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            width: size,
            height: size,
            decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFE0E0E0)),
            alignment: Alignment.center,
            child: Icon(Icons.person, size: radius, color: Colors.grey.shade700),
          ),
        ),
      );
    }
    return ClipOval(
      child: Image.asset(url, width: size, height: size, fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: size,
          height: size,
          decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFE0E0E0)),
          alignment: Alignment.center,
          child: Icon(Icons.person, size: radius, color: Colors.grey.shade700),
        ),
      ),
    );
  }

  Future<void> _resolverReporte(BuildContext context) async {
    try {
      final headersBase = await context.read<UserDataProvider>().getAuthHeaders();
      final headers = {...headersBase, 'Content-Type': 'application/json'};
      final res = await http.put(
        Uri.parse('https://oda-talent-back-81413836179.us-central1.run.app/api/reportes/resolver_reporte'),
        headers: headers,
        body: jsonEncode({'id_reporte': idReporte}),
      );
      if (res.statusCode >= 200 && res.statusCode < 300) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reporte resuelto')));
        onUpdate?.call();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al resolver: ${res.statusCode}')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Excepción: $e')));
    }
  }

  Future<void> _eliminarPublicacion(BuildContext context) async {
    try {
      final headersBase = await context.read<UserDataProvider>().getAuthHeaders();
      final headers = {...headersBase, 'Content-Type': 'application/json'};
      final res = await http.delete(
        Uri.parse('https://oda-talent-back-81413836179.us-central1.run.app/api/reportes/eliminar_publicacion'),
        headers: headers,
        body: jsonEncode({
          'id_publicacion': detalle.idPublicacion,
          'id_reporte': idReporte,
        }),
      );
      if (res.statusCode >= 200 && res.statusCode < 300) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Publicación eliminada')));
        onUpdate?.call();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al eliminar: ${res.statusCode}')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Excepción: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;
    final isMobile = MediaQuery.of(context).size.width < 640;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 820),
      child: Material(
        color: theme.background(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text('Detalle de publicación', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  ),
                  IconButton(
                    tooltip: 'Cerrar',
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const Divider(height: 1),
              const SizedBox(height: 12),

              // Header autor
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _avatar(detalle.autorAvatar, 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(detalle.autorNombre, style: const TextStyle(fontWeight: FontWeight.w700)),
                        if (detalle.fecha != null)
                          Text(detalle.fecha!.toString(), style: const TextStyle(fontSize: 12, color: Colors.black54)),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),
              Text(detalle.contenido),

              if (detalle.mediaUrl.isNotEmpty) ...[
                const SizedBox(height: 12),
                MediaContent(url: detalle.mediaUrl),
              ],

              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Center(
                child: isMobile
                    ? Column(
                        children: [
                          SimpleButton(
                            title: 'Eliminar Publicación',
                            icon: Icons.delete_forever,
                            backgroundColor: Colors.red,
                            textColor: Colors.white,
                            onTap: () => _eliminarPublicacion(context),
                          ),
                          const SizedBox(height: 12),
                          SimpleButton(
                            title: 'Resolver reporte',
                            icon: Icons.check_circle,
                            backgroundColor: Colors.green,
                            textColor: Colors.white,
                            onTap: () => _resolverReporte(context),
                          ),
                        ],
                      )
                    : Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 20,
                        runSpacing: 12,
                        children: [
                          SimpleButton(
                            title: 'Eliminar Publicación',
                            icon: Icons.delete_forever,
                            backgroundColor: Colors.red,
                            textColor: Colors.white,
                            onTap: () => _eliminarPublicacion(context),
                          ),
                          SimpleButton(
                            title: 'Resolver reporte',
                            icon: Icons.check_circle,
                            backgroundColor: Colors.green,
                            textColor: Colors.white,
                            onTap: () => _resolverReporte(context),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
