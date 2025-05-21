import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:vinculed_app_1/src/ui/pages/splashscreen.dart';


void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
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
