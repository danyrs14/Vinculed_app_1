import 'package:flutter/material.dart';
import 'package:vinculed_app_1/src/core/controllers/theme_controller.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override

  void initState() {
    super.initState();

    Future.delayed(const Duration(seconds: 20), () {
      if (!mounted) return;
    });
  }

  Widget build(BuildContext context) {
    final theme = ThemeController.instance;
    return Scaffold(
      body: SafeArea(
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            color: theme.primario(),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'OdaTalent',
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins',
                  color: theme.background(),
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Image.asset(
                  'assets/images/graduate.png',
                  width: MediaQuery.of(context).size.width * 0.8,
                  fit: BoxFit.cover,
                ),
              ),
              SizedBox(height: 60),
              Image.asset(
                'assets/images/escudoESCOM.png',
                width: 120,
              ),
              SizedBox(height: 8),
              Text(
                'TT 2025-B003',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: theme.background(),
                ),
              ),
              SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}