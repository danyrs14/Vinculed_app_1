import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:vinculed_app_1/src/ui/pages/splashscreen.dart';
import 'package:vinculed_app_1/src/ui/web_app/index.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return kIsWeb
        ? const AdminApp()
        : MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(fontFamily: 'Montserrat'),
      home: SplashScreen(),
    );
  }
}
