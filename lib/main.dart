import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:vinculed_app_1/src/ui/pages/splashscreen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform, // importante
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner:
      false,
      theme: ThemeData(
          fontFamily: 'Montserrat'
      ),
      home: SplashScreen(),
    );
  }
}
