import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:vinculed_app_1/src/core/controllers/theme_controller.dart';
import 'package:vinculed_app_1/src/ui/pages/candidato/busqueda.dart';
import 'package:vinculed_app_1/src/ui/pages/candidato/menu.dart';
import 'package:vinculed_app_1/src/ui/widgets/buttons/simple_buttons.dart';
import 'package:vinculed_app_1/src/ui/widgets/textos/textos.dart';
import 'package:vinculed_app_1/src/core/services/notification_log_service.dart';

class Notificaciones extends StatelessWidget {
  Notificaciones({super.key});

  final FirebaseAuth _auth = FirebaseAuth.instance;

  String _formatDate(Timestamp? ts) {
    if (ts == null) return '';
    final dt = ts.toDate();
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final y = dt.year.toString();
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '$d/$m/$y  $hh:$mm';
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;
    final user = _auth.currentUser;

    return Scaffold(
      backgroundColor: theme.background(),
      appBar: AppBar(
        backgroundColor: theme.background(),
        automaticallyImplyLeading: false,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Image.asset(
              'assets/images/graduate.png',
              width: 50,
              height: 50,
            ),
            Row(
              children: [
                IconButton(
                  icon: Icon(Icons.search, color: theme.primario()),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => Busqueda()),
                    );
                  },
                ),
                IconButton(
                  icon: CircleAvatar(
                    backgroundColor: Colors.blue[50],
                    backgroundImage: const AssetImage('assets/images/amlo.jpg'),
                    radius: 18,
                  ),
                  onPressed: () {
                    // Aquí podrías ir al perfil si quieres
                  },
                ),
              ],
            ),
          ],
        ),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: user == null
            ? const Center(
          child: Text(
            'Inicia sesión para ver tus notificaciones',
            style: TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
        )
            : Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Texto(
                text: 'Notificaciones',
                fontSize: 24,
              ),
            ),
            const SizedBox(height: 10),

            // ====== LISTA DE NOTIFICACIONES USANDO EL SERVICE ======
            Expanded(
              child: StreamBuilder<
                  QuerySnapshot<Map<String, dynamic>>>(
                stream: NotificationLogService.instance
                    .streamForCurrentUser(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(
                      child: Text(
                        'Ocurrió un error al cargar tus notificaciones',
                        style: TextStyle(fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    );
                  }

                  if (snapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  final docs = snapshot.data?.docs ?? [];

                  if (docs.isEmpty) {
                    return const Center(
                      child: Text(
                        'Aún no tienes notificaciones',
                        style: TextStyle(fontSize: 14),
                      ),
                    );
                  }

                  return ListView.separated(
                    itemCount: docs.length,
                    separatorBuilder: (_, __) =>
                    const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final data = docs[index].data();

                      final title =
                      (data['title'] ?? 'Notificación').toString();
                      final body =
                      (data['body'] ?? '').toString();
                      final createdAt =
                      data['createdAt'] as Timestamp?;
                      final read =
                      (data['read'] ?? false) as bool;

                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: read
                              ? Colors.white
                              : theme.secundario().withOpacity(0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: theme.secundario().withOpacity(0.4),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            Icon(
                              read
                                  ? Icons.notifications_none
                                  : Icons.notifications_active_rounded,
                              color: theme.primario(),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  if (body.isNotEmpty)
                                    Text(
                                      body,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _formatDate(createdAt),
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            const SizedBox(height: 16),

            SimpleButton(
              title: "Regresar",
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MenuPage(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
