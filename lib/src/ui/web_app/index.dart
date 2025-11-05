import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:vinculed_app_1/src/core/providers/auth_notifier.dart';
import 'package:vinculed_app_1/src/core/providers/user_provider.dart';

// Candidato
import 'package:vinculed_app_1/src/ui/web_app/candidato/add_experiencia.dart';
import 'package:vinculed_app_1/src/ui/web_app/candidato/ayuda.dart';
import 'package:vinculed_app_1/src/ui/web_app/candidato/buscar_vacantes.dart';
import 'package:vinculed_app_1/src/ui/web_app/candidato/experiencias.dart';
import 'package:vinculed_app_1/src/ui/web_app/candidato/inicio.dart';
import 'package:vinculed_app_1/src/ui/web_app/candidato/messages.dart';
import 'package:vinculed_app_1/src/ui/web_app/candidato/perfil_candidato.dart';
import 'package:vinculed_app_1/src/ui/web_app/candidato/postulaciones.dart';
import 'package:vinculed_app_1/src/ui/web_app/candidato/preferencias.dart';
import 'package:vinculed_app_1/src/ui/web_app/candidato/vacante.dart';
import 'package:vinculed_app_1/src/ui/web_app/candidato/lector_qr.dart';

// Generales
import 'package:vinculed_app_1/src/ui/web_app/dashboard.dart';
import 'package:vinculed_app_1/src/ui/web_app/login.dart';
import 'package:vinculed_app_1/src/ui/web_app/not_found_page.dart';
import 'package:vinculed_app_1/src/ui/web_app/reclutador/ayuda_rec.dart';
import 'package:vinculed_app_1/src/ui/web_app/reclutador/crear_vacante.dart';
import 'package:vinculed_app_1/src/ui/web_app/reclutador/messages_rec.dart';
import 'package:vinculed_app_1/src/ui/web_app/reclutador/mis_vacantes.dart';
import 'package:vinculed_app_1/src/ui/web_app/reclutador/perfil_reclutador.dart';
import 'package:vinculed_app_1/src/ui/web_app/reclutador/postulaciones.dart';
import 'package:vinculed_app_1/src/ui/web_app/signin.dart';
import 'package:vinculed_app_1/src/ui/web_app/signin_rec.dart';
import 'package:vinculed_app_1/src/ui/web_app/recuperar_password.dart';
import 'package:vinculed_app_1/src/ui/web_app/verificarEmailWeb.dart';
import 'package:vinculed_app_1/src/ui/web_app/despachador_inicio.dart';

// Reclutador
import 'package:vinculed_app_1/src/ui/web_app/reclutador/inicio.dart';

class AdminApp extends StatefulWidget {
  const AdminApp({super.key});

  @override
  State<AdminApp> createState() => _AdminAppState();
}

class _AdminAppState extends State<AdminApp> {
  late final GoRouter _router;
  late final AuthNotifier _authNotifier;

  @override
  void initState() {
    super.initState();

    _authNotifier = AuthNotifier();

    _router = GoRouter(
      // Hace que al iniciar vaya directo al dashboard
      initialLocation: '/dashboard',

      refreshListenable: _authNotifier,

      redirect: (BuildContext context, GoRouterState state) {
        if (_authNotifier.isInitializing) {
          // Aún no sabemos el estado de auth, no hagas nada.
          // Esto evita el salto al /dashboard en F5.
          return null; 
        }

        final User? user = _authNotifier.user;
        final bool isLoggedIn = user != null;
        final bool isVerified = user?.emailVerified ?? false;

        final String location = state.matchedLocation;

        // Las que se puede acceder sin login
        const publicRoutes = [
          '/dashboard', '/login', '/lector_qr', '/signin', 
          '/signin_rec', '/recover_password', '/404'
        ];
        
        final isGoingToPublic = publicRoutes.contains(location);

        if (!isLoggedIn) {
          return isGoingToPublic ? null : '/dashboard';
        }

        const verifyRoute = '/verificar_email';
        if (!isVerified ) {
          return location == verifyRoute ? null : verifyRoute;
        }

        const authRoutes = ['/login', '/lector_qr', '/signin', '/signin_rec', verifyRoute];
        if (authRoutes.contains(location)) {
          return '/inicio';
        }
        
        // No hay redirección
        return null;
      },

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
          path: '/lector_qr',
          builder: (context, state) => const LectorQRPageWeb(),
        ),
        GoRoute(
          path: '/signin',
          builder: (context, state) {
            // Extrae el nombre del alumno del parámetro 'extra'
            final nombre = state.extra as String?;
            return RegisterPageWeb(nombre: nombre);
          },
          redirect: (context, state) {
            if (state.extra == null || state.extra is! String) {
              return '/lector_qr';
            }
            return null;
          },
        ),
        GoRoute(
          path: '/signin_rec',
          builder: (context, state) => const RegisterPageWebRec(),
        ),
        GoRoute(
          path: '/recover_password',
          builder: (context, state) => const RecuperarPasswordPageWeb(),
        ),
        GoRoute(
          path: '/verificar_email',
          builder: (context, state) => const verificarEmailPage(),
        ),
        GoRoute(
          path: '/inicio',
          builder: (context, state) => const InicioPage(),
        ),
        // -----admin --------
        GoRoute(
          path: '/admin',
          // Este redirect protege TODAS las rutas hijas
          redirect: (context, state) {
            final role = context.read<UserDataProvider>().rol;

            if (role == null) {
              // Se manda a cargar
              return '/inicio';
            }
            if (role != 'admin') {
              return '/404';
            }

            return null; 
          },
          // Este padre no tiene 'builder', solo agrupa a los hijos
          routes: [
            GoRoute(
              path: 'busqueda_job',
              builder: (context, state) => const JobSearchPage(),
            ),
            GoRoute(
              path: 'vacante_job',
              builder: (context, state) => const JobDetailPage(),
            ),
            GoRoute(
              path: 'perfil_cand', 
              builder: (context, state) => const UserProfilePage(),
            ),
            GoRoute(
              path: 'mis_postulaciones',
              builder: (context, state) => const MyApplicationsPage(),
            ),
            GoRoute(
              path: 'messages',
              builder: (context, state) => const MessagesPage(),
            ),
            // La ruta real será '/candidato/experiencias'
            GoRoute(
              path: 'experiencias',
              builder: (context, state) => const ExperiencesPage(),
            ),
            GoRoute(
              path: 'experiencias_create',
              builder: (context, state) => const CreateExperiencePage(),
            ),
            GoRoute(
              path: 'faq',
              builder: (context, state) => const FaqPage(),
            ),
            GoRoute(
              path: 'preferences',
              builder: (context, state) => const PreferencesPage(),
            ),
          ],
        ),
        // ----- Candidato -----
        GoRoute(
          path: '/alumno',
          // Este redirect protege TODAS las rutas hijas
          redirect: (context, state) {
            final role = context.read<UserDataProvider>().rol;

            if (role == null) {
              // Se manda a cargar
              return '/inicio';
            }
            if (role != 'alumno') {
              return '/404';
            }

            return null; 
          },
          // Este padre no tiene 'builder', solo agrupa a los hijos
          routes: [
            GoRoute(
              path: 'busqueda_job',
              builder: (context, state) => const JobSearchPage(),
            ),
            GoRoute(
              path: 'vacante_job',
              builder: (context, state) => const JobDetailPage(),
            ),
            GoRoute(
              path: 'perfil_cand', 
              builder: (context, state) => const UserProfilePage(),
            ),
            GoRoute(
              path: 'mis_postulaciones',
              builder: (context, state) => const MyApplicationsPage(),
            ),
            GoRoute(
              path: 'messages',
              builder: (context, state) => const MessagesPage(),
            ),
            // La ruta real será '/candidato/experiencias'
            GoRoute(
              path: 'experiencias',
              builder: (context, state) => const ExperiencesPage(),
            ),
            GoRoute(
              path: 'experiencias_create',
              builder: (context, state) => const CreateExperiencePage(),
            ),
            GoRoute(
              path: 'faq',
              builder: (context, state) => const FaqPage(),
            ),
            GoRoute(
              path: 'preferences',
              builder: (context, state) => const PreferencesPage(),
            ),
          ],
        ),

        // ----- Reclutador -----
        GoRoute(
          path: '/reclutador',
          // Este redirect protege TODAS las rutas hijas
          redirect: (context, state) {
            final role = context.read<UserDataProvider>().rol;

            if (role == null) {
              // Se manda a cargar
              return '/inicio';
            }
            if (role != 'reclutador') {
              return '/404';
            }

            return null; 
          },
          // Este padre no tiene 'builder', solo agrupa a los hijos
          routes: [
            GoRoute(
              path: 'new_vacancy',
              builder: (context, state) => const CreateVacancyPage(),
            ),
            GoRoute(
              path: 'my_vacancy',
              builder: (context, state) => const MyVacanciesPage(),
            ),
            GoRoute(
              path: 'postulaciones',
              builder: (context, state) => const VacancyDetailPage(),
            ),
            GoRoute(
              path: 'perfil_rec',
              builder: (context, state) => const UserProfile(),
            ),
            GoRoute(
              path: 'faq_rec',
              builder: (context, state) => const FaqPageRec(),
            ),
            GoRoute(
              path: 'msg_rec',
              builder: (context, state) => const MessagesPageRec(),
            ),
          ],
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
      title: 'OdaTalent',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
      ),
      routerConfig: _router,
    );
  }
}
