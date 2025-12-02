import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:vinculed_app_1/src/core/controllers/theme_controller.dart';
import 'package:vinculed_app_1/src/ui/pages/candidato/busqueda.dart';
import 'package:vinculed_app_1/src/ui/pages/candidato/vacante.dart';
import 'package:vinculed_app_1/src/ui/widgets/buttons/simple_buttons.dart';
import 'package:vinculed_app_1/src/ui/widgets/textos/textos.dart';
import 'package:provider/provider.dart';
import 'package:vinculed_app_1/src/core/providers/user_provider.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class Home extends StatefulWidget {
  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final usuario = FirebaseAuth.instance.currentUser!;

  // Estado para vacantes (similar a HomeRegisteredPage)
  List<Map<String, dynamic>> _vacantes = [];
  bool _loadingVac = false;
  String? _errorVac;
  bool _initialFetchDone = false;

  Future<void> _fetchVacantesHome(int idRol) async {
    if (_loadingVac) return;
    setState(() {
      _loadingVac = true;
      _errorVac = null;
    });

    final uri = Uri.parse('https://oda-talent-back-81413836179.us-central1.run.app/api/vacantes/buscar').replace(queryParameters: {
      'ordenar_por': 'fecha_publicacion_desc',
      'page': '1',
      'limit': '3',
      'id_alumno': idRol.toString(),
    });

    try {
      final userProv = context.read<UserDataProvider>();
      final headers = await userProv.getAuthHeaders();
      final res = await http.get(uri, headers: headers);
      if (res.statusCode < 200 || res.statusCode >= 300) {
        throw Exception('HTTP ${res.statusCode}');
      }
      final body = jsonDecode(res.body);
      if (body is! Map) throw Exception('Formato inesperado');
      final map = Map<String, dynamic>.from(body);
      final items = (map['vacantes'] as List?) ?? const [];
      setState(() {
        _vacantes = items
            .whereType<Map>()
            .map((m) => Map<String, dynamic>.from(m))
            .toList();
      });
    } catch (e) {
      setState(() {
        _errorVac = 'No se pudieron cargar las vacantes: $e';
      });
    } finally {
      if (mounted) setState(() => _loadingVac = false);
    }
  }

  Widget _buildVacanteCard(Map<String, dynamic>? v) {
    final theme = ThemeController.instance;
    if (v == null) {
      return Container(
        padding: const EdgeInsets.fromLTRB(18, 22, 18, 16),
        decoration: BoxDecoration(
          color: theme.background(),
          border: Border.all(color: theme.secundario(), width: 1.4),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(child: Text('Sin datos')),
      );
    }
    final titulo = v['titulo'] ?? v['nombre'] ?? 'Vacante';
    final empresa = v['empresa'] ?? v['nombre_empresa'] ?? 'Empresa';
    final ciudad = v['ciudad'] ?? '';
    final entidad = v['entidad'] ?? '';
    final location = [ciudad, entidad]
        .where((e) => e != null && e.toString().isNotEmpty)
        .join(', ');
    final anyId = v['id_vacante'] ?? v['id'];
    final int? idVac = anyId is int ? anyId : int.tryParse(anyId?.toString() ?? '');

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 22, 18, 16),
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: theme.background(),
        border: Border.all(color: theme.secundario(), width: 1.4),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(titulo.toString(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700), textAlign: TextAlign.left),
          const SizedBox(height: 6),
          Text(location.isEmpty ? 'Sin ubicación' : location, style: const TextStyle(color: Colors.black54)),
          const SizedBox(height: 10),
          Text(empresa.toString(), style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 14),
          SizedBox(
            child: SimpleButton(
              title: 'Ver detalles',
              onTap: idVac == null ? null : () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => JobDetailPage(idVacante: idVac)),
                );
              },
              primaryColor: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      color: Colors.white,
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  shape: BoxShape.circle,
                ),
              ),
              Icon(Icons.rocket_launch_rounded, size: 50, color: Colors.blue.shade300),
              Positioned(
                top: 20,
                right: 20,
                child: Icon(Icons.star_rounded, size: 20, color: Colors.yellow.shade700),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            '¡Pronto despegaremos!',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1F2A36),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          const SizedBox(
            width: 400,
            child: Text(
              'Por el momento no hay nuevas vacantes publicadas, pero estamos preparando las mejores oportunidades para ti. ¡Vuelve pronto!',
              style: TextStyle(
                fontSize: 16,
                color: Colors.black54,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;

    final userProv = context.watch<UserDataProvider>();
    final idRol = userProv.idRol;
    if (!_initialFetchDone && idRol != null) {
      _initialFetchDone = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _fetchVacantesHome(idRol));
    }

    return Scaffold(
      backgroundColor: theme.background(),
      // Eliminando el appBar y el BottomNavigationBar
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 20),
              // Título de la pantalla
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const SizedBox(width: 10),
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: Colors.blue[50],
                    backgroundImage: usuario.photoURL != null ? NetworkImage(usuario.photoURL!) : null,
                    child: usuario.photoURL == null ? const Icon(Icons.person, size: 26) : null,
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Texto(
                        text: '${usuario.displayName}',
                        fontSize: 16,
                      ),
                      const Texto(
                        text: 'Bienvenido de Nuevo',
                        fontSize: 18,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // CONTENIDO TRAÍDO DE HomeRegisteredPage (versión móvil)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Builder(
                  builder: (_) {
                    if (_loadingVac) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    if (_errorVac != null) {
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF1F2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFFCA5A5)),
                        ),
                        child: Text(_errorVac!, style: const TextStyle(color: Colors.red)),
                      );
                    }
                    if (_vacantes.isEmpty) {
                      return _buildEmptyState();
                    }

                    // En móvil listamos verticalmente hasta 3 vacantes
                    final mostrar = _vacantes.take(3).toList();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final v in mostrar) _buildVacanteCard(v),
                      ],
                    );
                  },
                ),
              ),

              const SizedBox(height: 24),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  children: [
                    SimpleButton(
                      title: 'Buscar Vacantes',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => Busqueda()),
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
