import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:go_router/go_router.dart';
import 'package:vinculed_app_1/src/ui/widgets/elements/header3.dart';
import 'package:provider/provider.dart';
import 'package:vinculed_app_1/src/core/providers/user_provider.dart';

// ...existing code...
class RecruiterItem {
  final int id;
  final String nombre;
  final String correo;
  final String empresa;
  final String? urlLogo;
  final String estado;
  final int idEmpresa;

  RecruiterItem({
    required this.id,
    required this.nombre,
    required this.correo,
    required this.empresa,
    this.urlLogo,
    required this.estado,
    required this.idEmpresa,
  });

  factory RecruiterItem.fromJson(Map<String, dynamic> json) {
    return RecruiterItem(
      id: json['id'] is int ? json['id'] : int.parse('${json['id']}'),
      nombre: json['nombre'] ?? '',
      correo: json['correo'] ?? '',
      empresa: json['empresa'] ?? '',
      urlLogo: json['url_logo_empresa'],
      estado: json['estado'] ?? 'Pendiente',
      idEmpresa: json['id_empresa'] is int ? json['id_empresa'] : int.parse('${json['id_empresa']}'),
    );
  }
}

class InicioAdminPage extends StatefulWidget {
  const InicioAdminPage({Key? key}) : super(key: key);

  @override
  State<InicioAdminPage> createState() => _InicioAdminPageState();
}

class _InicioAdminPageState extends State<InicioAdminPage> {
  static const String apiUrl = 'http://localhost:3000/api/usuarios/reclutadores_pendientes';
  static const String acceptUrl = 'http://localhost:3000/api/usuarios/aceptar_reclutador';
  late Future<List<RecruiterItem>> _futureList;

  @override
  void initState() {
    super.initState();
    _futureList = fetchPending();
  }

  Future<List<RecruiterItem>> fetchPending() async {
    final resp = await http.get(Uri.parse(apiUrl),headers: {
          'Authorization': 'Bearer ${context.read<UserDataProvider>().idToken}',
        },);
    if (resp.statusCode != 200) {
      throw Exception('Error al obtener reclutadores: ${resp.statusCode}');
    }
    final data = json.decode(resp.body);
    if (data is! List) {
      throw Exception('Formato inesperado, se esperaba una lista JSON.');
    }
    return data.map<RecruiterItem>((e) => RecruiterItem.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  Future<void> _refresh() async {
    setState(() => _futureList = fetchPending());
    await _futureList;
  }

  Future<void> _acceptRecruiter(int id) async {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Procesando...')));
    try {
      final resp = await http.post(
        Uri.parse(acceptUrl),
        headers: {
          'Authorization': 'Bearer ${context.read<UserDataProvider>().idToken}',
          'Content-Type': 'application/json',
        },
        body: json.encode({'id_reclutador': id}),
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

  Widget _buildCard(RecruiterItem r) {
    final avatar = r.urlLogo != null
        ? ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Image.network(r.urlLogo!, width: 56, height: 56, fit: BoxFit.cover, errorBuilder: (_, __, ___) {
              return CircleAvatar(radius: 28, child: Text(r.nombre.isNotEmpty ? r.nombre[0].toUpperCase() : '?'));
            }),
          )
        : CircleAvatar(radius: 28, child: Text(r.nombre.isNotEmpty ? r.nombre[0].toUpperCase() : '?'));

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            avatar,
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(r.nombre, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(r.empresa, style: const TextStyle(fontSize: 14, color: Colors.black87)),
                const SizedBox(height: 4),
                Text(r.correo, style: const TextStyle(fontSize: 13, color: Colors.black54)),
                const SizedBox(height: 8),
                Row(children: [
                  Chip(
                    label: Text(r.estado),
                    backgroundColor: r.estado.toLowerCase() == 'pendiente' ? Colors.orange.shade100 : Colors.green.shade100,
                  ),
                  const SizedBox(width: 12),
                  Text('ID: ${r.id}', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                  const SizedBox(width: 8),
                  Text('Emp: ${r.idEmpresa}', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                ]),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: () => _acceptRecruiter(r.id),
                    child: const Text('Aceptar'),
                  ),
                )
              ]),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: EscomHeader3(
        onLoginTap: () => context.go('/reclutador/perfil_rec'),
        onNotifTap: () {},
        onMenuSelected: (label) {
          switch (label) {
            case "Inicio":
              context.go('/inicio');
              break;
            case "Crear Vacante":
              context.go('/reclutador/new_vacancy');
              break;
            case "Mis Vacantes":
              context.go('/my_vacancy');
              break;
            case "Postulaciones":
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
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<RecruiterItem>>(
          future: _futureList,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
            if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));
            final list = snap.data ?? [];
            if (list.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 200),
                  Center(child: Text('No hay reclutadores pendientes')),
                ],
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.only(top: 12, bottom: 12),
              itemCount: list.length,
              itemBuilder: (context, i) => _buildCard(list[i]),
            );
          },
        ),
      ),
    );
  }
}
// ...existing code...