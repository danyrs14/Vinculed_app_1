import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:vinculed_app_1/src/core/providers/user_provider.dart';
import 'package:http/http.dart' as http; // Necesario para la petición HTTP
import 'dart:convert'; // Necesario para decodificar JSON
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart' as fs;
import 'package:firebase_auth/firebase_auth.dart';

import 'package:vinculed_app_1/src/core/controllers/theme_controller.dart';
import 'package:vinculed_app_1/src/ui/widgets/elements/footer.dart';
import 'package:vinculed_app_1/src/ui/widgets/elements/header3.dart';

class UserProfile extends StatefulWidget {
  const UserProfile({super.key});

  @override
  State<UserProfile> createState() => _UserProfileState();
}

class _UserProfileState extends State<UserProfile> {
  final usuario = FirebaseAuth.instance.currentUser!;
  final _scrollCtrl = ScrollController();
  bool _showFooter = false;

  // NUEVOS ESTADOS para manejar la carga de la API
  Map<String, dynamic>? _perfilData;
  bool _loading = true;
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
      _fetchPerfilReclutador(); // Llama a la nueva función de carga
    });
  }

  // ──────────────────── FUNCIÓN DE CARGA ────────────────────
  Future<void> _fetchPerfilReclutador() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final userProv = context.read<UserDataProvider>();
      final headers = await userProv.getAuthHeaders();
      final idRol = userProv.idRol; // Obtenemos el ID del rol/reclutador
      
      final uri = Uri.parse('https://oda-talent-back-81413836179.us-central1.run.app/api/reclutadores/perfil')
          .replace(queryParameters: {'id_reclutador': '$idRol'});
      
      final resp = await http.get(uri, headers: headers);
      
      if (resp.statusCode != 200) {
        throw Exception('Error al obtener perfil: ${resp.statusCode}');
      }
      
      final data = jsonDecode(resp.body);
      setState(() {
        _perfilData = data is Map<String, dynamic> ? data : null;
        _loading = false;
      });
      
    } catch (e) {
      setState(() {
        _loading = false;
        _error = 'Error al cargar el perfil. Asegúrese de que el servidor esté activo. $e';
      });
    }
  }

  Future<String> _uploadRecruiterPhoto(Uint8List bytes, String ext, String ownerId) async {
    final storage = fs.FirebaseStorage.instance;
    final baseFolder = 'foto_perfil/${usuario.uid}';
    final folderRef = storage.ref().child(baseFolder);
    try {
      final existing = await folderRef.listAll();
      for (final item in existing.items) {
        await item.delete();
      }
    } catch (_) {}
    final path = '$baseFolder/avatar.$ext';
    final ref = storage.ref().child(path);
    final contentType = (ext == 'png') ? 'image/png' : 'image/jpeg';
    await ref.putData(bytes, fs.SettableMetadata(contentType: contentType));
    final url = await ref.getDownloadURL();
    return url;
  }

  Future<void> _changePhoto() async {
    try {
      final picked = await FilePicker.platform.pickFiles(type: FileType.image, allowMultiple: false, withData: true);
      if (picked == null || picked.files.isEmpty) return;
      final file = picked.files.single;
      final bytes = file.bytes;
      if (bytes == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No se pudo leer la imagen seleccionada')));
        return;
      }
      String ext = 'jpg';
      final name = (file.name).toLowerCase();
      if (name.endsWith('.png')) ext = 'png';
      if (name.endsWith('.jpeg')) ext = 'jpeg';

      final userProv = context.read<UserDataProvider>();
      final idRol = userProv.idRol;
      final owner = FirebaseAuth.instance.currentUser?.uid ?? '${idRol ?? 'reclutador'}';

      // Subir a Storage y obtener URL pública
      final photoUrl = await _uploadRecruiterPhoto(bytes, ext, owner);

      // Enviar al backend del reclutador
      final headers = await userProv.getAuthHeaders();
      final resp = await http.put(
        Uri.parse('https://oda-talent-back-81413836179.us-central1.run.app/api/reclutadores/perfil/actualizar_foto'),
        headers: headers,
        body: jsonEncode({'id_reclutador': idRol, 'url_foto_perfil': photoUrl}),
      );

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        setState(() {
          _perfilData = _perfilData ?? <String, dynamic>{};
          _perfilData!['url_foto_perfil'] = photoUrl;
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Foto actualizada correctamente')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error ${resp.statusCode}: ${resp.body}')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No se pudo actualizar la foto: $e')));
    }
  }

  void _handleScroll() {
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
      ..removeListener(_handleScroll)
      ..dispose();
    super.dispose();
  }

  // ──────────────────── CONSTRUCCIÓN DE DATOS ────────────────────

  List<_InfoItem> _leftItems() {
    final data = _perfilData ?? {};
    final empresa = data['empresa'] ?? {};
    
    return [
      _InfoItem(
        label: 'Correo Electronico:',
        value: data['correo'] ?? 'Sin correo',
        icon: Icons.email_outlined,
        circle: true,
      ),
      _InfoItem(
        label: 'Nombre de la Empresa:',
        value: empresa['nombre_empresa'] ?? 'Sin datos',
        icon: Icons.business,
      ),
      _InfoItem(
        label: 'Sitio Web:',
        value: empresa['sitio_web'] ?? 'No disponible',
        icon: Icons.link,
      ),
    ];
  }

  List<_InfoItem> _rightItems() {
    final empresa = _perfilData?['empresa'] ?? {};
    
    return [
      _InfoItem(
        label: 'Descripción de la Empresa:',
        value: empresa['descripcion_empresa'] ?? 'Aún no se ha añadido una descripción.',
        icon: Icons.edit_note,
        multiLine: true,
      ),
    ];
  }

  // ──────────────────── MÉTODO BUILD ────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;
    final w = MediaQuery.of(context).size.width;
    final isMobile = w < 900;
    final screenHeight = MediaQuery.of(context).size.height;
    
    // Extracción segura para el encabezado
    final perfil = _perfilData ?? {};
    final nombre = perfil['nombre'] ?? context.select((UserDataProvider u) => u.nombreUsuario ?? 'Reclutador');
    final fotoUrl = perfil['url_foto_perfil'];

    return Scaffold(
      backgroundColor: theme.background(),
      appBar: EscomHeader3(
        onLoginTap: () => context.go('/reclutador/perfil_rec'),
        onNotifTap: () {},
        onMenuSelected: (label) { /* ... navegación ... */ 
          switch (label) {
            case "Inicio": context.go('/inicio'); break;
            case "Crear Vacante": context.go('/reclutador/new_vacancy'); break;
            case "Mis Vacantes": context.go('/reclutador/postulaciones'); break;
            case "FAQ": context.go('/reclutador/faq_rec'); break;
            case "Mensajes": context.go('/reclutador/msg_rec'); break;
          }
        },
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: NotificationListener<ScrollNotification>(
              onNotification: (n) {
                if (n is ScrollUpdateNotification || n is ScrollEndNotification) _handleScroll();
                return false;
              },
              child: SingleChildScrollView(
                controller: _scrollCtrl,
                padding: const EdgeInsets.only(bottom: _footerReservedSpace + _extraBottomPadding),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1100),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          // Reemplaza uso incorrecto de 'constraints' por cálculo basado en pantalla
                          minHeight: (screenHeight - _footerReservedSpace - _extraBottomPadding).clamp(0, double.infinity),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ───────── Banner + Avatar (Usando datos del perfil) ─────────
                            _Banner(
                              avatarUrl: fotoUrl,
                              logoUrl: perfil['empresa']?['url_logo_empresa'],
                              onChangePhoto: _changePhoto,
                            ),
                            
                            const SizedBox(height: 18),

                            // ───────── Nombre y Rol ─────────
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    nombre,
                                    style: const TextStyle(
                                      fontSize: 26,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF1F2A36),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    perfil['empresa']?['nombre_empresa'] ?? 'Reclutador independiente',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Colors.black87,
                                      fontWeight: FontWeight.w500
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 22),

                            // ───────── Carga de datos o Contenido ─────────
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                              child: _loading
                                ? const Center(child: Padding(padding: EdgeInsets.only(top: 40), child: CircularProgressIndicator()))
                                : (_error != null)
                                    ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
                                    : isMobile
                                        ? Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              _InfoColumn(items: _leftItems()),
                                              const SizedBox(height: 24),
                                              _InfoColumn(items: _rightItems()),
                                            ],
                                          )
                                        : Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Expanded(child: _InfoColumn(items: _leftItems())),
                                              const SizedBox(width: 24),
                                              Expanded(child: _InfoColumn(items: _rightItems())),
                                            ],
                                          ),
                            ),

                            const SizedBox(height: 28),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          // ───────── Footer animado ─────────
          Positioned(
            left: 0, right: 0, bottom: 0,
            child: AnimatedSlide(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              offset: _showFooter ? Offset.zero : const Offset(0, 1),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 220),
                opacity: _showFooter ? 1 : 0,
                child: EscomFooter(isMobile: w < 700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/* ════════════════════════ Secciones / Widgets internos ═══════════════════════ */

class _Banner extends StatelessWidget {
  final String? avatarUrl;
  final String? logoUrl;
  final VoidCallback? onChangePhoto;
  
  const _Banner({this.avatarUrl, this.logoUrl, this.onChangePhoto});

  @override
  Widget build(BuildContext context) {
    // Usamos el logo de la empresa como banner de fondo si está disponible
    final backgroundImageUrl = logoUrl; 

    return Stack(
      children: [
        // Banner (Color Sólido o Imagen de la Empresa)
        AspectRatio(
          aspectRatio: 16 / 4.5,
          child: backgroundImageUrl != null
              ? Image.network(
                  backgroundImageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (ctx, err, stack) => Container(color: Colors.blueGrey.shade100),
                )
              : Container(color: Colors.blueGrey.shade100), // Color de fondo si no hay URL
        ),
        
        // Avatar del Reclutador
        Positioned(
          left: 24,
          bottom: 18,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              CircleAvatar(
                radius: 58,
                backgroundColor: Colors.white,
                child: CircleAvatar(
                  radius: 54,
                  backgroundColor: Colors.blue[50],
                  backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl!) : const AssetImage('assets/images/reclutador.png') as ImageProvider,
                  child: avatarUrl == null ? const Icon(Icons.person, size: 54, color: Colors.blueGrey) : null,
                ),
              ),
              if (onChangePhoto != null)
                Positioned(
                  right: -6,
                  bottom: -6,
                  child: Material(
                    color: Colors.white,
                    shape: const CircleBorder(),
                    elevation: 1,
                    child: IconButton(
                      tooltip: 'Cambiar foto',
                      icon: const Icon(Icons.edit, size: 18),
                      onPressed: onChangePhoto,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints.tightFor(width: 32, height: 32),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoColumn extends StatelessWidget {
  const _InfoColumn({required this.items});

  final List<_InfoItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      children: [
        for (final it in items) ...[
          _InfoRow(item: it),
          const SizedBox(height: 16),
        ],
      ],
    );
  }
}

// Mantiene la estructura de datos pero añade URL opcional
class _InfoItem {
  final String label;
  final String value;
  final IconData icon;
  final bool multiLine;
  final bool circle;

  const _InfoItem({
    required this.label,
    required this.value,
    required this.icon,
    this.multiLine = false,
    this.circle = false,
  });
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.item});
  final _InfoItem item;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: item.multiLine ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        // Etiqueta
        SizedBox(
          width: 210,
          child: Text(
            item.label,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        // Valor
        Expanded(
          child: Text(
            item.value,
            style: const TextStyle(color: Colors.black87, height: 1.4),
          ),
        ),
        // Acción (icono en círculo)
        const SizedBox(width: 10),
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: item.circle ? Border.all(color: Colors.black54, width: 1.2) : null,
          ),
          alignment: Alignment.center,
          child: Icon(item.icon, size: 14, color: Colors.black87),
        ),
      ],
    );
  }
}