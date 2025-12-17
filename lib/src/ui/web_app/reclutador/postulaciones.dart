import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:vinculed_app_1/src/core/providers/user_provider.dart';

import 'package:vinculed_app_1/src/core/controllers/theme_controller.dart';
import 'package:vinculed_app_1/src/ui/widgets/buttons/simple_buttons.dart';
import 'package:vinculed_app_1/src/ui/widgets/elements/footer.dart';
import 'package:vinculed_app_1/src/ui/widgets/elements/header3.dart';

class VacancyDetailPage extends StatefulWidget {
  const VacancyDetailPage({super.key});

  @override
  State<VacancyDetailPage> createState() => _VacancyDetailPageState();
}

class _VacancyDetailPageState extends State<VacancyDetailPage> {
  final _scrollCtrl = ScrollController();
  bool _showFooter = false;

  static const double _footerReservedSpace = EscomFooter.height;
  static const double _extraBottomPadding = 24.0;
  static const double _atEndThreshold = 4.0;

  // Estado de datos cargados desde el backend
  List<PublishedVacancy> _vacancies = [];
  int? _selectedIndex; // null => listado, idx => detalle
  bool _loading = true;
  String? _error;
  bool _isEmptyState = false; //flag para 404

  // Estado para detalle completo
  Map<String, dynamic>? _detalleVacante;
  List<Map<String, dynamic>> _postulaciones = [];
  bool _loadingDetalle = false;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _onScroll();
      _fetchVacantes();
    });
  }

  Future<void> _fetchVacantes() async {
    setState(() {
      _loading = true;
      _error = null;
      _isEmptyState = false;
    });
    try {
      final userProv = Provider.of<UserDataProvider>(context, listen: false);
      final headers = await userProv.getAuthHeaders();
      final idRol = userProv.idRol;
      final uri = Uri.parse('https://oda-talent-back-81413836179.us-central1.run.app/api/reclutadores/vacantes_publicadas')
          .replace(queryParameters: {'id_reclutador': '$idRol'});

      final resp = await http.get(uri, headers: headers);
      if (resp.statusCode == 404) {
        setState(() {
          _loading = false;
          _isEmptyState = true; // Activar el mensaje bonito
          _vacancies = [];
        });
        return; // Salir correctamente
      }
      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        final data = jsonDecode(resp.body);
        if (data is List) {
          _vacancies = data.map<PublishedVacancy>((e) => PublishedVacancy.fromJson(e as Map<String, dynamic>)).toList();
        } else {
          _vacancies = [];
        }
        setState(() => _loading = false);
      } else {
        setState(() {
          _loading = false;
          _error = 'Error ${resp.statusCode}: ${resp.body}';
        });
      }
    } catch (e) {
      setState(() {
        _loading = false;
        _error = 'Error al cargar: $e';
      });
    }
  }

  // Abrir detalle y cargar información completa
  Future<void> _openDetail(int index) async {
    setState(() {
      _selectedIndex = index;
      _loadingDetalle = true;
      _detalleVacante = null;
      _postulaciones = [];
    });
    _scrollCtrl.animateTo(0, duration: const Duration(milliseconds: 280), curve: Curves.easeOut);
    final id = _vacancies[index].idVacante;
    await _fetchVacanteDetalle(id);
  }

  Future<void> _fetchVacanteDetalle(int idVacante) async {
    try {
      final userProv = Provider.of<UserDataProvider>(context, listen: false);
      final headers = await userProv.getAuthHeaders();
      final uri = Uri.parse('https://oda-talent-back-81413836179.us-central1.run.app/api/reclutadores/postulaciones')
          .replace(queryParameters: {'id_vacante': '$idVacante'});

      final resp = await http.get(uri, headers: headers);
      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        final data = jsonDecode(resp.body);
        Map<String, dynamic>? vac;
        List<Map<String, dynamic>> posts = [];
        if (data is Map<String, dynamic>) {
          if (data['vacante'] is Map) {
            vac = Map<String, dynamic>.from(data['vacante'] as Map);
          }
          if (data['postulaciones'] is List) {
            posts = (data['postulaciones'] as List)
                .whereType<Map>()
                .map((e) => Map<String, dynamic>.from(e))
                .toList();
          }
        }
        setState(() {
          _detalleVacante = vac;
          _postulaciones = posts;
          _loadingDetalle = false;
        });
      } else {
        setState(() => _loadingDetalle = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error ${resp.statusCode}: ${resp.body}')),
        );
      }
    } catch (e) {
      setState(() => _loadingDetalle = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar detalle: $e')),
      );
    }
  }

  Future<void> _borrarVacante() async {
    final det = _detalleVacante;
    if (det == null) return;
    final idRaw = det['id_vacante'] ?? det['idVacante'] ?? det['id'];
    if (idRaw == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ID de vacante no disponible')),
      );
      return;
    }
    // 1. Confirmación de seguridad
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar vacante?'),
        content: const Text('Esta acción es irreversible. ¿Estás seguro de que deseas eliminar esta vacante?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    // 2. Iniciar proceso
    setState(() => _isDeleting = true);

    try {
      final userProv = context.read<UserDataProvider>();
      final headers = await userProv.getAuthHeaders();
      
      // Nota: http.delete soporta body, aunque algunos servidores son estrictos.
      // Asumimos que tu backend Node.js lo acepta correctamente.
      final uri = Uri.parse('https://oda-talent-back-81413836179.us-central1.run.app/api/reclutadores/borrar_vacante');
      final idVac = (idRaw is int) ? idRaw : int.tryParse('$idRaw') ?? idRaw;
      
      final response = await http.delete(
        uri,
        headers: headers,
        body: jsonEncode({
          "id_vacante": idVac // Asegúrate de tener esta variable disponible
        }),
      );

      if (response.statusCode == 204) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Vacante eliminada correctamente')),
          );
          // Regresar a la lista de vacantes
          context.pop(); 
          // O si prefieres ir a una ruta especifica: context.go('/my_vacancy');
        }
      } else {
        throw Exception('Error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo eliminar: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isDeleting = false);
      }
    }
  }

  Future<void> _toggleEstadoVacante() async {
    // Cambia el estado entre Activa <-> Expirada y actualiza el badge y el texto del botón
    final det = _detalleVacante;
    if (det == null) return;
    final idRaw = det['id_vacante'] ?? det['idVacante'] ?? det['id'];
    if (idRaw == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ID de vacante no disponible')),
      );
      return;
    }
    final current = (det['estado']?.toString() ?? 'Activa').toLowerCase();
    final target = current == 'expirada' ? 'Activa' : 'Expirada';

    try {
      final userProv = Provider.of<UserDataProvider>(context, listen: false);
      final headers = await userProv.getAuthHeaders();
      final uri = Uri.parse('https://oda-talent-back-81413836179.us-central1.run.app/api/reclutadores/cambiar_estado_vacante');
      final idVac = (idRaw is int) ? idRaw : int.tryParse('$idRaw') ?? idRaw;

      final resp = await http.put(
        uri,
        headers: headers,
        body: jsonEncode({
          'id_vacante': idVac,
          'estado': target,
        }),
      );

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        setState(() {
          // Actualiza el estado en el detalle
          _detalleVacante!['estado'] = target;
          // Y también en el listado para que el badge de la tarjeta refleje el cambio
          if (_selectedIndex != null &&
              _selectedIndex! >= 0 &&
              _selectedIndex! < _vacancies.length) {
            final v = _vacancies[_selectedIndex!];
            _vacancies[_selectedIndex!] = PublishedVacancy(
              idVacante: v.idVacante,
              idReclutador: v.idReclutador,
              titulo: v.titulo,
              montoBecaText: v.montoBecaText,
              fechaPublicacion: v.fechaPublicacion,
              fechaLimite: v.fechaLimite,
              numeroVacantes: v.numeroVacantes,
              ciudad: v.ciudad,
              entidad: v.entidad,
              modalidad: v.modalidad,
              estado: target,
              postulaciones: v.postulaciones,
            );
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Estado actualizado a $target')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error ${resp.statusCode}: ${resp.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cambiar estado: $e')),
      );
    }
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

  Widget _buildEmptyStateView() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 30),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icono grande y bonito (Simulación de inventario vacío)
            Icon(
              Icons.inventory_2_outlined,
              size: 80,
              color: Colors.blueGrey.shade300,
            ),
            const SizedBox(height: 20),
            const Text(
              '¡Aún no tienes vacantes publicadas!',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2A36),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              'Tu inventario de vacantes está vacío. Es hora de crear tu primera oferta para atraer talento de la ESCOM.',
              style: TextStyle(fontSize: 16, color: Colors.black54),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            // Botón de acción (Crear vacante)
            SizedBox(
              child: SimpleButton(
                title: 'Crear Nueva Vacante',
                // Asumo que esta es la ruta de creación
                onTap: () => context.go('/reclutador/new_vacancy'), 
                primaryColor: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _scrollCtrl
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;
    final w = MediaQuery.of(context).size.width;
    final isMobile = w < 880;

    return Scaffold(
      backgroundColor: theme.background(),
      appBar: EscomHeader3(
        onLoginTap: () => context.go('/reclutador/perfil_rec'),
        onNotifTap: () {},
        onMenuSelected: (label) {
          switch (label) {
            case "Inicio":
              context.go('/inicio');
              break;
            case "Crear Vacante":
              context.go('/reclutador/new_vacante');
              break;
            case "Mis Vacantes":
              context.go('/reclutador/postulaciones');
              break;
            case "FAQ":
              context.go('/reclutador/faq_rec');
              break;
            case "Mensajes":
              context.go('/reclutador/msg_rec');
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
                        constraints: const BoxConstraints(maxWidth: 1100),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: minBodyHeight > 0 ? minBodyHeight : 0,
                            ),
                            child: _loading
                                ? const Center(child: CircularProgressIndicator())
                                : (_error != null)
                                    ? Center(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.error_outline, color: Colors.redAccent),
                                            const SizedBox(height: 8),
                                            Text(_error!, textAlign: TextAlign.center),
                                            const SizedBox(height: 12),
                                            SizedBox(
                                              child: SimpleButton(title: 'Reintentar', onTap: _fetchVacantes),
                                            ),
                                          ],
                                        ),
                                      )
                                    : (_isEmptyState)
                                        ? _buildEmptyStateView()
                                    : (_selectedIndex == null)
                                        ? _VacancyListView(
                                            vacancies: _vacancies,
                                            onOpen: _openDetail,
                                          )
                                        : (_loadingDetalle || _detalleVacante == null)
                                            ? const Center(
                                                child: Padding(
                                                  padding: EdgeInsets.only(top: 40),
                                                  child: CircularProgressIndicator(),
                                                ),
                                              )
                                            : _VacancyDetailRichView(
                                                detail: _detalleVacante!,
                                                postulaciones: _postulaciones,
                                                isMobile: isMobile,
                                                onBackToList: () => setState(() => _selectedIndex = null),
                                                onToggleEstado: _toggleEstadoVacante,
                                                onDeleting: _borrarVacante,
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

/* ───────────────────────── Vista: Listado de Vacantes ───────────────────────── */

class _VacancyListView extends StatelessWidget {
  const _VacancyListView({
    required this.vacancies,
    required this.onOpen,
  });

  final List<PublishedVacancy> vacancies;
  final void Function(int index) onOpen;

  String _fmtDate(DateTime d) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(d.day)}/${two(d.month)}/${d.year}';
    }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 880;
    final theme = ThemeController.instance;

    if (vacancies.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _HeaderAvatar(),
          const SizedBox(height: 12),
          Text(
            'Vacantes',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: theme.fuente()),
          ),
          const SizedBox(height: 16),
          const Text('No hay vacantes publicadas todavía.'),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Encabezado
        Row(
          children: [
            const _HeaderAvatar(),
            const SizedBox(width: 12),
            Text(
              'Vacantes',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: theme.fuente(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Grid o lista de tarjetas
        LayoutBuilder(
          builder: (_, c) {
            // Hacer tarjetas más angostas y un poco más altas para evitar overflow en móvil
            final maxExtent = isMobile ? 600.0 : 500.0; // ancho máximo de cada tarjeta
            final aspect = 1.25; // más alto en móvil, moderado en desktop
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: vacancies.length,
              gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: maxExtent,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: aspect,
                mainAxisExtent: 320,
              ),
              itemBuilder: (_, i) {
                final v = vacancies[i];
                final modalidadColor = theme.secundario();
                final estadoLower = v.estado.toLowerCase();
                final estadoColor = estadoLower == 'activa' ? theme.primario() : Colors.blueGrey;
                final postulacionesColor = theme.secundario();
                return _CardBox(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Título
                      Text(
                        v.titulo,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: theme.fuente(),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Badges
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          _Badge(text: v.modalidad, color: modalidadColor),
                          _Badge(text: v.estado, color: estadoColor),
                          _Badge(text: 'Postulaciones: ${v.postulaciones}', color: postulacionesColor),
                        ],
                      ),

                      const SizedBox(height: 10),
                      // Datos con íconos
                      _InfoRow(icon: Icons.attach_money, text: v.montoBecaText.isEmpty ? 'Sin beca' : ' ${v.montoBecaText}'),
                      const SizedBox(height: 6),
                      _InfoRow(icon: Icons.event_available, text: 'Publicada: ${_fmtDate(v.fechaPublicacion)}'),
                      const SizedBox(height: 6),
                      _InfoRow(
                        icon: Icons.event_busy,
                        text: v.fechaLimite != null ? 'Fecha límite: ${_fmtDate(v.fechaLimite!)}' : 'Sin fecha límite',
                      ),
                      const SizedBox(height: 6),
                      _InfoRow(icon: Icons.group, text: 'Vacantes: ${v.numeroVacantes}'),
                      const SizedBox(height: 6),
                      _InfoRow(icon: Icons.place, text: '${v.ciudad}, ${v.entidad}'),

                      const Spacer(),
                      Align(
                        alignment: Alignment.centerRight,
                        child: SizedBox(
                          child: SimpleButton(
                            title: 'Ver detalle',
                            onTap: () => onOpen(i),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}

/* ───────────────────────── Vista: Detalle de Vacante ───────────────────────── */

class _VacancyDetailView extends StatelessWidget {
  const _VacancyDetailView({
    required this.vacancy,
    required this.isMobile,
    required this.onBackToList,
  });

  final PublishedVacancy vacancy;
  final bool isMobile;
  final VoidCallback onBackToList;

  String _fmtDate(DateTime d) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(d.day)}/${two(d.month)}/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;
    final estadoColor = vacancy.estado.toLowerCase() == 'activa' ? theme.primario() : Colors.blueGrey;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isMobile)
          Row(
            children: [
              Expanded(child: SimpleButton(title: 'Regresar', onTap: onBackToList)),
            ],
          )
        else
          Row(
            children: [
              SizedBox(width: 220, child: SimpleButton(title: 'Regresar', onTap: onBackToList)),
            ],
          ),

        const SizedBox(height: 20),

        Text(
          vacancy.titulo,
          style: TextStyle(
            fontSize: isMobile ? 26 : 34,
            fontWeight: FontWeight.w900,
            color: theme.fuente(),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            _Badge(text: vacancy.modalidad, color: theme.secundario()),
            _Badge(text: vacancy.estado, color: estadoColor),
            _Badge(text: 'Postulaciones: ${vacancy.postulaciones}', color: theme.secundario()),
          ],
        ),

        const SizedBox(height: 16),
        _InfoRow(icon: Icons.attach_money, text: vacancy.montoBecaText.isEmpty ? 'Sin beca' : '\$ ${vacancy.montoBecaText}'),
        const SizedBox(height: 6),
        _InfoRow(icon: Icons.event_available, text: 'Publicada: ${_fmtDate(vacancy.fechaPublicacion)}'),
        const SizedBox(height: 6),
        _InfoRow(icon: Icons.event_busy, text: vacancy.fechaLimite != null ? 'Fecha límite: ${_fmtDate(vacancy.fechaLimite!)}' : 'Sin fecha límite'),
        const SizedBox(height: 6),
        _InfoRow(icon: Icons.group, text: 'Vacantes: ${vacancy.numeroVacantes}'),
        const SizedBox(height: 6),
        _InfoRow(icon: Icons.place, text: '${vacancy.ciudad}, ${vacancy.entidad}'),
      ],
    );
  }
}

/* ───────────────────────── Widgets auxiliares ───────────────────────── */

class _HeaderAvatar extends StatelessWidget {
  const _HeaderAvatar();

  @override
  Widget build(BuildContext context) {
    return const CircleAvatar(
      radius: 18,
      backgroundImage: AssetImage('assets/images/escom.png'),
      backgroundColor: Colors.transparent,
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text, required this.color});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(.35)),
      ),
      child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w700)),
    );
  }
}

class _CardBox extends StatelessWidget {
  const _CardBox({this.child});
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x11000000)),
        boxShadow: const [
          BoxShadow(
            blurRadius: 10,
            spreadRadius: 0,
            offset: Offset(0, 2),
            color: Color(0x0F000000),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, size: 18, color: theme.fuente()),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// Modelo de datos para vacantes publicadas
class PublishedVacancy {
  final int idVacante;
  final int idReclutador;
  final String titulo;
  final String montoBecaText; // mantener como string
  final DateTime fechaPublicacion;
  final DateTime? fechaLimite;
  final int numeroVacantes;
  final String ciudad;
  final String entidad;
  final String modalidad;
  final String estado;
  final int postulaciones;

  PublishedVacancy({
    required this.idVacante,
    required this.idReclutador,
    required this.titulo,
    required this.montoBecaText,
    required this.fechaPublicacion,
    required this.fechaLimite,
    required this.numeroVacantes,
    required this.ciudad,
    required this.entidad,
    required this.modalidad,
    required this.estado,
    required this.postulaciones,
  });

  factory PublishedVacancy.fromJson(Map<String, dynamic> j) {
    DateTime? tryParseDate(dynamic v) {
      if (v == null) return null;
      try { return DateTime.parse(v.toString()); } catch (_) { return null; }
    }

    return PublishedVacancy(
      idVacante: j['id_vacante'] is int ? j['id_vacante'] as int : int.tryParse('${j['id_vacante']}') ?? 0,
      idReclutador: j['id_reclutador'] is int ? j['id_reclutador'] as int : int.tryParse('${j['id_reclutador']}') ?? 0,
      titulo: (j['titulo'] ?? '').toString(),
      montoBecaText: (j['monto_beca'] ?? '').toString(),
      fechaPublicacion: tryParseDate(j['fecha_publicacion']) ?? DateTime.now(),
      fechaLimite: tryParseDate(j['fecha_limite']),
      numeroVacantes: j['numero_vacantes'] is int ? j['numero_vacantes'] as int : int.tryParse('${j['numero_vacantes']}') ?? 0,
      ciudad: (j['ciudad'] ?? '').toString(),
      entidad: (j['entidad'] ?? '').toString(),
      modalidad: (j['modalidad'] ?? '').toString(),
      estado: (j['estado'] ?? '').toString(),
      postulaciones: j['postulaciones'] is int ? j['postulaciones'] as int : int.tryParse('${j['postulaciones']}') ?? 0,
    );
  }
}

/* ───────────────────────── Vista: Detalle completo (similar a JobDetailPage) ───────────────────────── */
class _VacancyDetailRichView extends StatelessWidget {
  const _VacancyDetailRichView({
    required this.detail,
    required this.postulaciones,
    required this.isMobile,
    required this.onBackToList,
    required this.onToggleEstado,
    required this.onDeleting,
  });

  final Map<String, dynamic> detail;
  final List<Map<String, dynamic>> postulaciones;
  final bool isMobile;
  final VoidCallback onBackToList;
  final VoidCallback onToggleEstado;
  final VoidCallback onDeleting;

  String _fmtDate(String? iso) {
    if (iso == null || iso.isEmpty) return 'No especificada';
    try {
      final dt = DateTime.parse(iso).toLocal();
      const months = ['Ene','Feb','Mar','Abr','May','Jun','Jul','Ago','Sep','Oct','Nov','Dic'];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
    } catch (_) { return iso; }
  }
  

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;

    final titulo = detail['titulo']?.toString() ?? 'Sin título';
    final descripcion = detail['descripcion']?.toString() ?? '';
    final beneficios = detail['beneficios'];
    final empresa = (detail['empresa'] is Map) ? Map<String, dynamic>.from(detail['empresa']) : <String, dynamic>{};
    final nombreEmpresa = empresa['nombre_empresa']?.toString() ?? 'Empresa Confidencial';
    final logoUrl = empresa['logo_empresa']?.toString();

    final monto = detail['monto_beca'];
    final montoStr = (monto == null || '$monto'.isEmpty) ? 'No especificado' : '\$${monto.toString()}';
    final horario = detail['horario']?.toString() ?? 'No especificado';

    final ubicacion = [
      detail['ubicacion'],
      detail['ciudad'],
      detail['entidad'],
      detail['codigo_postal']?.toString(),
    ].where((e) => e != null && e.toString().isNotEmpty).join(', ');

    final habilidades = detail['habilidades'] as List? ?? [];
    final estadoActual = detail['estado']?.toString() ?? 'Activa';
    final esExpirada = estadoActual.toLowerCase() == 'expirada';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Barra superior de acciones
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            SizedBox(width: isMobile ? 170 : 200, child: SimpleButton(title: 'Regresar', onTap: onBackToList)),
            SizedBox(width: isMobile ? 170 : 200, child: SimpleButton(title: 'Editar Vacante', onTap: () {
              final idVacante = detail['id_vacante'] ?? detail['idVacante'] ?? detail['id'];
              if (idVacante != null) {
                GoRouter.of(context).go('/reclutador/editar_vacante/$idVacante');
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ID de vacante no disponible')));
              }
            })),
            SizedBox(width: isMobile ? 170 : 200, child: SimpleButton(title:  'Eliminar Vacante', backgroundColor: Colors.redAccent, onTap: onDeleting,)),
            // Botón toggle con mayor ancho para evitar overflow y texto dinámico
            SizedBox(
              width: isMobile ? 205 : 225,
              child: SimpleButton(
                title: esExpirada ? 'Marcar como Activa' : 'Marcar como Expirada',
                onTap: onToggleEstado,
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // Tarjeta de encabezado
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 4)),
            ],
            border: Border.all(color: Colors.black12.withOpacity(.06)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.black12.withOpacity(.08)),
                      image: (logoUrl != null && logoUrl.isNotEmpty)
                          ? DecorationImage(image: NetworkImage(logoUrl), fit: BoxFit.cover)
                          : null,
                    ),
                    child: (logoUrl == null || logoUrl.isEmpty)
                        ? Icon(Icons.business, size: 40, color: Colors.grey[400])
                        : null,
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          titulo,
                          style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: theme.fuente()),
                        ),
                        const SizedBox(height: 6),
                        Text(nombreEmpresa, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _PillBadge(detail['modalidad']?.toString() ?? 'No esp.', Icons.work_outline, theme.secundario()),
                            _PillBadge(detail['duracion']?.toString() ?? 'No esp.', Icons.timer_outlined, theme.secundario()),
                            if (detail['numero_vacantes'] != null)
                              _PillBadge('${detail['numero_vacantes']} vacantes', Icons.people_outline, theme.secundario()),
                            _PillBadge(estadoActual, Icons.check_circle_outline,
                                (estadoActual.toLowerCase() == 'activa') ? theme.primario() : Colors.blueGrey),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              Wrap(
                spacing: 40,
                runSpacing: 20,
                children: [
                  _DetailItem('Beca Mensual', montoStr, Icons.monetization_on_outlined),
                  _DetailItem('Fecha Límite', _fmtDate(detail['fecha_limite']?.toString()), Icons.calendar_today),
                  _DetailItem('Publicada', _fmtDate(detail['fecha_publicacion']?.toString()), Icons.access_time),
                  _DetailItem('Horario', horario, Icons.schedule),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 32),

        // Secciones
        _SectionCard(title: 'Descripción del Puesto', children: [
          Text(descripcion, style: const TextStyle(fontSize: 16, height: 1.6, color: Colors.black87)),
        ]),

        if (detail['observaciones'] != null)
          _SectionCard(title: 'Observaciones', children: [
            Text(detail['observaciones'].toString(), style: const TextStyle(fontSize: 16, height: 1.6)),
          ]),

        if (beneficios != null)
          _SectionCard(title: 'Beneficios', children: [
            if (beneficios is String)
              Text(beneficios, style: const TextStyle(fontSize: 16, height: 1.6))
            else if (beneficios is List)
              ...beneficios.map((b) => _BulletItem(b.toString())),
          ]),

        _SectionCard(title: 'Requisitos y Detalles', children: [
          _LabeledInfo('Escolaridad', detail['escolaridad']?.toString() ?? 'No especificada'),
          const SizedBox(height: 16),
          _LabeledInfo('Conocimientos', detail['conocimientos']?.toString() ?? 'No especificados'),
          const SizedBox(height: 16),
          _LabeledInfo('Periodo', '${_fmtDate(detail['fecha_inicio']?.toString())} - ${_fmtDate(detail['fecha_fin']?.toString())}'),
        ]),

        if (habilidades.isNotEmpty)
          _SectionCard(title: 'Habilidades Requeridas', children: [
            Builder(
              builder: (context) {
                final Map<String, List<String>> skillsByType = {};
                for (var item in habilidades) {
                  if (item is Map) {
                    final tipoRaw = item['tipo']?.toString() ?? 'Generales';
                    final nombre = item['habilidad']?.toString() ?? '';
                    final tipo = tipoRaw.isNotEmpty ? '${tipoRaw[0].toUpperCase()}${tipoRaw.substring(1)}' : 'Generales';
                    if (nombre.isNotEmpty) {
                      skillsByType.putIfAbsent(tipo, () => []).add(nombre);
                    }
                  } else {
                    skillsByType.putIfAbsent('Generales', () => []).add(item.toString());
                  }
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: skillsByType.entries.map((e) => Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(e.key, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey[700], letterSpacing: .5)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8, runSpacing: 8,
                          children: e.value.map((n) => Chip(
                            label: Text(n, style: const TextStyle(fontSize: 13)),
                            backgroundColor: Colors.blue.shade50,
                            labelStyle: TextStyle(color: Colors.blue.shade800, fontWeight: FontWeight.w500),
                            side: BorderSide.none,
                            padding: const EdgeInsets.all(4),
                          )).toList(),
                        ),
                      ],
                    ),
                  )).toList(),
                );
              },
            ),
          ]),

        _SectionCard(title: 'Ubicación', children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.location_on_outlined, color: Colors.redAccent),
              const SizedBox(width: 12),
              Expanded(child: Text(ubicacion.isNotEmpty ? ubicacion : 'Remoto / No especificada', style: const TextStyle(fontSize: 16, height: 1.4, fontWeight: FontWeight.w500))),
            ],
          ),
        ]),

        const SizedBox(height: 12),
        const Divider(),
        const SizedBox(height: 12),

        // Postulaciones
        Text('Postulaciones', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: theme.fuente())),
        const SizedBox(height: 12),
        if (postulaciones.isEmpty)
          const Text('Aún no hay postulaciones para esta vacante.')
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: postulaciones.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: isMobile ? 1 : 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: isMobile ? 3.2 : 3.6,
            ),
            itemBuilder: (_, i) {
              final p = postulaciones[i];
              return _PostulanteCard(
                idAlumno: (p['id_alumno'] is int) ? p['id_alumno'] as int : int.tryParse('${p['id_alumno']}') ?? 0,
                nombre: p['nombre']?.toString() ?? 'Sin nombre',
                correo: p['correo']?.toString() ?? '',
                fotoUrl: p['url_foto_perfil']?.toString(),
                estatus: p['estatus']?.toString() ?? '',
              );
            },
          ),
      ],
    );
  }
}

class _PostulanteCard extends StatelessWidget {
  const _PostulanteCard({required this.idAlumno, required this.nombre, required this.correo, this.fotoUrl, required this.estatus});
  final int idAlumno;
  final String nombre;
  final String correo;
  final String? fotoUrl;
  final String estatus;

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;
    return _CardBox(
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.blue[50],
            backgroundImage: (fotoUrl != null && fotoUrl!.isNotEmpty) ? NetworkImage(fotoUrl!) : null,
            child: (fotoUrl == null || fotoUrl!.isEmpty)
                ? Icon(Icons.person, size: 32, color: theme.fuente())
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(nombre, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(correo, maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _Badge(text: estatus, color: theme.secundario()),
          const SizedBox(width: 12),
          SizedBox(
            child: SimpleButton(
              title: 'Ver perfil',
              onTap: () => context.go('/reclutador/perfil_candidato/$idAlumno'),
            ),
          ),
        ],
      ),
    );
  }
}

class _PillBadge extends StatelessWidget {
  const _PillBadge(this.text, this.icon, this.color);
  final String text; final IconData icon; final Color color;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(text, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title; final List<Widget> children;
  const _SectionCard({required this.title, required this.children});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12.withOpacity(.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

class _DetailItem extends StatelessWidget {
  final String label, value; final IconData icon; const _DetailItem(this.label, this.value, this.icon);
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: Colors.blue[700], size: 22),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[600], fontWeight: FontWeight.w500)),
            Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          ],
        ),
      ],
    );
  }
}

class _LabeledInfo extends StatelessWidget {
  const _LabeledInfo(this.label, this.value);
  final String label; final String value;
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black54)),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(fontSize: 16, height: 1.4)),
      ],
    );
  }
}

class _BulletItem extends StatelessWidget {
  const _BulletItem(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(padding: EdgeInsets.only(top: 7), child: Icon(Icons.circle, size: 6, color: Colors.blue)),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 16, height: 1.5))),
        ],
      ),
    );
  }
}