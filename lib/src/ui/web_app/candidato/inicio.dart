import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:vinculed_app_1/src/core/controllers/theme_controller.dart';
import 'package:vinculed_app_1/src/ui/widgets/buttons/simple_buttons.dart';
import 'package:vinculed_app_1/src/ui/widgets/elements/footer.dart';
import 'package:vinculed_app_1/src/ui/widgets/elements/header2.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:vinculed_app_1/src/core/providers/user_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:vinculed_app_1/src/ui/web_app/candidato/vacante.dart'; // detalle

// ======= SOLO AGREGADO PARA NOTIFICACIONES + GUARDAR TOKEN/DISPLAYNAME =======
import 'package:vinculed_app_1/src/core/services/notification_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class HomeRegisteredPage extends StatefulWidget {
  const HomeRegisteredPage({super.key});

  @override
  State<HomeRegisteredPage> createState() => _HomeRegisteredPageState();
}

class _HomeRegisteredPageState extends State<HomeRegisteredPage> {
  final _scrollCtrl = ScrollController();
  bool _showFooter = false;
  final usuario = FirebaseAuth.instance.currentUser!;

  // --- Estado de vacantes dinámicas ---
  List<Map<String, dynamic>> _vacantes = [];
  bool _loadingVac = false;
  String? _errorVac;
  bool _initialFetchDone = false;

  static const double _footerReservedSpace = EscomFooter.height;
  static const double _extraBottomPadding = 24.0;
  static const double _atEndThreshold = 4.0;

  // ======= SOLO AGREGADO PARA EVITAR DUPLICAR SETUP / BIENVENIDA =======
  static bool _welcomeShown = false;

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _onScroll();

      // ======= SETUP DE PUSH + GUARDAR FCM TOKEN Y DISPLAY NAME EN /users/{uid} =======
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('HomeRegisteredPage: no hay usuario autenticado, omito push.');
        return;
      }

      // Inicializa push y listeners (igual que reclutador)
      await NotificationService.instance.initPush();
      await NotificationService.instance.startListeningToIncomingMessages();

      // Guarda token + displayName en Firestore (/users)
      try {
        final token = await FirebaseMessaging.instance.getToken();
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
          {
            'fcmToken': token,
            'displayName': user.displayName,
          },
          SetOptions(merge: true),
        );
      } catch (e) {
        print('HomeRegisteredPage: error guardando token/displayName: $e');
      }

      // Notificación de bienvenida (una sola vez)
      if (_welcomeShown) return;
      _welcomeShown = true;

      final nombre = user.displayName ?? 'usuario';
      await NotificationService.instance.addNotification(
        userId: user.uid,
        title: '¡Bienvenido $nombre!',
        body: 'Has iniciado sesión correctamente.',
      );
    });
  }

  void _onScroll() {
    final pos = _scrollCtrl.position;
    if (!pos.hasPixels || !pos.hasContentDimensions) return;

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
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

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
      if (mounted) {
        setState(() => _loadingVac = false);
      }
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
    final idVac = anyId is int ? anyId : int.tryParse(anyId?.toString() ?? '');

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 22, 18, 16),
      decoration: BoxDecoration(
        color: theme.background(),
        border: Border.all(color: theme.secundario(), width: 1.4),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(titulo.toString(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700), textAlign: TextAlign.center),
          const SizedBox(height: 6),
          Text(location.isEmpty ? 'Sin ubicación' : location, style: const TextStyle(color: Colors.black54), textAlign: TextAlign.center),
          const SizedBox(height: 10),
          Text(empresa.toString(), style: const TextStyle(fontWeight: FontWeight.w700), textAlign: TextAlign.center),
          const SizedBox(height: 14),
          SizedBox(
            child: SimpleButton(
              title: 'Ver detalles',
              onTap: idVac == null ? null : () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => JobDetailPage(idVacante: idVac),
                  ),
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
      decoration: BoxDecoration(
        color: Colors.white,
        //borderRadius: BorderRadius.circular(16),
        //border: Border.all(color: Colors.blue.shade50),
        // boxShadow: [
        //   BoxShadow(
        //     color: Colors.blue.withOpacity(0.05),
        //     blurRadius: 15,
        //     offset: const Offset(0, 5),
        //   ),
        // ],
      ),
      child: Column(
        children: [
          // "Dibujito" hecho con Iconos y Contenedores
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
            "¡Pronto despegaremos!",
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
              "Por el momento no hay nuevas vacantes publicadas, pero estamos preparando las mejores oportunidades para ti. ¡Vuelve pronto!",
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
    final w = MediaQuery.of(context).size.width;
    final isMobile = w < 700;

    final userProv = context.watch<UserDataProvider>();
    final idRol = userProv.idRol;
    if (!_initialFetchDone && idRol != null) {
      _initialFetchDone = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _fetchVacantesHome(idRol));
    }

    return Scaffold(
      backgroundColor: theme.background(),
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
            child: LayoutBuilder(
              builder: (context, constraints) {
                final minBodyHeight =
                    constraints.maxHeight - _footerReservedSpace - _extraBottomPadding;

                return NotificationListener<ScrollNotification>(
                  onNotification: (n) {
                    if (n is ScrollUpdateNotification ||
                        n is UserScrollNotification ||
                        n is ScrollEndNotification) {
                      _onScroll();
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
                        constraints: const BoxConstraints(maxWidth: 1200),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: minBodyHeight > 0 ? minBodyHeight : 0,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Saludo con avatar
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 58,
                                      backgroundColor: Colors.blue[50],
                                      backgroundImage: usuario.photoURL != null ? NetworkImage(usuario.photoURL!) : null,
                                      child: usuario.photoURL == null ? const Icon(Icons.person, size: 58) : null,
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Text(
                                        'Bienvenido de Nuevo -  ${usuario.displayName}',
                                        style: TextStyle(
                                          fontSize: isMobile ? 22 : 28,
                                          fontWeight: FontWeight.w800,
                                          color: const Color(0xFF22313F),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 28),

                                // --- LÓGICA MODIFICADA AQUÍ ---
                                if (_loadingVac)
                                  const Center(child: Padding(
                                    padding: EdgeInsets.symmetric(vertical: 40),
                                    child: CircularProgressIndicator(),
                                  ))
                                else if (_errorVac != null)
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFF1F2),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: const Color(0xFFFCA5A5)),
                                    ),
                                    child: Text(_errorVac!, style: const TextStyle(color: Colors.red)),
                                  )
                                else if (_vacantes.isEmpty)
                                  // SI LA LISTA ESTÁ VACÍA, MOSTRAMOS EL MENSAJE OPTIMISTA
                                    _buildEmptyState()
                                  else
                                  // SI HAY DATOS, MOSTRAMOS FILA EN DESKTOP / COLUMNA EN MÓVIL
                                    (isMobile
                                        ? Column(
                                      children: _vacantes.map((v) => Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 1.0),
                                        child: _buildVacanteCard(v),
                                      )).toList(),
                                    )
                                        : Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: List.generate(3, (index) {
                                        Map<String, dynamic>? v = index < _vacantes.length ? _vacantes[index] : null;
                                        if (v == null) {
                                          return const Expanded(child: SizedBox());
                                        }
                                        return Expanded(
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                            child: _buildVacanteCard(v),
                                          ),
                                        );
                                      }),
                                    )
                                    ),

                                const SizedBox(height: 28),

                                // Botones grandes inferior (responsive)
                                LayoutBuilder(
                                  builder: (context, c) {
                                    final stackButtons = c.maxWidth < 680;
                                    if (stackButtons) {
                                      return Column(
                                        children: [
                                          SimpleButton(
                                            title: 'Buscar Vacantes',
                                            onTap: () => context.go('/alumno/busqueda_job'),
                                          ),
                                          const SizedBox(height: 16),
                                          SimpleButton(
                                            title: 'Notificaciones',
                                            onTap: () {},
                                          ),
                                        ],
                                      );
                                    }
                                    return Row(
                                      children: [
                                        Expanded(
                                          child: SimpleButton(
                                            title: 'Buscar Vacantes',
                                            onTap: () => context.go('/alumno/busqueda_job'),
                                          ),
                                        ),
                                        const SizedBox(width: 24),
                                        Expanded(
                                          child: SimpleButton(
                                            title: 'Notificaciones',
                                            onTap: () {},
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
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

          // Footer animado
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
}
//