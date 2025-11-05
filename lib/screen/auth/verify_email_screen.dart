import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../home_screen.dart'; // عدّل المسار إذا اختلف عندك

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  bool _isVerified = false;
  bool _sending = false;

  // Throttle لإعادة الإرسال
  DateTime? _nextSendAt;
  Timer? _poll;

  // ألوان وهوية بسيطة على ستايل تيك توك
  static const Color _bg = Colors.black;
  static const Color _card = Color(0xFF111111);
  static const Color _muted = Color(0xFF9E9E9E);
  static const Color _white = Colors.white;
  static const Color _tiktokRed = Color(0xFFFE2C55);

  @override
  void initState() {
    super.initState();
    _checkVerification();
    // Polling كل 4 ثواني لالتقاط التحقق تلقائيًا بعد فتح الرابط
    _poll = Timer.periodic(const Duration(seconds: 4), (_) => _checkVerification());
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _checkVerification() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await user.reload();
    final verified = FirebaseAuth.instance.currentUser?.emailVerified ?? false;

    if (!mounted) return;
    setState(() => _isVerified = verified);

    if (verified) {
      // تحديث مطالِبات التوكن اختياريًا لو بتعتمد على email_verified في القواعد
      await user.getIdToken(true);
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }

  String _mapAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'too-many-requests':
        return 'محاولات كثيرة خلال وقت قصير. انتظر قليلًا ثم جرّب مجددًا.';
      case 'network-request-failed':
        return 'خطأ في الشبكة. تأكد من الاتصال بالإنترنت.';
      case 'user-not-found':
        return 'لا يوجد مستخدم مسجّل حاليًا.';
      case 'user-disabled':
        return 'تم تعطيل هذا الحساب.';
      default:
        return 'تعذّر الإرسال: ${e.code}';
    }
  }

  int _secondsLeft() {
    if (_nextSendAt == null) return 0;
    final now = DateTime.now();
    return now.isBefore(_nextSendAt!) ? _nextSendAt!.difference(now).inSeconds : 0;
  }

  Future<void> _resendEmail() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _toast('لا يوجد مستخدم مسجّل دخولًا.');
      return;
    }

    // Throttle 45 ثانية
    final left = _secondsLeft();
    if (left > 0) {
      _toast('انتظر $left ثانية قبل إعادة الإرسال.');
      return;
    }

    setState(() => _sending = true);
    try {
      // لغة الرسائل
      await FirebaseAuth.instance.setLanguageCode('ar');

      await user.sendEmailVerification();
      _nextSendAt = DateTime.now().add(const Duration(seconds: 45));
      _toast('تم إرسال رسالة تحقق جديدة. تحقق من البريد/Spam.');
    } on FirebaseAuthException catch (e) {
      _toast(_mapAuthError(e));
    } catch (e) {
      _toast('حدث خطأ غير متوقع: $e');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final left = _secondsLeft();

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        foregroundColor: _white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'تأكيد البريد الإلكتروني',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: Center(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: _isVerified
              ? const SizedBox(
            height: 48,
            width: 48,
            child: CircularProgressIndicator.adaptive(
              valueColor: AlwaysStoppedAnimation<Color>(_tiktokRed),
              backgroundColor: Colors.white24,
            ),
          )
              : Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _card,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white12),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black54,
                      blurRadius: 20,
                      spreadRadius: 2,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // أيقونة ستايل تيك توك
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.06),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: const Icon(
                        Icons.mark_email_unread_rounded,
                        color: _tiktokRed,
                        size: 36,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'افتح بريدك الإلكتروني',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'أرسلنا رابط تحقق إلى بريدك. بعد الضغط على الرابط، سيتم اكتشاف التحقق تلقائيًا أو اضغط «تم التحقق».',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: _muted,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // زر أساسي – تم التحقق
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _checkVerification,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _tiktokRed,
                          foregroundColor: _white,
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        child: const Text('تم التحقق'),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // زر آوتلاين – إعادة الإرسال مع عداد تبريد
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: (_sending || left > 0) ? null : _resendEmail,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.white24),
                          foregroundColor: (_sending || left > 0) ? Colors.white38 : _white,
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (_sending) ...[
                              const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation(_white),
                                ),
                              ),
                              const SizedBox(width: 10),
                            ] else if (left > 0) ...[
                              const Icon(Icons.timer_outlined, size: 18),
                              const SizedBox(width: 8),
                              Text('أعد الإرسال خلال ${left}s'),
                            ] else ...[
                              const Icon(Icons.refresh_rounded, size: 18),
                              const SizedBox(width: 8),
                              const Text('إعادة إرسال الرسالة'),
                            ],
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),
                    Text(
                      'تأكد من مجلد Spam/الرسائل غير المرغوب فيها.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white30,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
