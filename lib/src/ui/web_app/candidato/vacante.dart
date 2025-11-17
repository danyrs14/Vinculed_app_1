import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import 'package:vinculed_app_1/src/ui/widgets/elements/footer.dart';
import 'package:vinculed_app_1/src/ui/widgets/elements/header2.dart';
import 'package:vinculed_app_1/src/ui/widgets/text_inputs/text_input.dart';
import 'package:vinculed_app_1/src/ui/widgets/buttons/simple_buttons.dart';
import 'package:vinculed_app_1/src/core/providers/user_provider.dart';

class JobDetailPage extends StatefulWidget {
  final int idVacante;
  const JobDetailPage({super.key, required this.idVacante});

  @override
  State<JobDetailPage> createState() => _JobDetailPageState();
}

class _JobDetailPageState extends State<JobDetailPage> {
  // Inputs de la barra de búsqueda superior
  final _qCtrl = TextEditingController();
  final _modeCtrl = TextEditingController();

  final _scrollCtrl = ScrollController();
  bool _showFooter = false;

  // Datos de detalle
  Map<String, dynamic>? _detalle;
  bool _loading = true;
  String? _error;

  // ====== Mismo esquema que JobSearchPage ======
  static const double _footerReservedSpace = EscomFooter.height;
  static const double _extraBottomPadding = 24.0;
  static const double _atEndThreshold = 4.0;

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_handleScroll);
    // Asegura estado correcto tras el primer layout
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleScroll();
      _fetchDetalle();
    });
  }

  Future<void> _fetchDetalle() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final userProv = context.read<UserDataProvider>();
      final headers = await userProv.getAuthHeaders();
      final uri = Uri.parse('http://localhost:3000/api/vacantes/detalles')
          .replace(queryParameters: {'id_vacante': widget.idVacante.toString()});
      final res = await http.get(uri, headers: headers);
      if (res.statusCode < 200 || res.statusCode >= 300) {
        throw Exception('Error ${res.statusCode}');
      }
      final data = jsonDecode(res.body);
      Map<String, dynamic>? vac;
      if (data is Map<String, dynamic>) {
        if (data['vacante'] is Map) {
          vac = Map<String, dynamic>.from(data['vacante'] as Map);
        } else {
          vac = data;
        }
      } else if (data is Map) {
        vac = Map<String, dynamic>.from(data);
      }
      setState(() => _detalle = vac);
    } catch (e) {
      setState(() => _error = 'No se pudo cargar la vacante. $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _handleScroll() {
    final pos = _scrollCtrl.position;
    if (!pos.hasPixels || !pos.hasContentDimensions) return;

    // Si el contenido cabe en pantalla, ocultamos footer (como en JobSearchPage)
    if (pos.maxScrollExtent <= 0) {
      if (_showFooter) setState(() => _showFooter = false);
      return;
    }

    // Mostrar footer únicamente al final del contenido
    final atBottom = pos.pixels >= (pos.maxScrollExtent - _atEndThreshold);
    if (atBottom != _showFooter) {
      setState(() => _showFooter = atBottom);
    }
  }

  @override
  void dispose() {
    _scrollCtrl
      ..removeListener(_handleScroll)
      ..dispose();
    _qCtrl.dispose();
    _modeCtrl.dispose();
    super.dispose();
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
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 700;

    return Scaffold(
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
          // ====== Scroll a pantalla completa con reserva de espacio para footer ======
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
                        constraints: const BoxConstraints(maxWidth: 1100),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: minBodyHeight > 0 ? minBodyHeight : 0,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // ───────── Fila de búsqueda superior ─────────
                                LayoutBuilder(
                                  builder: (context, c) {
                                    final wrap = c.maxWidth < 920;
                                    if (wrap) {
                                      return Column(
                                        children: [
                                          TextInput(title: 'Puesto', controller: _qCtrl),
                                          const SizedBox(height: 12),
                                          TextInput(title: 'Ciudad', controller: _modeCtrl),
                                          const SizedBox(height: 12),
                                          Align(
                                            alignment: Alignment.centerRight,
                                            child: SizedBox(
                                              width: 220,
                                              child: SimpleButton(
                                                title: 'Buscar Empleo',
                                                onTap: _onSearch,
                                              ),
                                            ),
                                          ),
                                        ],
                                      );
                                    }
                                    return Row(
                                      children: [
                                        Expanded(
                                          flex: 4,
                                          child: Padding(
                                            padding: const EdgeInsets.only(right: 16),
                                            child: TextInput(title: 'Puesto', controller: _qCtrl),
                                          ),
                                        ),
                                        Expanded(
                                          flex: 3,
                                          child: Padding(
                                            padding: const EdgeInsets.only(right: 16),
                                            child: TextInput(
                                              title: 'Ciudad',
                                              controller: _modeCtrl,
                                            ),
                                          ),
                                        ),
                                        SizedBox(
                                          width: 240,
                                          child: SimpleButton(
                                            title: 'Buscar Empleo',
                                            onTap: _onSearch,
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),

                                const SizedBox(height: 28),

                                if (_loading) ...[
                                  const Center(child: CircularProgressIndicator()),
                                  const SizedBox(height: 40),
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
                                  const SizedBox(height: 24),
                                ] else ...[
                                  // ───────── Encabezado del puesto (dinámico) ─────────
                                  Builder(builder: (context) {
                                    final d = _detalle ?? const {};
                                    final titulo = (d['titulo'] ?? d['title'] ?? 'Vacante').toString();
                                    final empresa = (d['nombre_empresa'] ?? d['empresa'] ?? '').toString();
                                    final modalidad = (d['modalidad'] ?? '').toString();
                                    final numVac = d['numero_vacantes'];
                                    final numVacStr = numVac is int
                                        ? (numVac == 1 ? '1 vacante' : '$numVac vacantes')
                                        : (numVac?.toString() ?? '');
                                    final monto = d['monto_beca'] ?? d['salario'];
                                    String montoStr = '';
                                    if (monto != null) {
                                      if (monto is num) {
                                        montoStr = '\$${monto.toString()}';
                                      } else {
                                        montoStr = monto.toString();
                                      }
                                    }
                                    final fPub = _fmtDate(d['fecha_publicacion']?.toString());
                                    final fLim = _fmtDate(d['fecha_limite']?.toString());

                                    final direccion = (d['direccion'] ?? '').toString();
                                    final ciudad = (d['ciudad'] ?? '').toString();
                                    final entidad = (d['entidad'] ?? '').toString();

                                    return Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          titulo,
                                          style: const TextStyle(
                                            fontSize: 30,
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFF1F2A36),
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        if (montoStr.isNotEmpty)
                                          Text(
                                            montoStr,
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.black87,
                                            ),
                                          ),
                                        const SizedBox(height: 4),
                                        if (empresa.isNotEmpty)
                                          Text(
                                            empresa,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.black87,
                                            ),
                                          ),

                                        const SizedBox(height: 12),

                                        Wrap(
                                          spacing: 12,
                                          runSpacing: 6,
                                          children: [
                                            if (modalidad.isNotEmpty)
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Icon(Icons.work_outline, size: 16),
                                                  const SizedBox(width: 6),
                                                  Text(modalidad),
                                                ],
                                              ),
                                            if (numVacStr.isNotEmpty)
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Icon(Icons.people_alt_outlined, size: 16),
                                                  const SizedBox(width: 6),
                                                  Text(numVacStr),
                                                ],
                                              ),
                                            if (fPub.isNotEmpty)
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Icon(Icons.calendar_today_outlined, size: 16),
                                                  const SizedBox(width: 6),
                                                  Text('Publicada: ' + fPub),
                                                ],
                                              ),
                                            if (fLim.isNotEmpty)
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Icon(Icons.event_busy_outlined, size: 16),
                                                  const SizedBox(width: 6),
                                                  Text('Límite: ' + fLim),
                                                ],
                                              ),
                                          ],
                                        ),

                                        const SizedBox(height: 16),

                                        if (direccion.isNotEmpty) _AddressLine(direccion),
                                        if (ciudad.isNotEmpty || entidad.isNotEmpty)
                                          _AddressLine([
                                            if (ciudad.isNotEmpty) ciudad,
                                            if (entidad.isNotEmpty) entidad,
                                          ].join(', ')),

                                        const SizedBox(height: 18),

                                        SizedBox(
                                          width: 220,
                                          child: SimpleButton(
                                            title: 'Postularme',
                                            onTap: _onApply,
                                          ),
                                        ),

                                        const SizedBox(height: 24),

                                        // ───────── Sección REQUISITOS ─────────
                                        if ((d['requisitos'] is List && (d['requisitos'] as List).isNotEmpty)) ...[
                                          const _SectionTitle('REQUISITOS'),
                                          const SizedBox(height: 14),
                                          ...List<Widget>.from(
                                            (d['requisitos'] as List)
                                                .where((e) => e != null)
                                                .map((e) => _Bullet(e.toString())),
                                          ),
                                          const SizedBox(height: 28),
                                        ],

                                        // ───────── Sección DESCRIPCION ─────────
                                        if ((d['descripcion'] ?? d['descripcion_puesto']) != null) ...[
                                          const _SectionTitle('DESCRIPCION'),
                                          const SizedBox(height: 14),
                                          Text(
                                            (d['descripcion'] ?? d['descripcion_puesto']).toString(),
                                            textAlign: TextAlign.justify,
                                            style: const TextStyle(height: 1.5),
                                          ),
                                          const SizedBox(height: 28),
                                        ],

                                        // ───────── Sección HABILIDADES ─────────
                                        if (d['habilidades'] is List && (d['habilidades'] as List).isNotEmpty) ...[
                                          const _SectionTitle('HABILIDADES'),
                                          const SizedBox(height: 14),
                                          Wrap(
                                            spacing: 8,
                                            runSpacing: 8,
                                            children: List<Widget>.from(
                                              (d['habilidades'] as List).map((h) => Chip(label: Text(h.toString()))),
                                            ),
                                          ),
                                          const SizedBox(height: 28),
                                        ],

                                        // ───────── Sección BENEFICIOS ─────────
                                        if (d['beneficios'] is List && (d['beneficios'] as List).isNotEmpty) ...[
                                          const _SectionTitle('BENEFICIOS'),
                                          const SizedBox(height: 14),
                                          ...List<Widget>.from(
                                            (d['beneficios'] as List)
                                                .where((e) => e != null)
                                                .map((e) => _Bullet(e.toString())),
                                          ),
                                          const SizedBox(height: 28),
                                        ],

                                        // ───────── Sección ROLES RELACIONADOS ─────────
                                        if (d['roles_relacionados'] is List && (d['roles_relacionados'] as List).isNotEmpty) ...[
                                          const _SectionTitle('ROLES RELACIONADOS'),
                                          const SizedBox(height: 14),
                                          Wrap(
                                            spacing: 8,
                                            runSpacing: 8,
                                            children: List<Widget>.from(
                                              (d['roles_relacionados'] as List).map((r) {
                                                final txt = r is Map
                                                    ? (r['nombre'] ?? r['rol'] ?? r['name'] ?? '').toString()
                                                    : r.toString();
                                                return Chip(label: Text(txt));
                                              }),
                                            ),
                                          ),
                                          const SizedBox(height: 40),
                                        ],
                                      ],
                                    );
                                  }),
                                ],
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

          // ====== Footer animado como en JobSearchPage ======
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

  // Acciones
  void _onSearch() {
    // context.go('/busqueda_job'); // si ya tienes esa ruta
  }

  void _onApply() {
    // Lógica para postularse
  }
}

/* ───────────────────────── Widgets pequeños ───────────────────────── */

class _AddressLine extends StatelessWidget {
  const _AddressLine(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(color: Colors.black54),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18.0),
          child: Text(
            title,
            style: const TextStyle(
              letterSpacing: 1,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.circle, size: 6),
        const SizedBox(width: 8),
        Expanded(child: Text(text)),
      ],
    );
  }
}
