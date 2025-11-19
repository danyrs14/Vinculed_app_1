import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:vinculed_app_1/src/core/controllers/theme_controller.dart';
import 'package:vinculed_app_1/src/ui/widgets/elements/footer.dart';
import 'package:vinculed_app_1/src/ui/widgets/elements/header2.dart';
import 'package:vinculed_app_1/src/ui/widgets/elements/postulacion_card.dart';
import 'package:provider/provider.dart';
import 'package:vinculed_app_1/src/core/providers/user_provider.dart';

class MyApplicationsPage extends StatefulWidget {
  const MyApplicationsPage({super.key});

  @override
  State<MyApplicationsPage> createState() => _MyApplicationsPageState();
}

class _MyApplicationsPageState extends State<MyApplicationsPage> {
  final _scrollCtrl = ScrollController();
  bool _showFooter = false;

  static const double _footerReservedSpace = EscomFooter.height;
  static const double _extraBottomPadding = 24.0;
  static const double _atEndThreshold = 4.0;

  String _currentTab = 'Activas'; // 'Activas' | 'Expiradas'
  bool _loading = false;
  String? _error;
  List<Map<String, dynamic>> _postulaciones = [];

  
  static const _baseUrl = 'https://oda-talent-back-81413836179.us-central1.run.app/api/alumnos/postulaciones';

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_handleScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleScroll();
      _loadPostulaciones();
    });
  }

  @override
  void dispose() {
    _scrollCtrl.removeListener(_handleScroll);
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _handleScroll() {
    final pos = _scrollCtrl.position;
    if (!pos.hasPixels || !pos.hasContentDimensions) return;

    if (pos.maxScrollExtent <= 0) {
      if (_showFooter) setState(() => _showFooter = false);
      return;
    }

    final atBottom = pos.pixels >= (pos.maxScrollExtent - _atEndThreshold);
    if (atBottom != _showFooter) setState(() => _showFooter = atBottom);
  }

  String _estadoParam() {
    switch (_currentTab) {
      case 'Activas':
        return 'Activa';
      case 'Expiradas':
        return 'Expirada';
      default:
        return 'Activa';
    }
  }

  Future<void> _loadPostulaciones() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final userProv = context.read<UserDataProvider>();
    final headers = await userProv.getAuthHeaders();
    final estado = _estadoParam();
    final uri = Uri.parse('$_baseUrl?id_alumno=${userProv.idRol}&estado=$estado');
    // NOTE: estado esperado: Activa | Expirada
    try {
      final resp = await http.get(uri, headers: headers);
      if (!mounted) return;
      if(resp.statusCode == 404){
        setState(() {
          _postulaciones = [];
          _loading = false;
        });
        return ;
      }
      if (resp.statusCode != 200) {
        setState(() {
          _error = 'Error ${resp.statusCode} al obtener datos';
          _loading = false;
        });
        return;
      }
      final data = json.decode(resp.body);
      if (data is List) {
        setState(() {
          _postulaciones = data.cast<Map<String, dynamic>>();
          _loading = false;
        });
      } else {
        setState(() {
          _error = 'Formato inesperado';
          _loading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Excepción: $e';
        _loading = false;
      });
    }
  }

  void _changeTab(String tab) {
    if (_currentTab == tab) {
      // recargar al hacer clic en la activa
      _loadPostulaciones();
      return;
    }
    setState(() {
      _currentTab = tab;
    });
    _loadPostulaciones();
  }

  IconData _iconForStatus(String estatus) {
    switch (estatus) {
      case 'En revisión':
        return Icons.search_rounded;
      case 'Reclutado':
        return Icons.verified_rounded;
      case 'Rechazado':
        return Icons.cancel_rounded;
      case 'Completado':
        return Icons.check_circle_rounded;
      default:
        return Icons.help_outline;
    }
  }

  Widget _buildCards(double maxWidth, bool isMobile, double screenWidth) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 60),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Text(
            _error!,
            style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600),
          ),
        ),
      );
    }
    if (_postulaciones.isEmpty) {
      final theme = ThemeController.instance;
      final accent = theme.secundario();
      final isActivas = _currentTab == 'Activas';
      final titulo = isActivas ? 'Aún no has aplicado a vacantes activas' : 'No tienes vacantes expiradas';
      final detalle = isActivas
          ? 'Explora puestos y encuentra una vacante que se adapte a tu perfil.'
          : 'Las vacantes que expiran aparecerán aquí para tu historial.';
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 12),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: accent.withOpacity(.25), width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(.06),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: accent.withOpacity(.10),
                      border: Border.all(color: accent.withOpacity(.30), width: 1.2),
                    ),
                    child: Icon(
                      isActivas ? Icons.work_outline : Icons.history_rounded,
                      size: 42,
                      color: accent,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    titulo,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: theme.fuente(),
                      letterSpacing: .3,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    detalle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      color: theme.fuente().withOpacity(.85),
                    ),
                  ),
                  const SizedBox(height: 22),
                  if (isActivas)
                    ElevatedButton.icon(
                      onPressed: () => context.go('/alumno/busqueda_job'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accent,
                        foregroundColor: theme.primario(),
                        padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      icon: const Icon(Icons.search_rounded),
                      label: const Text('Buscar vacantes'),
                    ),
                  if (!isActivas)
                    Text(
                      'Tip: Cuando una vacante cierre, podrás revisarla aquí.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: theme.fuente().withOpacity(.6),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final cols = isMobile ? 1 : (screenWidth < 1000 ? 2 : 3);
    final horizontalPadding = 24 * 2; // scaffold padding lateral (aprox)
    final usableWidth = (maxWidth < screenWidth ? maxWidth : screenWidth) - horizontalPadding;
    final gap = 24.0;
    final cardWidth = (usableWidth - (cols - 1) * gap) / cols;

    return Wrap(
      spacing: gap,
      runSpacing: gap,
      children: _postulaciones.map((p) {
        final titulo = p['titulo']?.toString() ?? 'Vacante';
        final empresa = p['nombre_empresa']?.toString() ?? 'Empresa';
        final ciudad = p['ciudad']?.toString() ?? '';
        final entidad = p['entidad']?.toString() ?? '';
        final estatus = p['estatus']?.toString() ?? 'Desconocido';
        final idVacante = p['id_vacante']?.toString();
        final loc = [ciudad, entidad].where((e) => e.isNotEmpty).join(', ');
        return SizedBox(
          width: cardWidth > 380 ? 380 : cardWidth, // limitar ancho máximo por estética
          child: ApplicationCard(
            title: titulo,
            company: empresa,
            location: loc.isEmpty ? 'Sin ubicación' : loc,
            statusLabel: estatus,
            statusIcon: _iconForStatus(estatus),
            onTap: idVacante == null
                ? null
                : () => context.go('/alumno/vacante_job/$idVacante'),
          ),
        );
      }).toList(),
    );
  }

  Widget _tabButton(String label, bool isMobile) {
    final selected = _currentTab == label;
    final theme = ThemeController.instance;
    final accent = theme.secundario();
    final baseBg = Colors.blueGrey.shade200;
    return ElevatedButton(
      onPressed: () => _changeTab(label),
      style: ElevatedButton.styleFrom(
        elevation: selected ? 2 : 0,
        backgroundColor: selected ? accent : baseBg,
        foregroundColor: theme.primario() ,
        padding: EdgeInsets.symmetric(horizontal: isMobile ? 18 : 28, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          //side: BorderSide(color: accent, width: 1.2),
        ),
        textStyle: TextStyle(
          fontSize: isMobile ? 14 : 16,
          fontWeight: FontWeight.w700,
          letterSpacing: .4,
        ),
      ),
      child: Text(label),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;

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

            case "Explorar Puestos en TI":
              context.go('/alumno/preferences');
              break;

          }
        },
      ),

      body: Stack(
        children: [
          // Scroll global con padding inferior para el footer
          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final minBodyHeight = constraints.maxHeight - _footerReservedSpace - _extraBottomPadding;
                final w = MediaQuery.of(context).size.width;
                final isMobile = w < 700; // se usa para botones/cards
                return NotificationListener<ScrollNotification>(
                  onNotification: (n) {
                    if (n is ScrollUpdateNotification || n is UserScrollNotification || n is ScrollEndNotification) {
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
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: minBodyHeight > 0 ? minBodyHeight : 0,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // Título fuera del Row
                                Text(
                                  'Mis Postulaciones',
                                  style: TextStyle(
                                    fontSize: isMobile ? 26 : 32,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF22313F),
                                  ),
                                ),
                                const SizedBox(height: 18),
                                // Botones de pestañas
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    _tabButton('Activas', isMobile),
                                    const SizedBox(width: 16),
                                    _tabButton('Expiradas', isMobile),
                                  ],
                                ),
                                const SizedBox(height: 26),
                                // Contenido dinámico
                                _buildCards(1100, isMobile, w),
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

          // Footer animado (aparece al final del scroll)
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
                child: EscomFooter(isMobile: MediaQuery.of(context).size.width < 700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
