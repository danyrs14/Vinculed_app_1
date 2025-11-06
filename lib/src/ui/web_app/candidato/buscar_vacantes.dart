import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:vinculed_app_1/src/core/controllers/theme_controller.dart';

import 'package:vinculed_app_1/src/ui/widgets/elements/header.dart';
import 'package:vinculed_app_1/src/ui/widgets/elements/footer.dart';
import 'package:vinculed_app_1/src/ui/widgets/elements/header2.dart';
import 'package:vinculed_app_1/src/ui/widgets/text_inputs/text_input.dart';
import 'package:vinculed_app_1/src/ui/widgets/buttons/simple_buttons.dart';

class JobSearchPage extends StatefulWidget {
  const JobSearchPage({super.key});

  @override
  State<JobSearchPage> createState() => _JobSearchPageState();
}

class _JobSearchPageState extends State<JobSearchPage> {
  final _queryCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();

  final _scrollCtrl = ScrollController();
  bool _showFooter = false;

  // ===== Estado: historial y resultados de ejemplo =====
  final List<String> _searchHistory = <String>[
    // --- EJEMPLOS (borra al conectar backend) ---
    'Flutter Developer',
    'Analista de Datos',
    'QA Tester',
    'Backend Node.js',
  ];
  int _resultsCount = 0;

  // Resultados MOCK (borra y reemplaza con tu data real)
  List<Map<String, String>> _mockResults = [];

  static const double _footerReservedSpace = EscomFooter.height;
  static const double _extraBottomPadding = 24.0;
  static const double _atEndThreshold = 4.0;

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_handleScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _handleScroll());
    _generateMockResults(); // precarga ejemplos
  }

  void _handleScroll() {
    final pos = _scrollCtrl.position;
    if (!pos.hasPixels || !pos.hasContentDimensions) return;

    // si el contenido cabe en pantalla, no muestres footer
    if (pos.maxScrollExtent <= 0) {
      if (_showFooter) setState(() => _showFooter = false);
      return;
    }

    final atBottom = pos.pixels >= (pos.maxScrollExtent - _atEndThreshold);
    if (atBottom != _showFooter) setState(() => _showFooter = atBottom);
  }

  @override
  void dispose() {
    _scrollCtrl
      ..removeListener(_handleScroll)
      ..dispose();
    _queryCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;
    final w = MediaQuery.of(context).size.width;
    final isMobile = w < 700;

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
            case "Preferencias":
              context.go('/alumno/preferences');
              break;
          }
        },
      ),

      body: Stack(
        children: [
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
                        constraints: const BoxConstraints(maxWidth: 900),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: minBodyHeight > 0 ? minBodyHeight : 0,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // Avatar + Título
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const CircleAvatar(
                                      radius: 22,
                                      backgroundImage: AssetImage('assets/images/amlo.jpg'),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Buscar Vacantes',
                                      style: TextStyle(
                                        fontSize: isMobile ? 26 : 32,
                                        fontWeight: FontWeight.w800,
                                        color: const Color(0xFF22313F),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 28),

                                // Formulario centrado
                                ConstrainedBox(
                                  constraints: const BoxConstraints(maxWidth: 620),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      TextInput(
                                        title: 'Buscar',
                                        controller: _queryCtrl,
                                        keyboardType: TextInputType.text,
                                      ),
                                      const SizedBox(height: 12),
                                      TextInput(
                                        title: 'Ingresa una Ubicacion',
                                        controller: _locationCtrl,
                                        keyboardType: TextInputType.streetAddress,
                                      ),
                                      const SizedBox(height: 18),
                                      Align(
                                        alignment: Alignment.center,
                                        child: SizedBox(
                                          width: 320,
                                          child: SimpleButton(
                                            title: 'Buscar Empleo',
                                            onTap: () {
                                              _onSearch(); // ejecuta la MISMA función
                                              // ❌ ya no navegamos: NO context.go('/vacante_job');
                                            },
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 24),

                                // ===== Historial de búsqueda =====
                                if (_searchHistory.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'Historial de búsqueda',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: _clearHistory,
                                        child: const Text('Limpiar historial'),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: _searchHistory.map((q) {
                                        return InputChip(
                                          label: Text(q),
                                          onPressed: () {
                                            _queryCtrl.text = q;
                                            _onSearch(fromChip: true);
                                          },
                                          onDeleted: () => _removeFromHistory(q),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ],

                                const SizedBox(height: 28),

                                // ===== Contador de resultados =====
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    'Resultados posibles: $_resultsCount',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF22313F),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),

                                // ===== Lista de resultados de EJEMPLO =====
                                if (_mockResults.isNotEmpty) ...[
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF5F8FB),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: const Color(0xFFE2E8F0)),
                                    ),
                                    child: const Text(
                                      'Ejemplos de resultados (bórralos al conectar tu backend)',
                                      style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  ListView.separated(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: _mockResults.length,
                                    separatorBuilder: (_, __) => const Divider(height: 1),
                                    itemBuilder: (context, index) {
                                      final r = _mockResults[index];
                                      return ListTile(
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                                        title: Text(
                                          r['title'] ?? '',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        subtitle: Text(
                                          '${r['company']} • ${r['location']}',
                                        ),
                                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                                        onTap: () {
                                          // si quieres, aquí puedes abrir un detalle en esta misma pantalla
                                        },
                                      );
                                    },
                                  ),
                                ],

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

          // Footer animado: aparece al llegar al final del contenido
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

  void _onSearch({bool fromChip = false}) {
    final q = _queryCtrl.text.trim();
    final loc = _locationCtrl.text.trim();

    // Actualiza historial (sin duplicados, más reciente primero)
    if (q.isNotEmpty && !fromChip) {
      _addToHistory(q);
    }

    // Genera resultados MOCK filtrados por query/ubicación (ejemplo)
    _generateMockResults(query: q, location: loc);
    setState(() {
      _resultsCount = _mockResults.length;
    });
  }

  // ===== Helpers de historial =====
  void _addToHistory(String query) {
    _searchHistory.removeWhere((e) => e.toLowerCase() == query.toLowerCase());
    _searchHistory.insert(0, query);
    // límite opcional de historial (p.ej., 8)
    if (_searchHistory.length > 8) {
      _searchHistory.removeRange(8, _searchHistory.length);
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

  // ===== MOCK de resultados (borra y reemplaza al conectar backend) =====
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

    // Filtrado sencillo por texto/ubicación (para dar sensación de dinamismo)
    List<Map<String, String>> filtered = samples;
    if (query != null && query.isNotEmpty) {
      final ql = query.toLowerCase();
      filtered = filtered
          .where((e) =>
      (e['title'] ?? '').toLowerCase().contains(ql) ||
          (e['company'] ?? '').toLowerCase().contains(ql))
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
}
