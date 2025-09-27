import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// Candidato
import 'package:vinculed_app_1/src/ui/web_app/candidato/add_experiencia.dart';
import 'package:vinculed_app_1/src/ui/web_app/candidato/ayuda.dart';
import 'package:vinculed_app_1/src/ui/web_app/candidato/buscar_vacantes.dart';
import 'package:vinculed_app_1/src/ui/web_app/candidato/experiencias.dart';
import 'package:vinculed_app_1/src/ui/web_app/candidato/inicio.dart';
import 'package:vinculed_app_1/src/ui/web_app/candidato/messages.dart';
import 'package:vinculed_app_1/src/ui/web_app/candidato/perfil_candidato.dart';
import 'package:vinculed_app_1/src/ui/web_app/candidato/postulaciones.dart';
import 'package:vinculed_app_1/src/ui/web_app/candidato/vacante.dart';

// Generales
import 'package:vinculed_app_1/src/ui/web_app/dashboard.dart';
import 'package:vinculed_app_1/src/ui/web_app/login.dart';
import 'package:vinculed_app_1/src/ui/web_app/not_found_page.dart';
import 'package:vinculed_app_1/src/ui/web_app/signin.dart';
import 'package:vinculed_app_1/src/ui/web_app/signin_rec.dart';

// Reclutador
import 'package:vinculed_app_1/src/ui/web_app/reclutador/inicio.dart';

class AdminApp extends StatefulWidget {
  const AdminApp({super.key});

  @override
  State<AdminApp> createState() => _AdminAppState();
}

class _AdminAppState extends State<AdminApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();

    _router = GoRouter(
      // Hace que al iniciar vaya directo al dashboard
      initialLocation: '/dashboard',

      // Opcional: si alguien entra a '/', lo redirigimos al dashboard
      routes: [
        GoRoute(
          path: '/',
          redirect: (context, state) => '/dashboard',
        ),

        // ----- Generales -----
        GoRoute(
          path: '/dashboard',
          builder: (context, state) => const Dashboard(),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginPageWeb(),
        ),
        GoRoute(
          path: '/signin',
          builder: (context, state) => const RegisterPageWeb(),
        ),
        GoRoute(
          path: '/signin_rec',
          builder: (context, state) => const RegisterPageWebRec(),
        ),

        // ----- Candidato -----
        GoRoute(
          path: '/inicio_cand',
          builder: (context, state) => const HomeRegisteredPage(),
        ),
        GoRoute(
          path: '/busqueda_job',
          builder: (context, state) => const JobSearchPage(),
        ),
        GoRoute(
          path: '/vacante_job',
          builder: (context, state) => const JobDetailPage(),
        ),
        GoRoute(
          path: '/perfil_cand',
          builder: (context, state) => const UserProfilePage(),
        ),
        GoRoute(
          path: '/mis_postulaciones',
          builder: (context, state) => const MyApplicationsPage(),
        ),
        GoRoute(
          path: '/messages',
          builder: (context, state) => const MessagesPage(),
        ),
        GoRoute(
          path: '/experiencias',
          builder: (context, state) => const ExperiencesPage(),
        ),
        GoRoute(
          path: '/experiencias_create',
          builder: (context, state) => const CreateExperiencePage(),
        ),
        GoRoute(
          path: '/faq',
          builder: (context, state) => const FaqPage(),
        ),

        // ----- Reclutador -----
        GoRoute(
          path: '/inicio_rec',
          builder: (context, state) => const HomeRecruiterPage(),
        ),

        // (Opcional) Ruta explícita de 404 para link directo
        GoRoute(
          path: '/404',
          builder: (context, state) => const NotFoundPage(),
        ),
      ],

      // Usa errorBuilder (API reciente). Si tu versión requiere errorPageBuilder, deja el tuyo.
      errorBuilder: (context, state) => const NotFoundPage(),

      debugLogDiagnostics: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'TT 2025-B003',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
      ),
      routerConfig: _router,
    );
  }
}
