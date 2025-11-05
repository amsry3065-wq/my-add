import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../home_screen.dart';                // عدّل المسارات حسب مشروعك
import 'login_screen.dart';
import 'verify_email_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  bool _isPasswordProvider(User u) {
    return u.providerData.any((p) => p.providerId == 'password');
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snap.data;

        // غير مسجل دخول
        if (user == null) return const LoginScreen();

        // مسجل بالبريد/كلمة مرور ولم يفعّل البريد بعد
        if (_isPasswordProvider(user) && !user.emailVerified) {
          return const VerifyEmailScreen();
        }

        // مسجل ومُفعّل (أو مسجل بجوجل)
        return const HomeScreen();
      },
    );
  }
}
