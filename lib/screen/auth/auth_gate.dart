import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// مسارات نسبية حسب هيكلة مشروعك (أنت داخل: lib/screen/auth/)
import '../home_screen.dart';
import '../business_management_screen.dart';
import 'login_screen.dart';
import 'verify_email_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  bool _isPasswordProvider(User u) {
    // true إذا داخل ببريد/كلمة مرور (مش Google)
    return u.providerData.any((p) => p.providerId == 'password');
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snap) {
        // بانتظار حالة الأوث
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snap.data;

        // غير مسجل دخول → شاشة اللوجين
        if (user == null) return const LoginScreen();

        // مسجّل بالبريد/كلمة مرور ولم يفعّل البريد بعد
        if (_isPasswordProvider(user) && !user.emailVerified) {
          return const VerifyEmailScreen();
        }

        // مسجل ومفعّل → نقرأ userType من Firestore ونوجّه
        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .snapshots(),
          builder: (context, userSnap) {
            if (userSnap.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            if (userSnap.hasError) {
              // في حال صار خطأ بالشبكة/الصلاحيات
              return const Scaffold(
                body: Center(child: Text('تعذر تحميل بيانات المستخدم')),
              );
            }

            final data = userSnap.data?.data() ?? {};
            final type = (data['userType'] ?? 'user').toString();

            // صاحب شاليه → شاشة إدارة الشاليه
            if (type == 'owner') {
              return const BusinessManagementScreen();
            }

            // مستخدم عادي → الهوم
            return const HomeScreen();
          },
        );
      },
    );
  }
}
