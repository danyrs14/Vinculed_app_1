import 'package:flutter/material.dart';
import 'package:vinculed_app_1/src/core/controllers/theme_controller.dart';
import 'package:vinculed_app_1/src/ui/pages/candidato/menu.dart';
import 'package:vinculed_app_1/src/ui/widgets/buttons/large_buttons.dart';
import 'package:vinculed_app_1/src/ui/widgets/buttons/simple_buttons.dart';
import 'package:vinculed_app_1/src/ui/widgets/text_inputs/text_input.dart';
import 'package:vinculed_app_1/src/ui/widgets/textos/textos.dart';

class Busqueda extends StatefulWidget {
  @override
  _BusquedaState createState() => _BusquedaState();
}

class _BusquedaState extends State<Busqueda> {
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _locationController = TextEditingController(); // NUEVO

  // ===== Estado: historial, contador y resultados MOCK =====
  final List<String> _searchHistory = <String>[
    // --- EJEMPLOS (borra al conectar backend) ---
    'Flutter Developer',
    'Analista de Datos',
    'QA Tester',
    'Backend Node.js',
  ];
  int _resultsCount = 0;

  // Resultados MOCK (borra al conectar backend)
  List<Map<String, String>> _mockResults = [];

  @override
  void initState() {
    super.initState();
    _generateMockResults(); // precarga ejemplos
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;

    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context); // Regresar a la pantalla anterior
        return false;
      },
      child: Scaffold(
        backgroundColor: theme.background(),
        appBar: AppBar(
          backgroundColor: theme.background(),
          automaticallyImplyLeading: false,
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Logo a la izquierda
              Image.asset(
                'assets/images/escom.png',
                width: 50,
                height: 50,
              ),

              // Íconos a la derecha (Búsqueda, Notificaciones y Perfil)
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.search, color: theme.primario()),
                    onPressed: () {
                      setState(() {
                        _isSearching = true; // Mantiene tu lógica
                      });
                      _onSearch(); // ejecuta búsqueda
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.notifications_none, color: theme.primario()),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: CircleAvatar(
                      backgroundImage: AssetImage('assets/images/amlo.jpg'),
                      radius: 18,
                    ),
                    onPressed: () {
                      // Acción para perfil
                    },
                  ),
                ],
              ),
            ],
          ),
          elevation: 0,
        ),
        body: Column(
          children: [
            const SizedBox(height: 8),
            Texto(
              text: 'Buscar Vacantes',
              fontSize: 24,
            ),

            // Campo de texto para búsqueda
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextInput(
                controller: _searchController,
                title: "Buscar",
                onChanged: (text) {
                  setState(() {
                    // Filtro en vivo si lo deseas
                  });
                },
              ),
            ),

            // NUEVO: Campo de ubicación
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TextInput(
                controller: _locationController,
                title: "Ubicación",
                // keyboardType: TextInputType.streetAddress, // si tu TextInput lo soporta
              ),
            ),

            const SizedBox(height: 8),

            // ===== Historial de búsqueda (chips) =====
            if (_searchHistory.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Historial de búsqueda',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: _clearHistory,
                          child: const Text('Limpiar historial'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _searchHistory.map((q) {
                          return InputChip(
                            label: Text(q),
                            onPressed: () {
                              _searchController.text = q;
                              _onSearch(fromChip: true);
                            },
                            onDeleted: () => _removeFromHistory(q),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 8),

            // ===== Contador de resultados =====
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Resultados posibles: $_resultsCount',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),

            // ===== Lista de resultados MOCK =====
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: _mockResults.isEmpty
                    ? const Center(
                  child: Text(
                    'Sin resultados. Intenta con otra búsqueda.',
                    style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
                  ),
                )
                    : ListView.separated(
                  padding: const EdgeInsets.only(bottom: 12),
                  itemCount: _mockResults.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final r = _mockResults[index];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      title: Text(
                        r['title'] ?? '',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text('${r['company']} • ${r['location']}'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        // Aquí podrías navegar al detalle
                        // Navigator.push(...);
                      },
                    );
                  },
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Botones Regresar + Buscar (lado a lado)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Row(
                children: [
                  Expanded(
                    child: SimpleButton(
                      title: "Regresar",
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => MenuPage()),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SimpleButton(
                      title: "Buscar",
                      onTap: _onSearch, // NUEVO botón al lado de Regresar
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  // ==================== LÓGICA ====================

  void _onSearch({bool fromChip = false}) {
    final q = _searchController.text.trim();
    final loc = _locationController.text.trim();

    // Actualiza historial (sin duplicados; no guardamos ubicación en el historial)
    if (q.isNotEmpty && !fromChip) {
      _addToHistory(q);
    }

    // Genera resultados MOCK filtrados por query + ubicación (reemplaza con tu backend)
    _generateMockResults(query: q, location: loc);
    setState(() {
      _resultsCount = _mockResults.length;
    });
  }

  // ------- Historial -------
  void _addToHistory(String query) {
    _searchHistory.removeWhere((e) => e.toLowerCase() == query.toLowerCase());
    _searchHistory.insert(0, query);
    // límite opcional
    if (_searchHistory.length > 10) {
      _searchHistory.removeRange(10, _searchHistory.length);
    }
    setState(() {});
  }

  void _removeFromHistory(String query) {
    _searchHistory.removeWhere((e) => e == query);
    setState(() {});
  }

  void _clearHistory() {
    _searchHistory.clear();
    setState(() {});
  }

  // ------- MOCK de resultados (borra al conectar backend) -------
  void _generateMockResults({String? query, String? location}) {
    final samples = <Map<String, String>>[
      {
        'title': 'Flutter Developer JR',
        'company': 'ESCOM Jobs',
        'location': 'CDMX',
      },
      {
        'title': 'Backend Node.js (Express)',
        'company': 'ODAtalent',
        'location': 'CDMX',
      },
      {
        'title': 'QA Tester Manual/Automatizado',
        'company': 'Quality Labs',
        'location': 'Edomex',
      },
      {
        'title': 'Data Analyst (SQL/Python)',
        'company': 'DataWorks',
        'location': 'Remoto',
      },
      {
        'title': 'Frontend React',
        'company': 'Webify',
        'location': 'Guadalajara',
      },
    ];

    List<Map<String, String>> filtered = samples;

    if (query != null && query.isNotEmpty) {
      final ql = query.toLowerCase();
      filtered = filtered
          .where((e) =>
      (e['title'] ?? '').toLowerCase().contains(ql) ||
          (e['company'] ?? '').toLowerCase().contains(ql) ||
          (e['location'] ?? '').toLowerCase().contains(ql))
          .toList();
    }

    if (location != null && location.isNotEmpty) {
      final ll = location.toLowerCase();
      filtered = filtered.where((e) => (e['location'] ?? '').toLowerCase().contains(ll)).toList();
    }

    setState(() {
      _mockResults = filtered;
      _resultsCount = _mockResults.length;
    });
  }

  // ======================================================

  @override
  void dispose() {
    _searchController.dispose();
    _locationController.dispose(); // NUEVO
    super.dispose();
  }
}
