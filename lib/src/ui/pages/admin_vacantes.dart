import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:vinculed_app_1/src/core/controllers/theme_controller.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:vinculed_app_1/src/core/providers/user_provider.dart';
import 'package:vinculed_app_1/src/ui/pages/admin_ajustes.dart';
import 'package:vinculed_app_1/src/ui/pages/admin_detalle_vacante.dart';
import 'package:vinculed_app_1/src/ui/web_app/admin_detalle_vacante.dart';

import 'package:vinculed_app_1/src/ui/widgets/elements/header4.dart';
import 'package:vinculed_app_1/src/ui/widgets/text_inputs/text_input.dart';
import 'package:vinculed_app_1/src/ui/widgets/buttons/simple_buttons.dart';
import 'package:vinculed_app_1/src/ui/widgets/text_inputs/dropdown.dart';
import 'package:vinculed_app_1/src/ui/widgets/text_inputs/roles_multi_dropdown.dart';

class AdminJobSearchMovilPage extends StatefulWidget {
  const AdminJobSearchMovilPage({super.key});

  @override
  State<AdminJobSearchMovilPage> createState() => _AdminJobSearchMovilPageState();
}

class _AdminJobSearchMovilPageState extends State<AdminJobSearchMovilPage> {
  final _queryCtrl = TextEditingController();
  final _locationCtrl = TextEditingController(); // entidad
  final _cityCtrl = TextEditingController(); // ciudad

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

  // Scroll (sin footer)
  final _scrollCtrl = ScrollController();
  static const double _extraBottomPadding = 24.0;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
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

    if (!_initialRequested) {
      _initialRequested = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _fetchVacantes(onlyRequired: true, resetPage: true);
      });
    }

    return Scaffold(
      backgroundColor: theme.background(),
      appBar: AppBar(
        backgroundColor: theme.background(),
        //automaticallyImplyLeading: false,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Image.asset('assets/images/graduate.png', width: 50, height: 50),
            Row(
              children: [
                const SizedBox(width: 10),
                IconButton(
                  icon: Icon(
                    Icons.settings_outlined,
                    color: theme.fuente(),
                    size: 26,
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AjustesAdmin()),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
        elevation: 0,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final minBodyHeight = constraints.maxHeight - _extraBottomPadding;

          return SingleChildScrollView(
            controller: _scrollCtrl,
            padding: const EdgeInsets.only(bottom: _extraBottomPadding),
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
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

                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 900),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              LayoutBuilder(
                                builder: (ctx, constraints) {
                                  final width = constraints.maxWidth;

                                  final isDesktop = width > 1100;
                                  final isTablet = width > 650 && width <= 1100;

                                  const double spacing = 12.0;
                                  const double runSpacing = 16.0;

                                  int cols = isDesktop ? 4 : (isTablet ? 2 : 1);
                                  double itemWidth = (width - (spacing * (cols - 1)) - 32) / cols;

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
                                        crossAxisAlignment: WrapCrossAlignment.end,
                                        children: [
                                          SizedBox(
                                            width: isDesktop ? (itemWidth * 2) + spacing : itemWidth,
                                            child: TextInput(
                                              title: 'Buscar por palabra clave',
                                              controller: _queryCtrl,
                                              keyboardType: TextInputType.text,
                                              icon: const Icon(Icons.search, size: 20),
                                            ),
                                          ),
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
                                          SizedBox(
                                            width: itemWidth,
                                            child: TextInput(
                                              title: 'Entidad / Estado',
                                              controller: _locationCtrl,
                                              keyboardType: TextInputType.text,
                                              icon: const Icon(Icons.public, size: 20),
                                            ),
                                          ),
                                          SizedBox(
                                            width: itemWidth,
                                            child: TextInput(
                                              title: 'Ciudad',
                                              controller: _cityCtrl,
                                              keyboardType: TextInputType.text,
                                              icon: const Icon(Icons.location_city, size: 20),
                                            ),
                                          ),
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
                                                DropdownMenuItem(value: '', child: Text('Sin especificar')),
                                              ],
                                            ),
                                          ),
                                          SizedBox(
                                            width: itemWidth,
                                            child: DropdownInput<String>(
                                              title: 'Ordenar por',
                                              required: true,
                                              value: _ordenarPor,
                                              icon: const Icon(Icons.sort, size: 20),
                                              onChanged: (v) => setState(() {
                                                if (v != null) _ordenarPor = v;
                                              }),
                                              items: const [
                                                DropdownMenuItem(value: 'fecha_publicacion_desc', child: Text('Más recientes')),
                                                DropdownMenuItem(value: 'fecha_publicacion_asc', child: Text('Más antiguas')),
                                                DropdownMenuItem(value: 'monto_beca_desc', child: Text('Mayor Beca')),
                                                DropdownMenuItem(value: 'monto_beca_asc', child: Text('Menor Beca')),
                                              ],
                                            ),
                                          ),
                                          SizedBox(
                                            width: isDesktop ? itemWidth : double.infinity,
                                            height: 56,
                                            child: Padding(
                                              padding: const EdgeInsets.only(top: 4.0),
                                              child: SimpleButton(
                                                title: 'Buscar Vacantes',
                                                icon: Icons.search,
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
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Resultados: ' + (_total != null ? _total.toString() : _vacantes.length.toString()),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF22313F),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

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
                                final estado = v['estado']?.toString() ?? '';

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
                                        if (fPub.isNotEmpty) _info(Icons.calendar_today_outlined, 'Publicada: $fPub'),
                                        if (fLimStr.isNotEmpty) _info(Icons.event_busy_outlined, 'Límite: $fLimStr'),
                                        if (estado.isNotEmpty) _info(Icons.info_outline, 'Estado: $estado'),
                                      ],
                                    ),
                                  ),
                                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                                  onTap: (idVac == null)
                                      ? null
                                      : () {
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (_) => AdminJobDetailMovilPage(idVacante: idVac!),
                                            ),
                                          );
                                        },
                                );
                              },
                            ),

                          const SizedBox(height: 12),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SimpleButton(
                                title: 'Ant.',
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
                                    ? 'Página $_page de ${((_total! + _limit - 1) ~/ _limit)}'
                                    : 'Página $_page',
                              ),
                              const SizedBox(width: 12),
                              SimpleButton(
                                title: 'Sig.',
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
          );
        },
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
    final idRol = 1; // requerido como id_alumno (no requerido para el admin)

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
