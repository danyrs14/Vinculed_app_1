import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:vinculed_app_1/src/ui/widgets/elements/footer.dart';
import 'package:vinculed_app_1/src/ui/widgets/elements/header2.dart';
import 'package:vinculed_app_1/src/ui/widgets/buttons/simple_buttons.dart';
import 'package:vinculed_app_1/src/core/providers/user_provider.dart';

class JobDetailPage extends StatefulWidget {
  final int idVacante;
  const JobDetailPage({super.key, required this.idVacante});

  @override
  State<JobDetailPage> createState() => _JobDetailPageState();
}

class _JobDetailPageState extends State<JobDetailPage> {
  final _scrollCtrl = ScrollController();
  bool _showFooter = false;
  Map<String, dynamic>? _detalle;
  
  // Estados de carga
  bool _loading = true; // Carga inicial de la página
  bool _processing = false; // Carga al dar clic en el botón (postular/cancelar)
  String? _error;

  static const double _footerReservedSpace = EscomFooter.height;
  static const double _extraBottomPadding = 24.0;
  static const double _atEndThreshold = 4.0;

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_handleScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleScroll();
      _fetchDetalle();
    });
  }

  // 1. LÓGICA PARA POSTULARSE O CANCELAR
  Future<void> _togglePostulacion() async {
    if (_detalle == null) return;

    setState(() => _processing = true);

    try {
      final userProv = context.read<UserDataProvider>();
      final headers = await userProv.getAuthHeaders();
      
      // El ID del alumno viene del provider (idRol según tu instrucción)
      final idAlumno = userProv.idRol; 
      final idVacante = widget.idVacante;

      // Verificar estado actual
      final bool estaPostulado = _detalle!['postulado'] == true;

      final body = jsonEncode({
        "id_alumno": idAlumno,
        "id_vacante": idVacante,
      });

      http.Response res;

      if (estaPostulado) {
        // --- CANCELAR POSTULACIÓN (DELETE) ---
        final uri = Uri.parse('https://oda-talent-back-81413836179.us-central1.run.app/api/alumnos/cancelar_postulacion');
        // Nota: http.delete soporta body, pero algunos proxies lo bloquean. 
        // Asumimos que tu backend lo soporta como solicitaste.
        res = await http.delete(uri, headers: headers, body: body);
      } else {
        // --- POSTULARSE (POST) ---
        final uri = Uri.parse('https://oda-talent-back-81413836179.us-central1.run.app/api/alumnos/postularse');
        res = await http.post(uri, headers: headers, body: body);
      }

      if (res.statusCode >= 200 && res.statusCode < 300) {
        // Éxito: Actualizamos el estado localmente para reflejar el cambio
        setState(() {
          _detalle!['postulado'] = !estaPostulado;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(estaPostulado 
                ? 'Postulación cancelada correctamente' 
                : '¡Te has postulado exitosamente!'),
              backgroundColor: estaPostulado ? Colors.black87 : Colors.green,
            ),
          );
        }
      } else {
        throw Exception('Error ${res.statusCode}: ${res.body}');
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al procesar solicitud: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  Future<void> _fetchDetalle() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final userProv = context.read<UserDataProvider>();
      final headers = await userProv.getAuthHeaders();
      final uri = Uri.parse('https://oda-talent-back-81413836179.us-central1.run.app/api/vacantes/detalles')
          .replace(queryParameters: {'id_vacante': widget.idVacante.toString(), 'id_alumno': userProv.idRol.toString()});
      
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
        
        // Aseguramos que la llave 'postulado' exista, si no viene, es false.
        if (data.containsKey('postulado')) {
          vac!['postulado'] = data['postulado'];
        } else {
          vac!['postulado'] = false;
        }
      }
      setState(() => _detalle = vac);
    } catch (e) {
      setState(() => _error = 'No se pudo cargar la vacante. Por favor intente más tarde.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ... (Resto de funciones: _handleScroll, dispose, _fmtDate, _launchURL igual que antes) ...
  void _handleScroll() {
    final pos = _scrollCtrl.position;
    if (!pos.hasPixels || !pos.hasContentDimensions) return;
    if (pos.maxScrollExtent <= 0) {
      if (_showFooter) setState(() => _showFooter = false);
      return;
    }
    final atBottom = pos.pixels >= (pos.maxScrollExtent - _atEndThreshold);
    if (atBottom != _showFooter) {
      setState(() => _showFooter = atBottom);
    }
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  String _fmtDate(String? iso) {
    if (iso == null || iso.isEmpty) return 'No especificada';
    try {
      final dt = DateTime.parse(iso).toLocal();
      final months = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return iso;
    }
  }

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 700;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: EscomHeader2(
        onLoginTap: () => context.go('/alumno/perfil_cand'),
        onNotifTap: () {},
        onMenuSelected: (label) {
          switch (label) {
            case "Inicio": context.go('/inicio'); break;
            case "Postulaciones": context.go('/alumno/mis_postulaciones'); break;
            case "Mensajes": context.go('/alumno/messages'); break;
            case "Experiencias": context.go('/alumno/experiencias'); break;
            case "FAQ": context.go('/alumno/faq'); break;
            case "Explorar Puestos en TI": context.go('/alumno/preferences'); break;
          }
        },
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: NotificationListener<ScrollNotification>(
              onNotification: (n) {
                if (n is ScrollUpdateNotification || n is ScrollEndNotification) {
                  _handleScroll();
                }
                return false;
              },
              child: SingleChildScrollView(
                controller: _scrollCtrl,
                padding: const EdgeInsets.only(bottom: _footerReservedSpace + _extraBottomPadding),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 900),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: _buildContent(),
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Footer
          Positioned(
            left: 0, right: 0, bottom: 0,
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

  Widget _buildContent() {
    if (_loading) {
      return const SizedBox(
        height: 400,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    
    if (_error != null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 10),
            Text(_error!, style: const TextStyle(fontSize: 16, color: Colors.red)),
            const SizedBox(height: 20),
            SimpleButton(title: "Reintentar", onTap: _fetchDetalle, primaryColor: true)
          ],
        ),
      );
    }

    final d = _detalle!;
    
    // --- DETERMINAR ESTADO DEL BOTÓN ---
    final bool estaPostulado = d['postulado'] == true;
    final String estatusPostulacion = d['estatus_postulacion']?.toString() ?? '';
    final bool esRechazado = estatusPostulacion == 'Rechazado';
    final bool estaReclutado = estatusPostulacion == 'Reclutado';
    final bool estaCompletado = estatusPostulacion == 'Completado';
    final bool vencida = d['estado'] != 'Activa';
    final bool perfilIncompleto = d['perfil_completo'] == 0;
    final Color? botonTextoColor;
    
    String botonTitulo;
    bool botonColorPrimario;
    Color? botonColorFondo;
    VoidCallback? botonAccion;

    if (_processing) {
      // CASO 1: Cargando
      botonTitulo = 'Procesando...';
      botonColorPrimario = false;
      botonColorFondo = Colors.blueGrey;
      botonAccion = null; // Deshabilita el clic
      botonTextoColor = Colors.white;
    } else if(perfilIncompleto){
      // CASO 7: Perfil incompleto (Bloqueado)
      botonTitulo = 'Completa tu perfil para postularte';
      botonColorPrimario = false;
      botonColorFondo = Color.fromARGB(255, 238, 238, 238);
      botonAccion = null; // Deshabilita el clic
      botonTextoColor = Colors.black;

    }else if (esRechazado) {
      // CASO 2: Rechazado (Bloqueado)
      botonTitulo = 'No ha sido aceptado en esta vacante'; // O "Postulación Rechazada"
      botonColorPrimario = false;
      botonColorFondo = Color.fromARGB(255, 238, 238, 238);
      botonAccion = null; // Deshabilita el clic
      botonTextoColor = Colors.black;
    }  else if(estaReclutado){
      // CASO 5: Reclutado (Bloqueado)
      botonTitulo = 'Ya has sido reclutado para esta vacante';
      botonColorPrimario = false;
      botonColorFondo = Colors.blue;
      botonAccion = null; // Deshabilita el clic
      botonTextoColor = null;
    }else if(estaCompletado){
      // CASO 5: Completado
      botonTitulo = 'Ya has completado las actividades de esta vacante';
      botonColorPrimario = false;
      botonColorFondo = Colors.green;
      botonAccion = null; // Deshabilita el clic
      botonTextoColor = null;
      }else if(vencida){
      // CASO 6: Vacante vencida (Bloqueado)
      botonTitulo = 'Vacante no disponible';
      botonColorPrimario = false;
      botonColorFondo = Colors.blueGrey;
      botonAccion = null; // Deshabilita el clic
      botonTextoColor = Colors.white;
      }else if (estaPostulado) {
        // CASO 3: Ya postulado (Permite cancelar)
        botonTitulo = 'Cancelar Postulación';
        botonColorPrimario = false;
        botonColorFondo = Colors.redAccent;
        botonAccion = _togglePostulacion;
        botonTextoColor = null;
      }else {
      // CASO 4: No postulado (Permite postularse)
      botonTitulo = 'Postularme a esta Vacante';
      botonColorPrimario = true; // Azul (o color principal)
      botonColorFondo = null;
      botonAccion = _togglePostulacion;
      botonTextoColor = null;
    }
    // -----------------------------------

    final titulo = d['titulo'] ?? 'Sin título';
    final descripcion = d['descripcion'] ?? '';
    final beneficios = d['beneficios'];
    final empresaData = d['empresa'] ?? {};
    final nombreEmpresa = empresaData['nombre_empresa'] ?? 'Empresa Confidencial';
    final logoUrl = empresaData['logo_empresa'];
    final webEmpresa = empresaData['sitio_web'];
    
    final monto = d['monto_beca'];
    final montoStr = monto != null ? '\$${monto.toString()}' : 'No especificado';
    
    final ubicacion = [
      d['ubicacion'], 
      d['ciudad'], 
      d['entidad'], 
      d['codigo_postal']?.toString()
    ].where((e) => e != null && e.toString().isNotEmpty).join(', ');

    final habilidades = d['habilidades'] as List? ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ---------------- TARJETA DE ENCABEZADO ----------------
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: Colors.grey.withOpacity(0.15), blurRadius: 15, offset: const Offset(0, 5)),
            ],
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Logo
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
                    child: logoUrl == null || logoUrl.toString().isEmpty 
                        ? Icon(Icons.business, size: 40, color: Colors.grey[400])
                        : null,
                  ),
                  const SizedBox(width: 20),
                  // Textos
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          titulo,
                          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Color(0xFF1F2A36)),
                        ),
                        const SizedBox(height: 6),
                        InkWell(
                          onTap: webEmpresa != null ? () => _launchURL(webEmpresa) : null,
                          child: Text(
                            nombreEmpresa,
                            style: TextStyle(
                              fontSize: 18, 
                              fontWeight: FontWeight.w600, 
                              color: webEmpresa != null ? Colors.blue[700] : Colors.grey[700],
                              decoration: webEmpresa != null ? TextDecoration.underline : null,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8, runSpacing: 8,
                          children: [
                            _Badge(d['modalidad'] ?? 'No esp.', Icons.work_outline, Colors.blue),
                            _Badge('${d['duracion'] ?? 'No esp.'} ${d['duracion'].contains('meses') ? '' : 'meses'}', Icons.timer_outlined, Colors.blue),
                            if (d['numero_vacantes'] != null)
                              _Badge('${d['numero_vacantes']} vacantes', Icons.people_outline, Colors.blue),
                            _Badge(d['estado'] ?? 'Activa', Icons.check_circle_outline, Colors.blue),
                            
                            // Badge de postulado
                            if(estaReclutado)
                              _Badge('Reclutado', Icons.verified, Colors.blueAccent)
                            else if (esRechazado)
                              _Badge('Postulación Rechazada', Icons.cancel, Colors.red)
                            else if(estaCompletado)
                              _Badge('Completado', Icons.star_rounded, Colors.green)
                            else if(vencida)
                              _Badge('Vacante Cerrada', Icons.lock, Colors.grey)
                            else if (estaPostulado)
                              _Badge('Postulado', Icons.check_circle, Colors.blue),
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
                spacing: 40, runSpacing: 20,
                children: [
                  _DetailItem('Beca Mensual', montoStr, Icons.monetization_on_outlined),
                  _DetailItem('Fecha Límite', _fmtDate(d['fecha_limite']), Icons.calendar_today),
                  _DetailItem('Publicada', _fmtDate(d['fecha_publicacion']), Icons.access_time),
                  _DetailItem('Horario', d['horario'] ?? 'No especificado', Icons.schedule),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 32),

        // ---------------- CONTENIDO PRINCIPAL ----------------
        
        _SectionCard(title: 'Descripción del Puesto', children: [
          Text(descripcion, style: const TextStyle(fontSize: 16, height: 1.6, color: Colors.black87)),
        ]),

        if (d['observaciones'] != null) 
          _SectionCard(title: 'Observaciones', children: [
              Text(d['observaciones'], style: const TextStyle(fontSize: 16, height: 1.6)),
          ]),

        if (beneficios != null) 
          _SectionCard(title: 'Beneficios', children: [
             if (beneficios is String)
               Text(beneficios, style: const TextStyle(fontSize: 16, height: 1.6))
             else if (beneficios is List)
               ...beneficios.map((b) => _BulletItem(b.toString())),
          ]),

        _SectionCard(title: 'Requisitos y Detalles', children: [
          _InfoRow('Escolaridad', d['escolaridad'] ?? 'No especificada'),
          const SizedBox(height: 16),
          _InfoRow('Conocimientos', d['conocimientos'] ?? 'No especificados'),
          const SizedBox(height: 16),
          _InfoRow('Periodo', '${_fmtDate(d['fecha_inicio'])} - ${_fmtDate(d['fecha_fin'])}'),
        ]),

        if (habilidades.isNotEmpty)
          _SectionCard(
            title: 'Habilidades Requeridas', 
            children: [
              Builder(
                builder: (context) {
                  final Map<String, List<String>> skillsByType = {};
                  for (var item in habilidades) {
                    if (item is Map) {
                      final String tipoRaw = item['tipo']?.toString() ?? 'Generales';
                      final String nombre = item['habilidad']?.toString() ?? '';
                      final tipo = tipoRaw.isNotEmpty ? '${tipoRaw[0].toUpperCase()}${tipoRaw.substring(1)}' : 'Generales';
                      if (nombre.isNotEmpty) {
                        if (!skillsByType.containsKey(tipo)) skillsByType[tipo] = [];
                        skillsByType[tipo]!.add(nombre);
                      }
                    } else {
                      if (!skillsByType.containsKey('Generales')) skillsByType['Generales'] = [];
                      skillsByType['Generales']!.add(item.toString());
                    }
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: skillsByType.entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(entry.key, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey[700], letterSpacing: 0.5)),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8, runSpacing: 8,
                              children: entry.value.map((nombreSkill) {
                                return Chip(
                                  label: Text(nombreSkill, style: const TextStyle(fontSize: 13)),
                                  backgroundColor: Colors.blue.shade50,
                                  labelStyle: TextStyle(color: Colors.blue.shade800, fontWeight: FontWeight.w500),
                                  side: BorderSide.none,
                                  padding: const EdgeInsets.all(4),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ]
          ),

        _SectionCard(title: 'Ubicación', children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.location_on_outlined, color: Colors.redAccent),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  ubicacion.isNotEmpty ? ubicacion : 'Remoto / No especificada', 
                  style: const TextStyle(fontSize: 16, height: 1.4, fontWeight: FontWeight.w500)
                )
              ),
            ],
          ),
        ]),

        const SizedBox(height: 20),

        // 7. BOTÓN DE ACCIÓN (Postular / Cancelar)
        SizedBox(
          width: double.infinity,
          child: (() {
            final Widget btn = SimpleButton(
              title: botonTitulo,
              onTap: botonAccion,
              primaryColor: botonColorPrimario,
              backgroundColor: botonColorFondo,
              textColor: botonTextoColor == Colors.white ? botonTextoColor : null,
            );

            if (botonAccion == null) {
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
      ],
    );
  }
}

// ... (Mantener los widgets _SectionCard, _DetailItem, etc. tal cual estaban) ...
class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;
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
        border: Border.all(color: Colors.grey.shade300), 
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: Color(0xFF1F2A36))),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

class _DetailItem extends StatelessWidget {
  final String label, value;
  final IconData icon;
  const _DetailItem(this.label, this.value, this.icon);

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
            Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.black87)),
          ],
        ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final IconData icon;
  final Color color;
  const _Badge(this.text, this.icon, this.color);

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

class _InfoRow extends StatelessWidget {
  final String label, value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black54)),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(fontSize: 16, color: Colors.black87, height: 1.4)),
      ],
    );
  }
}

class _BulletItem extends StatelessWidget {
  final String text;
  const _BulletItem(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 7),
            child: Icon(Icons.circle, size: 6, color: Colors.blue),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 16, height: 1.5))),
        ],
      ),
    );
  }
}