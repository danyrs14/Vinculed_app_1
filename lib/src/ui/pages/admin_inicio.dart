import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:go_router/go_router.dart';

import 'package:provider/provider.dart';
import 'package:vinculed_app_1/src/core/providers/user_provider.dart';
import 'package:vinculed_app_1/src/ui/widgets/buttons/simple_buttons.dart';
import 'package:vinculed_app_1/src/ui/widgets/elements/header4.dart';

// ...existing code...
class RecruiterItem {
  final int idReclutador;
  final String nombre;
  final String correo;
  final String empresa;
  final String? urlLogo;
  final String estado;
  final int idEmpresa;
  final int idUsuario;

  RecruiterItem({
    required this.idReclutador,
    required this.nombre,
    required this.correo,
    required this.empresa,
    this.urlLogo,
    required this.estado,
    required this.idEmpresa,
    required this.idUsuario,
  });

  factory RecruiterItem.fromJson(Map<String, dynamic> json) {
    return RecruiterItem(
      idReclutador: json['id_reclutador'] is int ? json['id_reclutador'] : int.parse('${json['id_reclutador']}'),
      nombre: json['nombre'] ?? '',
      correo: json['correo'] ?? '',
      empresa: json['empresa'] ?? '',
      urlLogo: json['url_logo_empresa'],
      estado: json['estado'] ?? 'Pendiente',
      idEmpresa: json['id_empresa'] is int ? json['id_empresa'] : int.parse('${json['id_empresa']}'),
      idUsuario: json['id_usuario'] is int ? json['id_usuario'] : int.parse('${json['id_usuario']}'),
    );
  }
}

class InicioAdminPageMovil extends StatefulWidget {
  const InicioAdminPageMovil({Key? key}) : super(key: key);

  @override
  State<InicioAdminPageMovil> createState() => _InicioAdminPageMovilState();
}

class _InicioAdminPageMovilState extends State<InicioAdminPageMovil> {
  static const String apiUrl = 'http://10.0.2.2:3000/api/usuarios/reclutadores_pendientes';
  static const String acceptUrl = 'http://10.0.2.2:3000/api/usuarios/aceptar_reclutador';
  static const String denyUrl = 'http://10.0.2.2:3000/api/usuarios/rechazar_reclutador';
  late Future<List<RecruiterItem>> _futureList;

  // === Footer estilo "Dashboard" ===
  final ScrollController _scrollCtrl = ScrollController();
  static const double _extraBottomPadding  = 24.0;

  @override
  void initState() {
    super.initState();
    _futureList = fetchPending();
  }
  // Footer logic removed

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<List<RecruiterItem>> fetchPending() async {
    final headers = await context.read<UserDataProvider>().getAuthHeaders();
    final resp = await http.get(
      Uri.parse(apiUrl),
      headers: headers,
    );
    if (resp.statusCode == 500 ) {
      throw Exception('Error al obtener reclutadores: ${resp.statusCode}');
    }
    if (resp.statusCode == 404) {
      return [];
    }
    final data = json.decode(resp.body);
    if (data is! List) {
      throw Exception('Formato inesperado, se esperaba una lista JSON.');
    }
    return data.map<RecruiterItem>((e) => RecruiterItem.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  Future<void> _refresh() async {
    setState(() { _futureList = fetchPending(); });
    await _futureList;
    // Footer logic removed; no post-frame recalculation needed
  }

  Future<void> _acceptRecruiter(int idReclutador) async {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Procesando...')));
    try {
      final headers = await context.read<UserDataProvider>().getAuthHeaders();
      final resp = await http.post(
        Uri.parse(acceptUrl),
        headers: headers,
        body: json.encode({'id_reclutador': idReclutador}),
      );
      if (resp.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reclutador aceptado')));
        await _refresh();
      } else {
        final message = resp.body.isNotEmpty ? resp.body : 'Código ${resp.statusCode}';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al aceptar: $message')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _denyRecruiter(int idUsuario) async {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Procesando...')));
    try {
      final headers = await context.read<UserDataProvider>().getAuthHeaders();
      final resp = await http.post(
        Uri.parse(denyUrl),
        headers: headers,
        body: json.encode({'id_usuario': idUsuario}),
      );
      if (resp.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reclutador rechazado')));
        await _refresh();
      } else {
        final message = resp.body.isNotEmpty ? resp.body : 'Código ${resp.statusCode}';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al rechazar: $message')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget _buildCard(RecruiterItem r) {
    final avatar = r.urlLogo != null
        ? ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: Image.network(
        r.urlLogo!,
        width: 56,
        height: 56,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) {
          return CircleAvatar(
            radius: 28,
            backgroundColor: Colors.blue[50],
            child: Text(
              r.nombre.isNotEmpty ? r.nombre[0].toUpperCase() : '?',
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
            ),
          );
        },
      ),
    )
        : CircleAvatar(
      radius: 28,
      backgroundColor: Colors.blue[50],
      child: Text(
        r.nombre.isNotEmpty ? r.nombre[0].toUpperCase() : '?',
        style: TextStyle(color: Theme.of(context).colorScheme.primary),
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 600;

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Card(
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: isSmallScreen
                    ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        avatar,
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                r.nombre,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                r.empresa,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.black87),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                r.correo,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.black54),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Chip(
                          label: Text(r.estado),
                          backgroundColor: r.estado.toLowerCase() == 'pendiente'
                              ? Theme.of(context).colorScheme.secondary.withOpacity(0.2)
                              : Theme.of(context).colorScheme.primary.withOpacity(0.2),
                          labelStyle: TextStyle(
                            color: r.estado.toLowerCase() == 'pendiente'
                                ? Theme.of(context).colorScheme.secondary
                                : Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'ID: ${r.idReclutador}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.black54),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Empresa: ${r.idEmpresa}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.black54),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Expanded(
                          child: SimpleButton(
                            title: 'Aceptar',
                            primaryColor: true,
                            onTap: () => _acceptRecruiter(r.idReclutador),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: SimpleButton(
                            title: 'Rechazar',
                            primaryColor: false,
                            backgroundColor: Colors.red,
                            onTap: () => _denyRecruiter(r.idUsuario),
                          ),
                        ),
                      ],
                    ),
                  ],
                )
                    : Row(
                  children: [
                    avatar,
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            r.nombre,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            r.empresa,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.black87),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            r.correo,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.black54),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Chip(
                                label: Text(r.estado),
                                backgroundColor: r.estado.toLowerCase() == 'pendiente'
                                    ? Theme.of(context).colorScheme.secondary.withOpacity(0.2)
                                    : Theme.of(context).colorScheme.primary.withOpacity(0.2),
                                labelStyle: TextStyle(
                                  color: r.estado.toLowerCase() == 'pendiente'
                                      ? Theme.of(context).colorScheme.secondary
                                      : Theme.of(context).colorScheme.primary,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'ID: ${r.idReclutador}',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.black54),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Emp: ${r.idEmpresa}',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.black54),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      children: [
                        SizedBox(
                          width: 140,
                          child: SimpleButton(
                            title: 'Aceptar',
                            primaryColor: true,
                            onTap: () => _acceptRecruiter(r.idReclutador),
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: 140,
                          child: SimpleButton(
                            title: 'Rechazar',
                            primaryColor: false,
                            backgroundColor: Colors.red,
                            onTap: () => _denyRecruiter(r.idUsuario),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ...existing code...
  @override
  Widget build(BuildContext context) {
  // Removed mobile footer usage

    return Scaffold(

      body: Stack(
        children: [
          // === CONTENIDO estilo "Dashboard" ===
          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Reservamos espacio inferior básico para evitar salto visual
                final minBodyHeight = constraints.maxHeight - _extraBottomPadding;

                return RefreshIndicator(
                  onRefresh: _refresh,
                  child: SingleChildScrollView(
                    controller: _scrollCtrl,
                    physics: const ClampingScrollPhysics(),
                    padding: const EdgeInsets.only(top: 12, bottom: _extraBottomPadding),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 900),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(minHeight: minBodyHeight > 0 ? minBodyHeight : 0),
                            child: FutureBuilder<List<RecruiterItem>>(
                              future: _futureList,
                              builder: (context, snap) {
                                if (snap.connectionState == ConnectionState.waiting) {
                                  return Column(
                                    children: const [
                                      SizedBox(height: 200),
                                      Center(child: CircularProgressIndicator()),
                                    ],
                                  );
                                }
                                if (snap.hasError) {
                                  return Column(
                                    children: [
                                      const SizedBox(height: 200),
                                      Center(
                                        child: Text(
                                          'Error: ',
                                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.red),
                                        ),
                                      ),
                                      Center(
                                        child: Text(
                                          '${snap.error}',
                                          textAlign: TextAlign.center,
                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.red),
                                        ),
                                      ),
                                    ],
                                  );
                                }

                                final list = snap.data ?? [];
                                if (list.isEmpty) {
                                  return Column(
                                    children: const [
                                      SizedBox(height: 200),
                                      Center(child: Text('No hay reclutadores pendientes')),
                                    ],
                                  );
                                }

                                // Renderizamos tarjetas en Column para usar el mismo scroll padre
                                return Column(
                                  children: [
                                    for (final r in list) _buildCard(r),
                                  ],
                                );
                              },
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
          // Footer removed
        ],
      ),
    );
  }
// ...existing
}
