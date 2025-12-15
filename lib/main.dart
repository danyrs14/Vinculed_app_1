import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:vinculed_app_1/src/ui/web_app/index_stub.dart'
if (dart.library.js_interop)
'package:vinculed_app_1/src/ui/web_app/index.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:provider/provider.dart';
import 'package:vinculed_app_1/src/core/providers/user_provider.dart';
import 'package:vinculed_app_1/src/ui/pages/transicionInicial.dart';
import 'package:vinculed_app_1/src/core/controllers/theme_controller.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:vinculed_app_1/src/core/services/notification_service.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  await NotificationService.instance.initPush();

  runApp(
    ChangeNotifierProvider(
      create: (context) => UserDataProvider(),
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final themeCtrl = ThemeController.instance;
    return ValueListenableBuilder<bool>(
      valueListenable: themeCtrl.brightness,
      builder: (_, isLight, __) {
        final brightness = isLight ? Brightness.light : Brightness.dark;
        final primary = themeCtrl.primario();
        final secondary = themeCtrl.secundario();
        final background = themeCtrl.background();
        final fuente = themeCtrl.fuente();
        final scheme = ColorScheme(
          brightness: brightness,
          primary: primary,
          onPrimary: fuente,
          secondary: secondary,
          onSecondary: fuente,
          error: Colors.red,
          onError: Colors.white,
          background: background,
          onBackground: fuente,
          surface: background,
          onSurface: fuente,
        );
        final globalTheme = ThemeData(
          useMaterial3: true,
          fontFamily: 'Montserrat',
          colorScheme: scheme,
          scaffoldBackgroundColor: background,
          primaryColor: primary,
          cardTheme: CardThemeData(
            color: background,
            surfaceTintColor: Colors.transparent,
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          appBarTheme: AppBarTheme(
            backgroundColor: background,
            elevation: 0,
            iconTheme: IconThemeData(color: primary),
            titleTextStyle: TextStyle(
              color: fuente,
              fontSize: 18,
              fontWeight: FontWeight.w600,
              fontFamily: 'Montserrat',
            ),
          ),
          textTheme: ThemeData.light().textTheme.apply(
            fontFamily: 'Montserrat',
            bodyColor: fuente,
            displayColor: fuente,
          ),
          iconTheme: IconThemeData(color: fuente),
          dividerColor: secondary.withOpacity(.3),
        );
        return kIsWeb
            ? const AdminApp()
            : MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: globalTheme,
          home: TrasicionPage(),
        );
      },
    );
  }
}
