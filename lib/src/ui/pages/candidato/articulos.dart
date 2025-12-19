import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:vinculed_app_1/src/ui/widgets/text_inputs/roles_multi_dropdown.dart';
import 'package:vinculed_app_1/src/core/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:vinculed_app_1/src/core/controllers/theme_controller.dart';
import 'package:vinculed_app_1/src/ui/widgets/elements/header2.dart';

class AlumnoArticulosPage extends StatefulWidget {
  const AlumnoArticulosPage({super.key});

  @override
  State<AlumnoArticulosPage> createState() => _AlumnoArticulosPageState();
}

class _AlumnoArticulosPageState extends State<AlumnoArticulosPage> {
  RoleOption? _selectedRol;
  String? _markdownContent;
  bool _loadingArticulo = false;
  String? _errorArticulo;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _fetchArticulo(int idRol) async {
    setState(() {
      _loadingArticulo = true;
      _errorArticulo = null;
      _markdownContent = null;
    });
    try {
      final url = Uri.parse('https://oda-talent-back-81413836179.us-central1.run.app/api/roles_trabajo/articulos/$idRol');
      // Usa headers autenticados si están disponibles
      Map<String, String>? headers;
      try {
        final userProv = Provider.of<UserDataProvider>(context, listen: false);
        headers = await userProv.getAuthHeaders();
      } catch (_) {
        headers = {};
      }
      final res = await http.get(url, headers: headers);
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final data = jsonDecode(res.body) as List<dynamic>;
        if (data.isNotEmpty) {
          final first = data.first as Map<String, dynamic>;
          _markdownContent = (first['contenido'] ?? '') as String;
        } else {
          _errorArticulo = 'Sin contenido.';
        }
      } else if (res.statusCode == 404) {
        _errorArticulo = 'Lo sentimos, no contamos con un artículo de ese rol de trabajo.';
      } else {
        _errorArticulo = 'Error ${res.statusCode}';
      }
    } catch (e) {
      _errorArticulo = 'Error: $e';
    } finally {
      if (mounted) {
        setState(() {
          _loadingArticulo = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;
    final w = MediaQuery.of(context).size.width;
    final isMobile = w < 700;

    return Scaffold(
      backgroundColor: theme.background(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ---------- Título ----------
                  Text(
                    'Explorar Puestos en TI',
                    style: TextStyle(
                      fontSize: isMobile ? 26 : 34,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF22313F),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Selecciona el puesto de trabajo del que te gustaría saber información. Al confirmar se cargará un artículo detallado.',
                    style: TextStyle(
                      fontSize: isMobile ? 14 : 16,
                      color: Colors.black87,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 24),
                  RolesMultiDropdown(
                    label: 'Elegir rol de trabajo',
                    hintText: '',
                    singleSelection: true,
                    initialSelectedIds: _selectedRol != null ? [_selectedRol!.id] : const [],
                    onChanged: (roles) {
                      final r = roles.isNotEmpty ? roles.first : null;
                      setState(() {
                        _selectedRol = r;
                      });
                      if (r != null) {
                        _fetchArticulo(r.id);
                      } else {
                        setState(() {
                          _markdownContent = null;
                        });
                      }
                    },
                    onOpen: () {},
                    onClose: () {},
                  ),
                  const SizedBox(height: 28),
                  if (_loadingArticulo) const LinearProgressIndicator(minHeight: 3),
                  if (_errorArticulo != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.secundario().withOpacity(0.08),
                        border: Border.all(
                          color: theme.secundario().withOpacity(0.35),
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: theme.secundario(),
                            size: 22,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Contenido no disponible',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: theme.fuente(),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _errorArticulo!,
                                  style: const TextStyle(
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Sugerencia: intenta seleccionando otro rol por ahora.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (_markdownContent != null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Markdown(
                          data: _markdownContent!,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.grey.withOpacity(0.25)),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          child: const Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Icon(Icons.auto_awesome, size: 16, color: Colors.grey),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Aviso sobre el uso de IA: Este texto se creó con la ayuda de ChatGPT',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
