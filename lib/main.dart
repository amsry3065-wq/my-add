// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';

// شاشاتك
import 'package:myadds/screen/splash_screen.dart';
import 'package:myadds/screen/welcome_screen.dart';
import 'package:myadds/screen/auth/login_screen.dart';
import 'package:myadds/screen/auth/registration_screen.dart';
import 'package:myadds/screen/auth/verify_email_screen.dart';
import 'package:myadds/screen/home_screen.dart';
import 'package:myadds/screen/search_screen.dart';
import 'package:myadds/screen/business_management_screen.dart';
import 'package:myadds/screen/messages_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
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
      home: const SplashScreen(), // ← أول شاشة
      routes: {
        '/welcome': (_) => const WelcomeScreen(),
        '/login': (_) => const LoginScreen(),
        '/register': (_) => const RegistrationScreen(),
        '/verify': (_) => const VerifyEmailScreen(),

        // ✅ خلي /home تفتح الصفحة الرئيسية ذات التبويبات
        '/home': (_) => const HomeScreen(),

        '/splash': (_) => const SplashScreen(),
        '/search': (_) => const SearchScreen(),

        // ✅ Route للرسائل
        '/messages': (_) => const MessagesScreen(),

        '/owner/manage': (_) => const BusinessManagementScreen(),
      },
    );
  }
}
