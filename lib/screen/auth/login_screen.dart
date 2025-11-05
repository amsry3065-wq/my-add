import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:myadds/screen/auth/forgot_password_screen.dart';
import 'package:myadds/screen/auth/registration_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // -------------------- تسجيل الدخول بالبريد --------------------
  Future<void> _signInWithEmail() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تسجيل الدخول بنجاح ✅')),
      );
      Navigator.pop(context); // ← يرجع بعد تسجيل الدخول الناجح
    } on FirebaseAuthException catch (e) {
      _showSnack(_mapAuthError(e));
    } catch (e) {
      _showSnack('حدث خطأ غير متوقع: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // -------------------- واجهة المستخدم --------------------
  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          backgroundColor: Colors.grey[50],
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.deepPurple),
            onPressed: () => Navigator.pop(context), // زر الرجوع للبوب-أب
            tooltip: 'رجوع',
          ),
          title: const Text(
            "تسجيل الدخول",
            style: TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          centerTitle: true,
        ),
        body: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    const Icon(Icons.lock_outline, size: 64, color: Colors.deepPurple),
                    const SizedBox(height: 16),

                    // البريد الإلكتروني
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration:
                      _input('البريد الإلكتروني', const Icon(Icons.email)),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'يجب إدخال البريد الإلكتروني';
                        }
                        final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                            .hasMatch(v.trim());
                        if (!ok) return 'أدخل بريدًا إلكترونيًا صالحًا';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // كلمة المرور
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: _input(
                        'كلمة المرور',
                        const Icon(Icons.lock),
                        suffix: IconButton(
                          onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword),
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return 'يجب إدخال كلمة المرور';
                        }
                        if (v.length < 6) {
                          return 'كلمة المرور يجب أن تحتوي على 6 أحرف على الأقل';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),

                    // نسيت كلمة المرور
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const ForgotPasswordScreen(),
                            ),
                          );
                        },
                        child: const Text(
                          "نسيت كلمة المرور؟",
                          style: TextStyle(
                            color: Colors.deepPurple,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // زر تسجيل الدخول
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _loading ? null : _signInWithEmail,
                        child: const Text(
                          "تسجيل الدخول",
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),

                    // الانتقال إلى التسجيل
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("ليس لديك حساب؟ "),
                        TextButton(
                          style: TextButton.styleFrom(padding: EdgeInsets.zero),
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => const RegistrationScreen()),
                          ),
                          child: const Text('أنشئ حسابًا جديدًا'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            if (_loading)
              Container(
                color: Colors.black.withOpacity(0.15),
                child: const Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }

  // -------------------- أدوات مساعدة --------------------
  InputDecoration _input(String label, Icon prefix, {Widget? suffix}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: prefix,
      suffixIcon: suffix,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  void _showSnack(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  String _mapAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'البريد الإلكتروني غير صالح.';
      case 'user-disabled':
        return 'تم تعطيل هذا المستخدم.';
      case 'user-not-found':
        return 'لا يوجد مستخدم بهذا البريد.';
      case 'wrong-password':
        return 'كلمة المرور غير صحيحة، حاول مجددًا.';
      case 'too-many-requests':
        return 'محاولات كثيرة. حاول لاحقًا.';
      case 'network-request-failed':
        return 'خطأ في الاتصال. تحقق من الإنترنت.';
      default:
        return 'خطأ في تسجيل الدخول (${e.code}).';
    }
  }
}
