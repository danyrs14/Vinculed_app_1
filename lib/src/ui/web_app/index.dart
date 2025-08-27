import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:vinculed_app_1/src/ui/web_app/dashboard.dart';
import 'package:vinculed_app_1/src/ui/web_app/login.dart';
import 'package:vinculed_app_1/src/ui/web_app/not_found_page.dart';
import 'package:vinculed_app_1/src/ui/web_app/signin.dart';
import 'package:vinculed_app_1/src/ui/web_app/signin_rec.dart';

class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    final GoRouter router = GoRouter(
      routes: [
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
      ],
      initialLocation: '/dashboard',
      errorPageBuilder: (context, state) {
        return MaterialPage(
          child: NotFoundPage(),
        );
      },
    );

    return MaterialApp.router(
      title: 'TT 2025-B003',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
      ),
      routerConfig: router,
    );
  }
}
