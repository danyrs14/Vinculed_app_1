import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:vinculed_app_1/src/core/controllers/theme_controller.dart';
import 'package:vinculed_app_1/src/core/providers/user_provider.dart';
import 'package:vinculed_app_1/src/ui/pages/candidato/vacante.dart';
import 'package:vinculed_app_1/src/ui/widgets/elements/postulacion_card.dart';

class Postulaciones extends StatefulWidget {
  const Postulaciones({super.key});
  @override
  State<Postulaciones> createState() => _PostulacionesState();
}

class _PostulacionesState extends State<Postulaciones> {
  String _currentTab = 'Activas'; // Activas | Expiradas
  bool _loading = false;
  String? _error;
  List<Map<String, dynamic>> _postulaciones = [];

  static const _baseUrl = 'https://oda-talent-back-81413836179.us-central1.run.app/api/alumnos/postulaciones';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadPostulaciones());
  }

  String _estadoParam() {
    switch (_currentTab) {
      case 'Activas': return 'Activa';
      case 'Expiradas': return 'Expirada';
      default: return 'Activa';
    }
  }

  Future<void> _loadPostulaciones() async {
    setState(() { _loading = true; _error = null; });
    try {
      final userProv = context.read<UserDataProvider>();
      final headers = await userProv.getAuthHeaders();
      final estado = _estadoParam();
      final uri = Uri.parse('$_baseUrl?id_alumno=${userProv.idRol}&estado=$estado');
      final resp = await http.get(uri, headers: headers);
      if (!mounted) return;
      if (resp.statusCode == 404) {
        setState(() { _postulaciones = []; _loading = false; });
        return;
      }
      if (resp.statusCode != 200) {
        setState(() { _error = 'Error ${resp.statusCode} al obtener datos'; _loading = false; });
        return;
      }
      final data = json.decode(resp.body);
      if (data is List) {
        setState(() { _postulaciones = data.cast<Map<String,dynamic>>(); _loading = false; });
      } else {
        setState(() { _error = 'Formato inesperado'; _loading = false; });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = 'Excepción: $e'; _loading = false; });
    }
  }

  void _changeTab(String tab) {
    if (_currentTab == tab) {
      _loadPostulaciones();
      return;
    }
    setState(() { _currentTab = tab; });
    _loadPostulaciones();
  }

  IconData _iconForStatus(String estatus) {
    switch (estatus) {
      case 'En revisión': return Icons.search_rounded;
      case 'Reclutado': return Icons.verified_rounded;
      case 'Rechazado': return Icons.cancel_rounded;
      case 'Completado': return Icons.star_rounded;
      default: return Icons.help_outline;
    }
  }

  Widget _tabButton(String label) {
    final selected = _currentTab == label;
    final theme = ThemeController.instance;
    final accent = theme.secundario();
    final baseBg = Colors.blueGrey.shade200;
    return ElevatedButton(
      onPressed: () => _changeTab(label),
      style: ElevatedButton.styleFrom(
        elevation: selected ? 2 : 0,
        backgroundColor: selected ? accent : baseBg,
        foregroundColor: theme.primario(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: .4),
      ),
      child: Text(label),
    );
  }

  Widget _buildEmpty() {
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
                  child: Icon(isActivas ? Icons.work_outline : Icons.history_rounded, size: 42, color: accent),
                ),
                const SizedBox(height: 24),
                Text(
                  titulo,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: theme.fuente(), letterSpacing: .3),
                ),
                const SizedBox(height: 12),
                Text(
                  detalle,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, height: 1.4, color: theme.fuente().withOpacity(.85)),
                ),
                const SizedBox(height: 22),
                if (isActivas)
                  ElevatedButton.icon(
                    onPressed: () { /* Navegar a búsqueda móvil */ Navigator.pop(context); },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: theme.primario(),
                      padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                    icon: const Icon(Icons.search_rounded),
                    label: const Text('Buscar vacantes'),
                  )
                else
                  Text(
                    'Tip: Cuando una vacante cierre, podrás revisarla aquí.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: theme.fuente().withOpacity(.6)),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildList() {
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
          child: Text(_error!, style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600)),
        ),
      );
    }
    if (_postulaciones.isEmpty) return _buildEmpty();

    final accent = ThemeController.instance.secundario();

    Widget statusBadge(String estatus) {
      final icon = _iconForStatus(estatus);
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: accent.withOpacity(.12),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: accent.withOpacity(.35), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: accent),
            const SizedBox(width: 6),
            Text(
              estatus,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: accent,
                letterSpacing: .2,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: _postulaciones.map((p) {
        final titulo = p['titulo']?.toString() ?? 'Vacante';
        final empresa = p['nombre_empresa']?.toString() ?? 'Empresa';
        final ciudad = p['ciudad']?.toString() ?? '';
        final entidad = p['entidad']?.toString() ?? '';
        final estatus = p['estatus']?.toString() ?? 'Desconocido';
        final idVacante = p['id_vacante'];
        final loc = [ciudad, entidad].where((e) => e.isNotEmpty).join(', ');
        return Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ApplicationCard(
                title: titulo,
                company: empresa,
                location: loc.isEmpty ? 'Sin ubicación' : loc,
                statusLabel: estatus,
                statusIcon: _iconForStatus(estatus),
                onTap: idVacante == null
                    ? null
                    : () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => JobDetailPage(idVacante: idVacante)),
                            ),
              ),
              const SizedBox(height: 10),
              //statusBadge(estatus),
            ],
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;
    return Scaffold(
      backgroundColor: theme.background(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text('Mis Postulaciones', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Color(0xFF22313F))),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _tabButton('Activas'),
                  const SizedBox(width: 16),
                  _tabButton('Expiradas'),
                ],
              ),
              const SizedBox(height: 26),
              _buildList(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
