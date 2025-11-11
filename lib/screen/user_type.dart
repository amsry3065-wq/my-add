import 'package:flutter/material.dart';
import '../screen/home/user_home_screen.dart'; // شاشة المستخدم العادي
import '../screen/business_management_screen.dart'; // شاشة مالك الشاليه
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// هذه الشاشة تتحقق من نوع المستخدم بعد تسجيل الدخول
/// وتوجهه مباشرة للشاشة المناسبة:
/// - UserHomeScreen للمستخدم العادي
/// - BusinessManagementScreen للمالك (Owner)
class UserType extends StatefulWidget {
  const UserType({super.key});

  @override
  State<UserType> createState() => _UserTypeState();
}

class _UserTypeState extends State<UserType> {
  @override
  void initState() {
    super.initState();
    _checkUserType(); // التحقق مباشرة عند فتح الشاشة
  }

  /// ==========================================================
  /// دالة لفحص نوع المستخدم من Firebase Firestore
  /// ==========================================================
  Future<void> _checkUserType() async {
    try {
      // جلب المستخدم الحالي من Firebase Auth
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        // لم يتم تسجيل الدخول بعد
        print("⚠️ لم يتم تسجيل الدخول بعد.");
        return;
      }

      // جلب المستند الخاص بالمستخدم من مجموعة "users"
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final data = doc.data(); // البيانات كماب
      // الحصول على النوع، إذا غير موجود يعتبر 'user' افتراضي
      final userType = (data?['userType'] ?? 'user').toString().toLowerCase();

      print("DEBUG: نوع المستخدم = $userType"); // ديبغ

      if (!mounted) return; // حماية لو الشاشة اتقفلت قبل انتهاء العملية

      // ==========================================================
      // التوجيه حسب نوع المستخدم
      // ==========================================================
      if (userType == 'owner') {
        // إذا هو Owner → يفتح شاشة إدارة الأعمال
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const BusinessManagementScreen(),
          ),
        );
      } else {
        // أي مستخدم عادي → يفتح الشاشة الرئيسية للمستخدم
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const UserHomeScreen(),
          ),
        );
      }
    } catch (e, st) {
      // التعامل مع أي خطأ أثناء جلب البيانات
      print("❌ خطأ أثناء جلب نوع المستخدم: $e\n$st");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('حدث خطأ أثناء التحقق من نوع المستخدم.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // شاشة انتظار أثناء تحميل بيانات المستخدم
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
