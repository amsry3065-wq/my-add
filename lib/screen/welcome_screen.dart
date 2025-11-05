// lib/screen/welcome_screen.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/brand.dart';
import '../widget/buttons.dart';
import 'auth/login_screen.dart';
import 'auth/registration_screen.dart';
import 'home_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final cardW = w > 440 ? 440.0 : w - 48;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Brand.black,
        body: Stack(
          children: [
            // خلفية خفيفة (توهج سيان/فوشيا)
            Positioned(
              top: -80, left: -40,
              child: _glow(const Color(0x5525F4EE), 240),
            ),
            Positioned(
              bottom: -60, right: -30,
              child: _glow(const Color(0x55FE2C55), 260),
            ),

            // المحتوى
            Center(
              child: Container(
                width: cardW,
                constraints: const BoxConstraints(minHeight: 320),
                decoration: BoxDecoration(
                  color: Brand.surface.withOpacity(.66),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: Colors.white.withOpacity(.06)),
                  boxShadow: const [
                    BoxShadow(blurRadius: 28, color: Colors.black54, offset: Offset(0, 10)),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // رأس: لوجو + عنوان
                          Row(
                            children: [
                              _Logo(),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ShaderMask(
                                  shaderCallback: (r) => Brand.gradient.createShader(r),
                                  child: Text(
                                    'اعلاناتي',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.cairo(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                      letterSpacing: .2,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // سطر ترحيبي جديد
                          Text(
                            'مرحبًا بك في تطبيق إعلاناتي — أول تطبيق شاليهات في فلسطين',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.cairo(
                              color: Colors.white,
                              fontSize: 14.5,
                              fontWeight: FontWeight.w600,
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 6),

                          // توجيه بسيط
                          Text(
                            'اختر طريقة المتابعة',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.cairo(
                              color: Colors.white70,
                              fontSize: 13.5,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 18),

                          // أزرار رئيسية
                          FilledGradientButton(
                            label: 'تسجيل الدخول',
                            icon: Icons.login_rounded,
                            onTap: () async {
                              HapticFeedback.selectionClick();
                              await Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const LoginScreen()),
                              );
                            },
                          ),
                          const SizedBox(height: 10),

                          FilledGradientButton(
                            label: 'إنشاء حساب جديد',
                            icon: Icons.person_add_alt_1_rounded,
                            textColor: Colors.black,
                            gradient: const LinearGradient(
                              colors: [Brand.cyan, Color(0xFF8AF7FF)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            onTap: () async {
                              HapticFeedback.selectionClick();
                              await Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const RegistrationScreen()),
                              );
                            },
                          ),
                          const SizedBox(height: 14),

                          // (تم حذف أزرار Google و Apple بناءً على طلبك)

                          OutlineNeonButton(
                            label: 'متابعة كضيف',
                            icon: Icons.visibility_rounded,
                            onTap: () {
                              HapticFeedback.selectionClick();
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (_) => const HomeScreen()),
                              );
                            },
                          ),
                          const SizedBox(height: 6),

                          TextButton(
                            onPressed: () {
                              HapticFeedback.selectionClick();
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (_) => const HomeScreen()),
                              );
                            },
                            child: Text(
                              'تخطي الآن',
                              style: GoogleFonts.cairo(
                                color: Colors.white70,
                                decoration: TextDecoration.underline,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _glow(Color c, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: c, blurRadius: 80, spreadRadius: 40),
        ],
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // توهج خلفي
        Container(
          width: 46, height: 46,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: Brand.red.withOpacity(.35), blurRadius: 20, spreadRadius: 2),
              BoxShadow(color: Brand.cyan.withOpacity(.35), blurRadius: 20, spreadRadius: 2, offset: const Offset(4, 2)),
            ],
          ),
        ),
        // دائرة متدرجة + أيقونة
        Container(
          width: 46, height: 46,
          decoration: const BoxDecoration(shape: BoxShape.circle, gradient: Brand.gradient),
          child: const Icon(Icons.play_arrow_rounded, color: Colors.white),
        ),
      ],
    );
  }
}
