import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:vinculed_app_1/src/core/controllers/theme_controller.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:vinculed_app_1/src/core/providers/user_provider.dart';
import 'package:vinculed_app_1/src/ui/pages/candidato/busqueda.dart';
import 'package:vinculed_app_1/src/ui/pages/candidato/perfil.dart';
import 'package:vinculed_app_1/src/ui/widgets/buttons/simple_buttons.dart';
import 'package:url_launcher/url_launcher.dart';

class JobDetailPage extends StatefulWidget {
  final int idVacante;
  const JobDetailPage({super.key, required this.idVacante});

  @override
  State<JobDetailPage> createState() => _JobDetailPageState();
}

class _JobDetailPageState extends State<JobDetailPage> {
  final usuario = FirebaseAuth.instance.currentUser!;
  Map<String, dynamic>? _detalle;
  bool _loading = true;
  bool _processing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchDetalle());
  }

  Future<void> _fetchDetalle() async {
    setState(() { _loading = true; _error = null; });
    try {
      final userProv = context.read<UserDataProvider>();
      final headers = await userProv.getAuthHeaders();
      final uri = Uri.parse('https://oda-talent-back-81413836179.us-central1.run.app/api/vacantes/detalles')
          .replace(queryParameters: {
        'id_vacante': widget.idVacante.toString(),
        'id_alumno': userProv.idRol.toString(),
      });
      final res = await http.get(uri, headers: headers);
      if (res.statusCode < 200 || res.statusCode >= 300) throw Exception('Error ${res.statusCode}');
      final data = jsonDecode(res.body);
      Map<String, dynamic>? vac;
      if (data is Map<String, dynamic>) {
        vac = data['vacante'] is Map ? Map<String, dynamic>.from(data['vacante']) : Map<String, dynamic>.from(data);
        vac['postulado'] = data.containsKey('postulado') ? data['postulado'] : false;
      }
      setState(() => _detalle = vac);
    } catch (e) {
      setState(() => _error = 'No se pudo cargar la vacante.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _togglePostulacion() async {
    if (_detalle == null) return;
    setState(() => _processing = true);
    try {
      final userProv = context.read<UserDataProvider>();
      final headers = await userProv.getAuthHeaders();
      final idAlumno = userProv.idRol;
      final estaPostulado = _detalle!['postulado'] == true;
      final body = jsonEncode({ 'id_alumno': idAlumno, 'id_vacante': widget.idVacante });
      http.Response res;
      if (estaPostulado) {
        res = await http.delete(
          Uri.parse('https://oda-talent-back-81413836179.us-central1.run.app/api/alumnos/cancelar_postulacion'),
          headers: headers,
          body: body,
        );
      } else {
        res = await http.post(
          Uri.parse('https://oda-talent-back-81413836179.us-central1.run.app/api/alumnos/postularse'),
          headers: headers,
          body: body,
        );
      }
      if (res.statusCode >= 200 && res.statusCode < 300) {
        setState(() { _detalle!['postulado'] = !estaPostulado; });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(estaPostulado ? 'Postulación cancelada' : 'Postulación enviada'),
          backgroundColor: estaPostulado ? Colors.black87 : Colors.green,
        ));
      } else {
        throw Exception('Error ${res.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error: $e'),
        backgroundColor: Colors.red,
      ));
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  String _fmtDate(String? iso) {
    if (iso == null || iso.isEmpty) return 'No especificada';
    try {
      final dt = DateTime.parse(iso).toLocal();
      final months = ['Ene','Feb','Mar','Abr','May','Jun','Jul','Ago','Sep','Oct','Nov','Dic'];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
    } catch (_) { return iso; }
  }

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;
    return Scaffold(
      backgroundColor: theme.background(),
      appBar: AppBar( // keep existing style
        backgroundColor: theme.background(),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            //Image.asset('assets/images/escom.png', width: 50, height: 50),
            Row(children: [
              IconButton(icon: Icon(Icons.search, color: theme.primario()), onPressed: () {Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => Busqueda()),
                    );}),
              IconButton(icon: Icon(Icons.notifications_none, color: theme.primario()), onPressed: () {}),
              IconButton(
                  icon: CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.blue[50],
                    backgroundImage: usuario.photoURL != null ? NetworkImage(usuario.photoURL!) : null,
                    child: usuario.photoURL == null ? const Icon(Icons.person, size: 18) : null,
                  ),
                  onPressed: () {
                    // Acción para perfil
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const Perfil()),
                    );
                  },
                ),
            ])
          ],
        ),
        elevation: 0,
      ),
      body: SafeArea(
        child: _buildContent(theme),
      ),
    );
  }

  Widget _buildContent(ThemeController theme) {
    if (_loading) {
      return const Center(child: Padding(
        padding: EdgeInsets.all(40),
        child: CircularProgressIndicator(),
      ));
    }
    if (_error != null) {
      return Center(
        child: Container(
          padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(12)),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 16)),
              const SizedBox(height: 16),
              SimpleButton(title: 'Reintentar', primaryColor: true, onTap: _fetchDetalle),
            ]),
        ),
      );
    }
    final d = _detalle!;
    final estaPostulado = d['postulado'] == true;
    final estatusPostulacion = d['estatus_postulacion']?.toString() ?? '';
    final esRechazado = estatusPostulacion == 'Rechazado';
    final estaReclutado = estatusPostulacion == 'Reclutado';
    final estaCompletado = estatusPostulacion == 'Completado';
    final vencida = d['estado'] != 'Activa';
    final perfilIncompleto = d['perfil_completo'] == 0;

    String botonTitulo;
    bool primary = false; Color? fondo; Color? texto;
    VoidCallback? accion;
    if (_processing) {
      botonTitulo = 'Procesando...'; fondo = Colors.blueGrey; texto = Colors.white; accion = null;
    } else if (perfilIncompleto) {
      botonTitulo = 'Completa tu perfil para postularte'; fondo = Color.fromARGB(255, 238, 238, 238); texto = Colors.black;
    } else if (esRechazado) {
      botonTitulo = 'No ha sido aceptado en esta vacante'; fondo = Color.fromARGB(255, 238, 238, 238); texto = Colors.black;
    } else if (estaReclutado) {
      botonTitulo = 'Ya has sido reclutado'; fondo = Colors.blue;
    } else if (estaCompletado) {
      botonTitulo = 'Actividades completadas'; fondo = Colors.green;
    } else if (vencida) {
      botonTitulo = 'Vacante no disponible'; fondo = Colors.blueGrey; texto = Colors.white;
    } else if (estaPostulado) {
      botonTitulo = 'Cancelar Postulación'; fondo = Colors.redAccent; accion = _togglePostulacion;
    } else {
      botonTitulo = 'Postularme a esta Vacante'; primary = true; accion = _togglePostulacion;
    }

    final titulo = d['titulo'] ?? 'Sin título';
    final descripcion = d['descripcion'] ?? '';
    final beneficios = d['beneficios'];
    final empresaData = d['empresa'] ?? {}; final nombreEmpresa = empresaData['nombre_empresa'] ?? 'Empresa Confidencial';
    final logoUrl = empresaData['logo_empresa']; final webEmpresa = empresaData['sitio_web'];
    final monto = d['monto_beca']; final montoStr = monto != null ? '\$${monto.toString()}' : 'No especificado';
    final ubicacion = [d['ubicacion'], d['ciudad'], d['entidad'], d['codigo_postal']?.toString()].where((e) => e != null && e.toString().isNotEmpty).join(', ');
    final habilidades = d['habilidades'] as List? ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Encabezado
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.grey.withOpacity(.15), blurRadius: 15, offset: const Offset(0,5))],
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                  image: logoUrl != null && logoUrl.toString().isNotEmpty
                      ? DecorationImage(image: NetworkImage(logoUrl), fit: BoxFit.cover)
                      : null,
                ),
                child: logoUrl == null || logoUrl.toString().isEmpty ? Icon(Icons.business, size: 40, color: Colors.grey[400]) : null,
              ),
              const SizedBox(width: 20),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(titulo, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Color(0xFF1F2A36))),
                const SizedBox(height: 6),
                InkWell(
                  onTap: webEmpresa != null ? () => _launchURL(webEmpresa) : null,
                  child: Text(
                    nombreEmpresa,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: webEmpresa != null ? Colors.blue[700] : Colors.grey[700], decoration: webEmpresa != null ? TextDecoration.underline : null),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  _Badge(d['modalidad'] ?? 'No esp.', Icons.work_outline, Colors.blue),
                  _Badge('${d['duracion'] ?? 'No esp.'} ${d['duracion'].contains('meses') ? '' : 'meses'}', Icons.timer_outlined, Colors.blue),
                  if (d['numero_vacantes'] != null) _Badge('${d['numero_vacantes']} vacantes', Icons.people_outline, Colors.blue),
                  _Badge(d['estado'] ?? 'Activa', Icons.check_circle_outline, Colors.blue),
                  if (estaReclutado) _Badge('Reclutado', Icons.verified, Colors.blueAccent)
                  else if (esRechazado) _Badge('Postulación Rechazada', Icons.cancel, Colors.red)
                  else if (estaCompletado) _Badge('Completado', Icons.star_rounded, Colors.green)
                  else if (vencida) _Badge('Vacante Cerrada', Icons.lock, Colors.grey)
                  else if (estaPostulado) _Badge('Postulado', Icons.check_circle, Colors.blue),
                ])
              ]))
            ]),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            Wrap(spacing: 40, runSpacing: 20, children: [
              _DetailItem('Beca Mensual', montoStr, Icons.monetization_on_outlined),
              _DetailItem('Fecha Límite', _fmtDate(d['fecha_limite']), Icons.calendar_today),
              _DetailItem('Publicada', _fmtDate(d['fecha_publicacion']), Icons.access_time),
              _DetailItem('Horario', d['horario'] ?? 'No especificado', Icons.schedule),
            ]),
          ]),
        ),
        const SizedBox(height: 32),
        _SectionCard(title: 'Descripción del Puesto', children: [Text(descripcion, style: const TextStyle(fontSize: 16, height: 1.6, color: Colors.black87))]),
        if (d['observaciones'] != null) _SectionCard(title: 'Observaciones', children: [Text(d['observaciones'], style: const TextStyle(fontSize: 16, height: 1.6))]),
        if (beneficios != null) _SectionCard(title: 'Beneficios', children: [
          if (beneficios is String) Text(beneficios, style: const TextStyle(fontSize: 16, height: 1.6))
          else if (beneficios is List) ...beneficios.map((b) => _BulletItem(b.toString())),
        ]),
        _SectionCard(title: 'Requisitos y Detalles', children: [
          _InfoRow('Escolaridad', d['escolaridad'] ?? 'No especificada'),
          const SizedBox(height: 16),
          _InfoRow('Conocimientos', d['conocimientos'] ?? 'No especificados'),
          const SizedBox(height: 16),
          _InfoRow('Periodo', '${_fmtDate(d['fecha_inicio'])} - ${_fmtDate(d['fecha_fin'])}'),
        ]),
        if (habilidades.isNotEmpty) _SectionCard(title: 'Habilidades Requeridas', children: [
          Builder(builder: (context) {
            final Map<String, List<String>> skillsByType = {};
            for (var item in habilidades) {
              if (item is Map) {
                final tipoRaw = item['tipo']?.toString() ?? 'Generales';
                final nombre = item['habilidad']?.toString() ?? '';
                final tipo = tipoRaw.isNotEmpty ? '${tipoRaw[0].toUpperCase()}${tipoRaw.substring(1)}' : 'Generales';
                if (nombre.isNotEmpty) { skillsByType.putIfAbsent(tipo, () => []); skillsByType[tipo]!.add(nombre); }
              } else {
                skillsByType.putIfAbsent('Generales', () => []); skillsByType['Generales']!.add(item.toString());
              }
            }
            return Column(crossAxisAlignment: CrossAxisAlignment.start, children: skillsByType.entries.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(e.key, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey[700], letterSpacing: .5)),
                const SizedBox(height: 8),
                Wrap(spacing: 8, runSpacing: 8, children: e.value.map((nombreSkill) => Chip(
                  label: Text(nombreSkill, style: const TextStyle(fontSize: 13)),
                  backgroundColor: Colors.blue.shade50,
                  labelStyle: TextStyle(color: Colors.blue.shade800, fontWeight: FontWeight.w500),
                  side: BorderSide.none,
                  padding: const EdgeInsets.all(4),
                )).toList()),
              ]),
            )).toList());
          })
        ]),
        _SectionCard(title: 'Ubicación', children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Icon(Icons.location_on_outlined, color: Colors.redAccent),
            const SizedBox(width: 12),
            Expanded(child: Text(ubicacion.isNotEmpty ? ubicacion : 'Remoto / No especificada', style: const TextStyle(fontSize: 16, height: 1.4, fontWeight: FontWeight.w500)))
          ])
        ]),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: (() {
            final Widget btn = SimpleButton(
              title: botonTitulo,
              onTap: accion,
              primaryColor: primary,
              backgroundColor: fondo,
              textColor: texto,
            );

            if (accion == null) {
              // Deshabilitar completamente: sin ripple, sin hover, cursor no permitido y estilo atenuado
              return MouseRegion(
                cursor: SystemMouseCursors.forbidden,
                child: AbsorbPointer(
                  absorbing: true,
                  child: Theme(
                    data: Theme.of(context).copyWith(
                      splashFactory: NoSplash.splashFactory,
                      hoverColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                    ),
                    child: Opacity(
                      opacity: 0.6,
                      child: btn,
                    ),
                  ),
                ),
              );
            }

            return btn;
          })(),
        ),
        const SizedBox(height: 20),
      ]),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title; final List<Widget> children; const _SectionCard({required this.title, required this.children});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: Color(0xFF1F2A36))),
        const SizedBox(height: 16),
        ...children,
      ]),
    );
  }
}

class _DetailItem extends StatelessWidget {
  final String label, value; final IconData icon; const _DetailItem(this.label, this.value, this.icon);
  @override
  Widget build(BuildContext context) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: Colors.blue[700], size: 22)),
      const SizedBox(width: 12),
      Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[600], fontWeight: FontWeight.w500)),
              Text(
                value,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                softWrap: true,
              ),
            ],
          ),)
    ]);
  }
}

class _Badge extends StatelessWidget {
  final String text; final IconData icon; final Color color; const _Badge(this.text, this.icon, this.color);
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: color.withOpacity(.08), borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withOpacity(.3))),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 16, color: color), const SizedBox(width: 6), Text(text, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color)),
      ]),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label, value; const _InfoRow(this.label, this.value);
  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black54)),
      const SizedBox(height: 6),
      Text(value, style: const TextStyle(fontSize: 16, color: Colors.black87, height: 1.4)),
    ]);
  }
}

class _BulletItem extends StatelessWidget {
  final String text; const _BulletItem(this.text);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Padding(padding: EdgeInsets.only(top: 7), child: Icon(Icons.circle, size: 6, color: Colors.blue)),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 16, height: 1.5))),
      ]),
    );
  }
}
