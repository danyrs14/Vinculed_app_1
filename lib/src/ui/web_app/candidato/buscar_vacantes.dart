import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:vinculed_app_1/src/core/controllers/theme_controller.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:vinculed_app_1/src/core/providers/user_provider.dart';

import 'package:vinculed_app_1/src/ui/widgets/elements/footer.dart';
import 'package:vinculed_app_1/src/ui/widgets/elements/header2.dart';
import 'package:vinculed_app_1/src/ui/widgets/text_inputs/text_input.dart';
import 'package:vinculed_app_1/src/ui/widgets/buttons/simple_buttons.dart';
import 'package:vinculed_app_1/src/ui/widgets/text_inputs/dropdown.dart';
import 'package:vinculed_app_1/src/ui/widgets/text_inputs/roles_multi_dropdown.dart';
import 'package:vinculed_app_1/src/ui/web_app/candidato/vacante.dart';

// Modelo simple para historial de búsquedas
class _HistoryItem {
  final int id;
  final String consulta;
  const _HistoryItem({required this.id, required this.consulta});
}

class JobSearchPage extends StatefulWidget {
  const JobSearchPage({super.key});

  @override
  State<JobSearchPage> createState() => _JobSearchPageState();
}

class _JobSearchPageState extends State<JobSearchPage> {
  final _queryCtrl = TextEditingController();
  final _locationCtrl = TextEditingController(); // entidad
  final _cityCtrl = TextEditingController(); // ciudad

  final _scrollCtrl = ScrollController();
  bool _showFooter = false;

  // Historial cargado desde backend
  List<_HistoryItem> _history = [];

  // ===== Estado para resultados reales y paginación =====
  final String _baseUrl = 'https://oda-talent-back-81413836179.us-central1.run.app/api/vacantes/buscar';
  int _page = 1;
  final int _limit = 10;
  String _ordenarPor = 'fecha_publicacion_desc';
  String? _selectedModalidad; // 'Presencial' | 'Remoto' | 'Híbrido'
  List<int> _selectedRolIds = [];
  bool _loading = false;
  String? _error;
  List<dynamic> _vacantes = [];
  int? _total; // si el backend lo envía
  bool _hasNext = false; // fallback si no hay total
  bool _initialRequested = false; // dispara fetch al entrar

  // filtros usados en el último fetch (para mantenerlos entre páginas)
  Map<String, String> _currentFilters = {};

  static const double _footerReservedSpace = EscomFooter.height;
  static const double _extraBottomPadding = 24.0;
  static const double _atEndThreshold = 4.0;

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_handleScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _handleScroll());
  }

  void _handleScroll() {
    final pos = _scrollCtrl.position;
    if (!pos.hasPixels || !pos.hasContentDimensions) return;

    // si el contenido cabe en pantalla, no muestres footer
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
    _queryCtrl.dispose();
    _locationCtrl.dispose();
    _cityCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;
    final w = MediaQuery.of(context).size.width;
    final isMobile = w < 700;

    // Dispara la petición inicial cuando ya tengamos idRol del usuario
    final userProv = context.watch<UserDataProvider>();
    if (!_initialRequested && userProv.idRol != null) {
      _initialRequested = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _fetchVacantes(onlyRequired: true, resetPage: true);
        _fetchHistory();
      });
    }

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
            case "Preferencias":
              context.go('/alumno/preferences');
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
                      _handleScroll();
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
                        constraints: const BoxConstraints(maxWidth: 900),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: minBodyHeight > 0 ? minBodyHeight : 0,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // Avatar + Título
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const CircleAvatar(
                                      radius: 22,
                                      backgroundImage: AssetImage('assets/images/amlo.jpg'),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Buscar Vacantes',
                                      style: TextStyle(
                                        fontSize: isMobile ? 26 : 32,
                                        fontWeight: FontWeight.w800,
                                        color: const Color(0xFF22313F),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 28),

                                // Formulario centrado
                                ConstrainedBox(
                                  constraints: const BoxConstraints(maxWidth: 900),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      // Fila de filtros compacta
                                      LayoutBuilder(
                                        builder: (ctx, constraints) {
                                          final width = constraints.maxWidth;
                                          
                                          // Definimos breakpoints para el diseño responsivo
                                          final isDesktop = width > 1100;
                                          final isTablet = width > 650 && width <= 1100;
                                          
                                          // Espaciado entre elementos
                                          const double spacing = 12.0;
                                          const double runSpacing = 16.0;

                                          // Calculamos el ancho base de una columna
                                          // Desktop: 4 columnas | Tablet: 2 columnas | Mobile: 1 columna
                                          int cols = isDesktop ? 4 : (isTablet ? 2 : 1);
                                          double itemWidth = (width - (spacing * (cols - 1)) - 32) / cols; // -32 por el padding del Card

                                          return Card(
                                            elevation: 2,
                                            shadowColor: Colors.black12,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                            color: Colors.white,
                                            margin: const EdgeInsets.only(bottom: 20),
                                            child: Padding(
                                              padding: const EdgeInsets.all(16.0),
                                              child: Wrap(
                                                spacing: spacing,
                                                runSpacing: runSpacing,
                                                crossAxisAlignment: WrapCrossAlignment.end, // Alinea el botón con los inputs
                                                children: [
                                                  // 1. BUSCADOR (Ocupa 2 espacios en Desktop si es posible)
                                                  SizedBox(
                                                    width: isDesktop ? (itemWidth * 2) + spacing : itemWidth,
                                                    child: TextInput(
                                                      title: 'Buscar por palabra clave',
                                                      controller: _queryCtrl,
                                                      keyboardType: TextInputType.text,
                                                      icon: const Icon(Icons.search, size: 20),
                                                    ),
                                                  ),

                                                  // 2. ROLES (Ocupa 2 espacios en Desktop para ver mejor los chips)
                                                  SizedBox(
                                                    width: isDesktop ? (itemWidth * 2) + spacing : itemWidth,
                                                    child: RolesMultiDropdown(
                                                      label: 'Buscar por roles de trabajo',
                                                      hintText: '',
                                                      onChanged: (roles) {
                                                        setState(() {
                                                          _selectedRolIds = roles.map((r) => r.id).toList();
                                                        });
                                                      },
                                                    ),
                                                  ),

                                                  // 3. ENTIDAD
                                                  SizedBox(
                                                    width: itemWidth,
                                                    child: TextInput(
                                                      title: 'Entidad / Estado',
                                                      controller: _locationCtrl,
                                                      keyboardType: TextInputType.text,
                                                      icon: const Icon(Icons.public, size: 20),
                                                    ),
                                                  ),

                                                  // 4. CIUDAD
                                                  SizedBox(
                                                    width: itemWidth,
                                                    child: TextInput(
                                                      title: 'Ciudad',
                                                      controller: _cityCtrl,
                                                      keyboardType: TextInputType.text,
                                                      icon: const Icon(Icons.location_city, size: 20),
                                                    ),
                                                  ),

                                                  // 5. MODALIDAD
                                                  SizedBox(
                                                    width: itemWidth,
                                                    child: DropdownInput<String>(
                                                      title: 'Modalidad',
                                                      value: _selectedModalidad,
                                                      icon: const Icon(Icons.work_outline, size: 20),
                                                      onChanged: (v) => setState(() => _selectedModalidad = v),
                                                      items: const [
                                                        DropdownMenuItem(value: 'Presencial', child: Text('Presencial')),
                                                        DropdownMenuItem(value: 'Remoto', child: Text('Remoto')),
                                                        DropdownMenuItem(value: 'Híbrido', child: Text('Híbrido')),
                                                      ],
                                                    ),
                                                  ),

                                                  // 6. ORDENAR Y BOTÓN (Agrupados visualmente o separados según espacio)
                                                  SizedBox(
                                                    width: itemWidth,
                                                    child: DropdownInput<String>(
                                                      title: 'Ordenar por',
                                                      required: true,
                                                      value: _ordenarPor,
                                                      icon: const Icon(Icons.sort, size: 20),
                                                      onChanged: (v) => setState(() { if (v != null) _ordenarPor = v; }),
                                                      items: const [
                                                        DropdownMenuItem(value: 'fecha_publicacion_desc', child: Text('Más recientes')),
                                                        DropdownMenuItem(value: 'fecha_publicacion_asc', child: Text('Más antiguas')),
                                                        DropdownMenuItem(value: 'monto_beca_desc', child: Text('Mayor Beca')),
                                                        DropdownMenuItem(value: 'monto_beca_asc', child: Text('Menor Beca')),
                                                      ],
                                                    ),
                                                  ),

                                                  // 7. BOTÓN DE BÚSQUEDA
                                                  // Le damos un ancho fijo o lleno dependiendo del diseño
                                                  SizedBox(
                                                    width: isDesktop ? itemWidth : double.infinity, 
                                                    height: 56, // Altura estándar de inputs material design para alineación
                                                    child: Padding(
                                                      padding: const EdgeInsets.only(top: 4.0), // Ajuste fino si el label del input empuja hacia abajo
                                                      child: SimpleButton(
                                                        title: 'Buscar Vacantes',
                                                        icon: Icons.search,
                                                        // Estilo para que resalte
                                                        primaryColor: true, 
                                                        onTap: _loading ? null : () => _onSearch(),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                      const SizedBox(height: 18),
                                      // Historial debajo de filtros (desde backend)
                                      if (_history.isNotEmpty) ...[
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            const Text(
                                              'Historial',
                                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                                            ),
                                            TextButton(
                                              onPressed: _clearHistory,
                                              child: const Text('Limpiar'),
                                            ),
                                          ],
                                        ),
                                        Align(
                                          alignment: Alignment.centerLeft,
                                          child: Wrap(
                                            spacing: 8,
                                            runSpacing: 8,
                                            children: _history
                                                .where((it) => it.consulta.trim().isNotEmpty)
                                                .map((it) => InputChip(
                                                      label: Text(it.consulta),
                                                      onPressed: () {
                                                        _queryCtrl.text = it.consulta;
                                                        _onSearch(fromChip: true);
                                                      },
                                                      onDeleted: () => _removeHistoryItem(it),
                                                    ))
                                                .toList(),
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                      ],

                                    ],
                                  ),
                                ),

                                const SizedBox(height: 24),

                                // ===== Contador de resultados =====
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    'Resultados: ' +
                                        (_total != null
                                            ? _total.toString()
                                            : _vacantes.length.toString()),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF22313F),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),

                                // ===== Lista de resultados reales =====
                                if (_loading)
                                  const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 12),
                                    child: Center(child: CircularProgressIndicator()),
                                  )
                                else if (_error != null)
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFF1F2),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: const Color(0xFFFCA5A5)),
                                    ),
                                    child: Text(
                                      _error!,
                                      style: const TextStyle(color: Colors.red),
                                    ),
                                  )
                                else ...[
                                  if (_vacantes.isEmpty)
                                    const Center(child: Text('Sin resultados'))
                                  else
                                    ListView.separated(
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      itemCount: _vacantes.length,
                                      separatorBuilder: (_, __) => const Divider(height: 1),
                                      itemBuilder: (context, index) {
                                        final raw = _vacantes[index];
                                        late final Map<String, dynamic> v;
                                        if (raw is Map<String, dynamic>) {
                                          v = raw;
                                        } else if (raw is Map) {
                                          v = Map<String, dynamic>.from(raw);
                                        } else {
                                          v = <String, dynamic>{};
                                        }

                                        final title = (v['titulo'] ?? v['title'] ?? 'Vacante').toString();
                                        final empresa = (v['nombre_empresa'] ?? v['empresa'] ?? '').toString();
                                        final modalidad = (v['modalidad'] ?? '').toString();
                                        final numVac = v['numero_vacantes'];
                                        final numVacStr = numVac is int
                                            ? (numVac == 1 ? '1 vacante' : '$numVac vacantes')
                                            : (numVac?.toString() ?? '');
                                        final fPub = _fmtDate(v['fecha_publicacion']?.toString());
                                        final fLim = v['fecha_limite'];
                                        final fLimStr = fLim != null ? _fmtDate(fLim.toString()) : '';

                                        // id de la vacante para navegar al detalle
                                        int? idVac;
                                        final anyId = v['id_vacante'] ?? v['id'];
                                        if (anyId is int) idVac = anyId;
                                        else if (anyId != null) {
                                          idVac = int.tryParse(anyId.toString());
                                        }

                                        return ListTile(
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                          title: Text(
                                            title,
                                            style: const TextStyle(fontWeight: FontWeight.w700),
                                          ),
                                          subtitle: Padding(
                                            padding: const EdgeInsets.only(top: 4),
                                            child: Wrap(
                                              spacing: 12,
                                              runSpacing: 6,
                                              children: [
                                                if (empresa.isNotEmpty) _info(Icons.business, empresa),
                                                if (numVacStr.isNotEmpty) _info(Icons.people_alt_outlined, numVacStr),
                                                if (modalidad.isNotEmpty) _info(Icons.work_outline, modalidad),
                                                if (fPub.isNotEmpty) _info(Icons.calendar_today_outlined, 'Publicada: ' + fPub),
                                                if (fLimStr.isNotEmpty) _info(Icons.event_busy_outlined, 'Límite: ' + fLimStr),
                                              ],
                                            ),
                                          ),
                                          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                                          onTap: (idVac == null)
                                              ? null
                                              : () {
                                                  Navigator.of(context).push(
                                                    MaterialPageRoute(
                                                      builder: (_) => JobDetailPage(idVacante: idVac!),
                                                    ),
                                                  );
                                                },
                                        );
                                      },
                                    ),

                                  const SizedBox(height: 12),

                                  // ===== Paginación =====
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SimpleButton(
                                        title: 'Anterior',
                                        onTap: _page > 1 && !_loading
                                            ? () {
                                                setState(() => _page -= 1);
                                                _fetchVacantes();
                                              }
                                            : null,
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        _total != null
                                            ? 'Página $_page de ' + (((_total! + _limit - 1) ~/ _limit)).toString()
                                            : 'Página $_page',
                                      ),
                                      const SizedBox(width: 12),
                                      SimpleButton(
                                        title: 'Siguiente',
                                        onTap: !_loading && (_hasNext || (_total != null && _page < ((_total! + _limit - 1) ~/ _limit)))
                                            ? () {
                                                setState(() => _page += 1);
                                                _fetchVacantes();
                                              }
                                            : null,
                                      ),
                                    ],
                                  ),
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

          // Footer animado (sin cambios)
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

  // Ejecuta la búsqueda con filtros de los inputs
  void _onSearch({bool fromChip = false}) {
    final q = _queryCtrl.text.trim();
    final entidad = _locationCtrl.text.trim();
    final ciudad = _cityCtrl.text.trim();

    if (q.isNotEmpty && !fromChip) {
      _addToHistory(q);
    }

    final filters = <String, String>{};
    if (q.isNotEmpty) filters['query'] = q;
    if (entidad.isNotEmpty) filters['entidad'] = entidad;
    if (ciudad.isNotEmpty) filters['ciudad'] = ciudad;
    if (_selectedModalidad != null && _selectedModalidad!.isNotEmpty) {
      filters['modalidad'] = _selectedModalidad!;
    }
    if (_selectedRolIds.isNotEmpty) {
      filters['rol_trabajo'] = _selectedRolIds.join(',');
    }

    _page = 1;
    _currentFilters = filters;
    _fetchVacantes(resetPage: true);
  }

  // ===== Helpers de historial =====
  void _addToHistory(String query) {
    // El backend administra el historial; función mantenida por compatibilidad si se requiere en el futuro
    // Actualmente no se usa para evitar desincronización con el servidor
  }

  void _clearHistory() async {
    try {
      final userProv = context.read<UserDataProvider>();
      final idRol = userProv.idRol;
      if (idRol == null) return;
      final headers = await userProv.getAuthHeaders();
      final uri = Uri.parse('https://oda-talent-back-81413836179.us-central1.run.app/api/alumnos/limpiar_historial');
      final res = await http.delete(
        uri,
        headers: headers,
        body: jsonEncode({'id_alumno': idRol}),
      );
      if (res.statusCode >= 200 && res.statusCode < 300) {
        setState(() => _history.clear());
      }
    } catch (_) {}
  }

  Future<void> _removeHistoryItem(_HistoryItem item) async {
    try {
      final userProv = context.read<UserDataProvider>();
      final idRol = userProv.idRol;
      if (idRol == null) return;
      final headers = await userProv.getAuthHeaders();
      final uri = Uri.parse('https://oda-talent-back-81413836179.us-central1.run.app/api/alumnos/borrar_busqueda');
      final res = await http.delete(
        uri,
        headers: headers,
        body: jsonEncode({'id_alumno': idRol, 'id_busqueda': item.id}),
      );
      if (res.statusCode >= 200 && res.statusCode < 300) {
        setState(() => _history.removeWhere((h) => h.id == item.id));
      }
    } catch (_) {}
  }

  Future<void> _fetchHistory() async {
    try {
      final userProv = context.read<UserDataProvider>();
      final idRol = userProv.idRol;
      if (idRol == null) return;
      final headers = await userProv.getAuthHeaders();
      final uri = Uri.parse('https://oda-talent-back-81413836179.us-central1.run.app/api/alumnos/historial_busquedas')
          .replace(queryParameters: {'id_alumno': idRol.toString(), 'limit': '10'});
      final res = await http.get(uri, headers: headers);
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final data = jsonDecode(res.body);
        if (data is List) {
          final list = data
              .whereType<Map>()
              .map((m) => Map<String, dynamic>.from(m))
              .map((m) => _HistoryItem(
                    id: (m['id_busqueda'] ?? 0) is int
                        ? (m['id_busqueda'] as int)
                        : int.tryParse('${m['id_busqueda']}') ?? 0,
                    consulta: (m['consulta'] ?? '').toString(),
                  ))
              .toList();
          setState(() => _history = list);
        }
      }
    } catch (_) {}
  }

  // Pequeño helper para mostrar icono + texto
  Widget _info(IconData icon, String text) {
    final theme = ThemeController.instance;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: theme.secundario()),
        const SizedBox(width: 4),
        Text(text),
      ],
    );
  }

  String _fmtDate(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    try {
      final dt = DateTime.parse(iso).toLocal();
      final mm = dt.month.toString().padLeft(2, '0');
      final dd = dt.day.toString().padLeft(2, '0');
      return '${dt.year}-$mm-$dd';
    } catch (_) {
      return iso;
    }
  }

  // ===== Llamada real al backend con paginación =====
  Future<void> _fetchVacantes({bool onlyRequired = false, bool resetPage = false}) async {
    final userProv = context.read<UserDataProvider>();
    final idRol = userProv.idRol; // requerido como id_alumno
    if (idRol == null) {
      setState(() {
        _error = 'Cargando datos de usuario...';
      });
      return;
    }

    if (resetPage) _page = 1;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final headers = await userProv.getAuthHeaders();

      final params = <String, String>{
        'ordenar_por': _ordenarPor,
        'id_alumno': idRol.toString(),
        'page': _page.toString(),
        'limit': _limit.toString(),
      };

      if (!onlyRequired) {
        params.addAll(_currentFilters);
      }

      final uri = Uri.parse(_baseUrl).replace(queryParameters: params);
      final res = await http.get(uri, headers: headers);

      if (res.statusCode < 200 || res.statusCode >= 300) {
        throw Exception('Error ${res.statusCode}');
      }

      final body = jsonDecode(res.body);

      if (body is! Map) {
        throw Exception('Formato inesperado');
      }

      final map = Map<String, dynamic>.from(body);
      final items = (map['vacantes'] as List?) ?? const [];
      final pag = map['paginacion'] as Map?;
      final pagMap = pag != null ? Map<String, dynamic>.from(pag) : null;
      final total = pagMap?['total_vacantes'] as int?;
      final totalPaginas = pagMap?['total_paginas'] as int?;
      final paginaActual = pagMap?['pagina_actual'] as int?;

      setState(() {
        _vacantes = items;
        _total = total;
        if (paginaActual != null) _page = paginaActual;
        _hasNext = (totalPaginas != null && paginaActual != null)
            ? paginaActual < totalPaginas
            : items.length == _limit;
      });
    } catch (e) {
      setState(() {
        _error = 'No se pudieron cargar las vacantes. $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }
}
