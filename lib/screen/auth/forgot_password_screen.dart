import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  bool _sending = false;
/// ff
  // فحص بسيط لصيغة الإيميل (واجهة فقط)
  final _emailReg = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$', caseSensitive: false);

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  bool get _isValidEmail => _emailReg.hasMatch(_email.text.trim());

  Future<void> _onSendCode() async {
    if (!_formKey.currentState!.validate()) return;

    // إخفاء الكيبورد
    FocusScope.of(context).unfocus();

    setState(() => _sending = true);
    try {
      final email = _email.text.trim();

      // خلي رسائل البريد تطلع بالعربي
      await FirebaseAuth.instance.setLanguageCode('ar');

      // الطلب الفعلي إلى Firebase
      // موبايل والويب: الإعداد الافتراضي يكفي لمعظم الحالات
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم إرسال رابط إعادة التعيين إلى $email ✅')),
      );

      // رجوع للشاشة السابقة (اختياري)
      Navigator.maybePop(context);
    } on FirebaseAuthException catch (e) {
      final msg = switch (e.code) {
        'invalid-email' => 'عنوان البريد الإلكتروني غير صالح.',
        'user-not-found' => 'لا يوجد مستخدم بهذا البريد.',
        'network-request-failed' => 'خطأ في الشبكة. تحقّق من الاتصال بالإنترنت.',
        'too-many-requests' => 'محاولات كثيرة خلال وقت قصير. انتظر قليلًا وحاول مجددًا.',
      // أخطاء ActionCodeSettings تظهر عادة عند تمرير إعدادات مخصصة؛ نحن لا نمررها هنا لتفاديها
        _ => 'فشل إرسال رسالة إعادة التعيين (${e.code}).',
      };
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('خطأ غير متوقع: $e')));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Directionality(
      textDirection: TextDirection.rtl, // ← واجهة عربية
      child: Scaffold(
        appBar: AppBar(title: const Text('نسيت كلمة المرور')),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
              child: Card(
                elevation: 2,
                clipBehavior: Clip.antiAlias,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.mark_email_read_outlined, size: 48),
                        const SizedBox(height: 12),
                        Text(
                          'إعادة تعيين كلمة المرور',
                          style: theme.textTheme.titleLarge,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'أدخل بريدك الإلكتروني لإرسال رابط إعادة تعيين كلمة المرور.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),

                        // البريد الإلكتروني
                        TextFormField(
                          controller: _email,
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.emailAddress,
                          autofillHints: const [AutofillHints.email],
                          textInputAction: TextInputAction.done,
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            hintText: 'أدخل بريدك الإلكتروني',
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          validator: (value) {
                            final v = (value ?? '').trim();
                            if (v.isEmpty) return 'يرجى إدخال البريد الإلكتروني';
                            if (!_emailReg.hasMatch(v)) return 'البريد الإلكتروني غير صالح';
                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        // زر الإرسال
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: (_sending || !_isValidEmail) ? null : _onSendCode,
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _sending
                                ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                                : const Text('إرسال الرابط'),
                          ),
                        ),
                        const SizedBox(height: 4),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
