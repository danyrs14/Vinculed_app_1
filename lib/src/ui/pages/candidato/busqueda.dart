import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:vinculed_app_1/src/core/controllers/theme_controller.dart';
import 'package:vinculed_app_1/src/ui/pages/candidato/menu.dart';
import 'package:vinculed_app_1/src/ui/pages/candidato/notificaciones.dart';
import 'package:vinculed_app_1/src/ui/pages/candidato/perfil.dart';
import 'package:vinculed_app_1/src/ui/widgets/buttons/simple_buttons.dart';
import 'package:vinculed_app_1/src/ui/widgets/text_inputs/text_input.dart';
import 'package:vinculed_app_1/src/ui/widgets/textos/textos.dart';
import 'package:provider/provider.dart';
import 'package:vinculed_app_1/src/core/providers/user_provider.dart';
import 'package:vinculed_app_1/src/ui/widgets/text_inputs/dropdown.dart';
import 'package:vinculed_app_1/src/ui/widgets/text_inputs/roles_multi_dropdown.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class Busqueda extends StatefulWidget {
  @override
  _BusquedaState createState() => _BusquedaState();
}

class _BusquedaState extends State<Busqueda> {
  // Controladores filtros
  final TextEditingController _queryCtrl = TextEditingController();
  final TextEditingController _entidadCtrl = TextEditingController();
  final TextEditingController _ciudadCtrl = TextEditingController();

  final usuario = FirebaseAuth.instance.currentUser!;

  // Estado de filtros avanzados
  String _ordenarPor = 'fecha_publicacion_desc';
  String? _selectedModalidad; // Presencial | Remoto | Híbrido
  List<int> _selectedRolIds = [];

  // Estado de resultados
  bool _loading = false;
  String? _error;
  List<dynamic> _vacantes = [];
  int _page = 1;
  final int _limit = 10;
  int? _total;
  bool _hasNext = false;

  // Historial
  List<_HistoryItem> _history = [];
  bool _historyLoading = false;

  // Flags
  bool _initialRequested = false;
  Map<String, String> _currentFilters = {};

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;
    final userProv = context.watch<UserDataProvider>();

    // Disparar fetch inicial cuando idRol esté disponible
    if (!_initialRequested && userProv.idRol != null) {
      _initialRequested = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _fetchVacantes(onlyRequired: true, resetPage: true);
        _fetchHistory();
      });
    }

    return Scaffold(
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
      backgroundColor: theme.background(),
      body: SafeArea(
        child: WillPopScope(
          onWillPop: () async {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => MenuPage()),
            );
            return false;
          },
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Título con botón regreso
                const SizedBox(height: 4),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back_rounded, color: theme.primario()),
                      tooltip: 'Regresar',
                      onPressed: () {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => MenuPage()),
                          (route) => false,
                        );
                      },
                    ),
                    const SizedBox(width: 4),
                    const Texto(text: 'Buscar Vacantes', fontSize: 24),
                  ],
                ),
                const SizedBox(height: 16),

                // Card de filtros (versión móvil compacta)
                Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextInput(
                          controller: _queryCtrl,
                          title: 'Palabra clave',
                          icon: const Icon(Icons.search, size: 20),
                        ),
                        const SizedBox(height: 12),
                        RolesMultiDropdown(
                          label: 'Rol de trabajo',
                          onChanged: (selected) {
                            setState(() => _selectedRolIds = selected.map((r) => r.id).toList());
                          },
                        ),
                        const SizedBox(height: 12),
                        TextInput(
                          controller: _entidadCtrl,
                          title: 'Entidad',
                          icon: const Icon(Icons.public, size: 20),
                        ),
                        const SizedBox(height: 12),
                        TextInput(
                          controller: _ciudadCtrl,
                          title: 'Ciudad',
                          icon: const Icon(Icons.location_city, size: 20),
                        ),
                        const SizedBox(height: 12),
                        DropdownInput<String>(
                          title: 'Modalidad',
                          value: _selectedModalidad,
                          items: const [
                            DropdownMenuItem(value: 'Presencial', child: Text('Presencial')),
                            DropdownMenuItem(value: 'Remoto', child: Text('Remoto')),
                            DropdownMenuItem(value: 'Híbrido', child: Text('Híbrido')),
                          ],
                          onChanged: (v) => setState(() => _selectedModalidad = v),
                        ),
                        const SizedBox(height: 12),
                        DropdownInput<String>(
                          title: 'Ordenar por',
                          value: _ordenarPor,
                          items: const [
                            DropdownMenuItem(value: 'fecha_publicacion_desc', child: Text('Más recientes')),
                            DropdownMenuItem(value: 'fecha_publicacion_asc', child: Text('Más antiguas')),
                          ],
                          onChanged: (v) {
                            if (v != null) setState(() => _ordenarPor = v);
                          },
                        ),
                        const SizedBox(height: 16),
                        SimpleButton(
                          title: 'Buscar',
                          primaryColor: true,
                          onTap: _onSearch,
                        ),
                      ],
                    ),
                  ),
                ),

                // Historial
                if (_history.isNotEmpty) ...[
                  Row(
                    children: [
                      const Text('Historial', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                      const Spacer(),
                      TextButton(onPressed: _clearHistory, child: const Text('Limpiar')),
                    ],
                  ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _history
                        .where((h) => h.consulta.trim().isNotEmpty)
                        .map((h) => InputChip(
                              label: Text(h.consulta),
                              onPressed: () {
                                _queryCtrl.text = h.consulta;
                                _onSearch(fromChip: true);
                              },
                              onDeleted: () => _removeHistoryItem(h),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 12),
                ] else if (_historyLoading) ...[
                  const Center(
                      child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: CircularProgressIndicator(),
                  )),
                  const SizedBox(height: 12),
                ],

                // Contador
                Text(
                  'Resultados: ' + (_total != null ? _total.toString() : _vacantes.length.toString()),
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),

                // Lista resultados / estados
                if (_loading) ...[
                  const Center(
                      child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: CircularProgressIndicator(),
                  )),
                ] else if (_error != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF1F2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFCA5A5)),
                    ),
                    child: Text(_error!, style: const TextStyle(color: Colors.red)),
                  ),
                  const SizedBox(height: 12),
                ] else if (_vacantes.isEmpty) ...[
                  const Center(
                      child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Text('Sin resultados'),
                  )),
                ] else ...[
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _vacantes.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final raw = _vacantes[index];
                      late final Map<String, dynamic> v;
                      if (raw is Map<String, dynamic>) v = raw; else if (raw is Map) v = Map<String, dynamic>.from(raw); else v = {};
                      final title = (v['titulo'] ?? v['title'] ?? 'Vacante').toString();
                      final empresa = (v['nombre_empresa'] ?? v['empresa'] ?? '').toString();
                      final modalidad = (v['modalidad'] ?? '').toString();
                      final numVac = v['numero_vacantes'];
                      final numVacStr = numVac is int ? (numVac == 1 ? '1 vacante' : '$numVac vacantes') : (numVac?.toString() ?? '');
                      final fPub = _fmtDate(v['fecha_publicacion']?.toString());
                      final fLimStr = v['fecha_limite'] != null ? _fmtDate(v['fecha_limite'].toString()) : '';
                      int? idVac; final anyId = v['id_vacante'] ?? v['id']; if (anyId is int) idVac = anyId; else if (anyId != null) idVac = int.tryParse(anyId.toString());
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
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
                        onTap: idVac == null ? null : () {
                          // TODO: navegar a detalle móvil
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  // Paginación
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SimpleButton(
                        title: 'Anterior',
                        onTap: _page > 1 && !_loading ? () { setState(() => _page -= 1); _fetchVacantes(); } : null,
                      ),
                      const SizedBox(width: 12),
                      Text(_total != null ? 'Página $_page de ' + (((_total! + _limit - 1) ~/ _limit)).toString() : 'Página $_page'),
                      const SizedBox(width: 12),
                      SimpleButton(
                        title: 'Siguiente',
                        onTap: !_loading && (_hasNext || (_total != null && _page < ((_total! + _limit - 1) ~/ _limit)))
                            ? () { setState(() => _page += 1); _fetchVacantes(); }
                            : null,
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ================== Lógica de búsqueda ==================
  void _onSearch({bool fromChip = false}) {
    final q = _queryCtrl.text.trim();
    final entidad = _entidadCtrl.text.trim();
    final ciudad = _ciudadCtrl.text.trim();

    if (q.isNotEmpty && !fromChip) {
      // No agregamos al backend (se maneja allá). Historial local si deseas:
      // _addToHistoryLocal(q);
    }
    final filters = <String, String>{};
    if (q.isNotEmpty) filters['query'] = q;
    if (entidad.isNotEmpty) filters['entidad'] = entidad;
    if (ciudad.isNotEmpty) filters['ciudad'] = ciudad;
    if (_selectedModalidad != null && _selectedModalidad!.isNotEmpty) filters['modalidad'] = _selectedModalidad!;
    if (_selectedRolIds.isNotEmpty) filters['rol_trabajo'] = _selectedRolIds.join(',');

    _page = 1;
    _currentFilters = filters;
    _fetchVacantes(resetPage: true);
  }

  Future<void> _fetchVacantes({bool onlyRequired = false, bool resetPage = false}) async {
    final userProv = context.read<UserDataProvider>();
    final idRol = userProv.idRol;
    if (idRol == null) {
      setState(() { _error = 'Cargando datos de usuario...'; });
      return;
    }
    if (resetPage) _page = 1;
    setState(() { _loading = true; _error = null; });
    try {
      final headers = await userProv.getAuthHeaders();
      final params = <String, String>{
        'ordenar_por': _ordenarPor,
        'id_alumno': idRol.toString(),
        'page': _page.toString(),
        'limit': _limit.toString(),
      };
      if (!onlyRequired) params.addAll(_currentFilters);
      final uri = Uri.parse('https://oda-talent-back-81413836179.us-central1.run.app/api/vacantes/buscar').replace(queryParameters: params);
      final res = await http.get(uri, headers: headers);
      if (res.statusCode < 200 || res.statusCode >= 300) throw Exception('Error ${res.statusCode}');
      final body = jsonDecode(res.body);
      if (body is! Map) throw Exception('Formato inesperado');
      final map = Map<String, dynamic>.from(body);
      final items = (map['vacantes'] as List?) ?? const [];
      final pag = map['paginacion'] as Map?; final pagMap = pag != null ? Map<String, dynamic>.from(pag) : null;
      final total = pagMap?['total_vacantes'] as int?;
      final totalPaginas = pagMap?['total_paginas'] as int?;
      final paginaActual = pagMap?['pagina_actual'] as int?;
      setState(() {
        _vacantes = items;
        _total = total;
        if (paginaActual != null) _page = paginaActual;
        _hasNext = (totalPaginas != null && paginaActual != null) ? paginaActual < totalPaginas : items.length == _limit;
      });
    } catch (e) {
      setState(() { _error = 'No se pudieron cargar las vacantes. $e'; });
    } finally {
      if (mounted) setState(() { _loading = false; });
    }
  }

  Future<void> _fetchHistory() async {
    setState(() => _historyLoading = true);
    try {
      final userProv = context.read<UserDataProvider>();
      final idRol = userProv.idRol; if (idRol == null) return;
      final headers = await userProv.getAuthHeaders();
      final uri = Uri.parse('https://oda-talent-back-81413836179.us-central1.run.app/api/alumnos/historial_busquedas').replace(queryParameters: {'id_alumno': idRol.toString(), 'limit': '10'});
      final res = await http.get(uri, headers: headers);
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final data = jsonDecode(res.body);
        if (data is List) {
          final list = data.whereType<Map>().map((m) => Map<String, dynamic>.from(m)).map((m) => _HistoryItem(
            id: (m['id_busqueda'] ?? 0) is int ? (m['id_busqueda'] as int) : int.tryParse('${m['id_busqueda']}') ?? 0,
            consulta: (m['consulta'] ?? '').toString(),
          )).toList();
          setState(() => _history = list);
        }
      }
    } catch (_) {} finally { if (mounted) setState(() => _historyLoading = false); }
  }

  void _clearHistory() async {
    try {
      final userProv = context.read<UserDataProvider>();
      final idRol = userProv.idRol; if (idRol == null) return;
      final headers = await userProv.getAuthHeaders();
      final uri = Uri.parse('https://oda-talent-back-81413836179.us-central1.run.app/api/alumnos/limpiar_historial');
      final res = await http.delete(uri, headers: headers, body: jsonEncode({'id_alumno': idRol}));
      if (res.statusCode >= 200 && res.statusCode < 300) setState(() => _history.clear());
    } catch (_) {}
  }

  Future<void> _removeHistoryItem(_HistoryItem item) async {
    try {
      final userProv = context.read<UserDataProvider>();
      final idRol = userProv.idRol; if (idRol == null) return;
      final headers = await userProv.getAuthHeaders();
      final uri = Uri.parse('https://oda-talent-back-81413836179.us-central1.run.app/api/alumnos/borrar_busqueda');
      final res = await http.delete(uri, headers: headers, body: jsonEncode({'id_alumno': idRol, 'id_busqueda': item.id}));
      if (res.statusCode >= 200 && res.statusCode < 300) setState(() => _history.removeWhere((h) => h.id == item.id));
    } catch (_) {}
  }

  // Helpers
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

  @override
  void dispose() {
    _queryCtrl.dispose();
    _entidadCtrl.dispose();
    _ciudadCtrl.dispose();
    super.dispose();
  }
}

class _HistoryItem {
  final int id;
  final String consulta;
  const _HistoryItem({required this.id, required this.consulta});
}
