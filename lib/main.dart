// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'firebase_options.dart';

// شاشاتك
import 'package:myadds/screen/welcome_screen.dart';
import 'package:myadds/screen/auth/login_screen.dart';
import 'package:myadds/screen/auth/registration_screen.dart';
import 'package:myadds/screen/auth/verify_email_screen.dart';
import 'package:myadds/screen/home_screen.dart';       // تأكد من المسار الصحيح
import 'package:myadds/screen/splash_screen.dart';     // لو بدك لودينغ/أنيميشن مؤقت

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'إعلاناتي',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        scaffoldBackgroundColor: Colors.grey[50],
      ),
      home: const AuthGate(),
      routes: {
        '/welcome': (_) => const WelcomeScreen(),
        '/login': (_) => const LoginScreen(),
        '/register': (_) => const RegistrationScreen(),
        '/verify': (_) => const VerifyEmailScreen(),
        '/home': (_) => const HomeScreen(),
        '/splash': (_) => const SplashScreen(),
      },
    );
  }
}

/// يقرّر الوجهة حسب حالة المستخدم
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  bool _isPasswordProvider(User u) {
    // true إذا كان داخل عبر البريد/كلمة المرور
    return u.providerData.any((p) => p.providerId == 'password');
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snap) {
        // حالة انتظار
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snap.data;

        // غير مسجل دخول
        if (user == null) {
          return const WelcomeScreen();
        }

        // مسجل دخول بمزوّد البريد/كلمة مرور ولم يفعّل بريده بعد
        if (_isPasswordProvider(user) && !(user.emailVerified)) {
          return const VerifyEmailScreen();
        }

        // مسجل ومفعّل (أو مسجل بجوجل الذي يكون متحقق تلقائيًا)
        return const HomeScreen();
      },
    );
  }
}
