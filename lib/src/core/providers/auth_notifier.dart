import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

class AuthNotifier extends ChangeNotifier {
  User? _user;
  User? get user => _user;

  late final StreamSubscription<User?> _authSubscription;

  AuthNotifier() {
    // Escuchamos userChanges() en lugar de authStateChanges()
    // para que también detecte cambios como la verificación de email.
    _authSubscription = FirebaseAuth.instance
        .userChanges()
        .listen(_onAuthStateChanged);
  }

  void _onAuthStateChanged(User? user) {
    _user = user;
    notifyListeners(); 
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }
}