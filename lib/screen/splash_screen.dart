// lib/screen/splash_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/brand.dart';
import 'welcome_screen.dart'; // ← انتقل لهذه الشاشة بعد 3 ثوانٍ

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();

    // أنيميشن نبض للشعار
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _scale = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    // بعد 3 ثوانٍ: انتقل لواجهة الترحيب
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Brand.black,
        body: SafeArea(
          child: Center(
            child: _LogoPulse(),
          ),
        ),
      ),
    );
  }
}

class _LogoPulse extends StatelessWidget {
  const _LogoPulse();

  @override
  Widget build(BuildContext context) {
    final state = context.findAncestorStateOfType<_SplashScreenState>()!;
    return ScaleTransition(
      scale: state._scale,
      child: Image.asset(
        'assets/images/logo.png', // ← ضع شعارك هنا وتأكد من pubspec.yaml
        width: 110,
        fit: BoxFit.contain,
      ),
    );
  }
}
