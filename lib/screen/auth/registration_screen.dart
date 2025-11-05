import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'verify_email_screen.dart';

enum UserType { user, owner } // مستخدم عادي أو صاحب شاليه

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();

  // عام
  final _first = TextEditingController();
  final _last = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  // حقول خاصة لصاحب الشاليه
  final _chaletName = TextEditingController();
  final _chaletAddress = TextEditingController();

  UserType _userType = UserType.user; // الافتراضي: مستخدم عادي
  bool _obscurePass = true;
  bool _obscureConfirm = true;
  bool _acceptTerms = false;
  bool _loading = false;

  @override
  void dispose() {
    _first.dispose();
    _last.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    _confirm.dispose();
    _chaletName.dispose();
    _chaletAddress.dispose();
    super.dispose();
  }

  // ====================== Helpers ======================

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  String _mapAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'هذا البريد مستخدم من قبل.';
      case 'invalid-email':
        return 'بريد إلكتروني غير صالح.';
      case 'weak-password':
        return 'كلمة المرور ضعيفة (6 أحرف فأكثر).';
      case 'operation-not-allowed':
        return 'تم تعطيل طريقة التسجيل هذه.';
      case 'network-request-failed':
        return 'مشكلة اتصال بالشبكة.';
      default:
        return 'خطأ (${e.code}). حاول لاحقًا.';
    }
  }

  Future<void> _createUserDoc({
    required User user,
    required String first,
    required String last,
    required String email,
    String? phone,
    required UserType type,
    String? chaletName,
    String? chaletAddress,
    bool overwriteIfExists = false,
  }) async {
    final users = FirebaseFirestore.instance.collection('users').doc(user.uid);

    final data = {
      'uid': user.uid,
      'firstName': first,
      'lastName': last,
      'email': email,
      'phone': phone ?? '',
      'userType': type.name, // 'user' or 'owner'
      if (type == UserType.owner) ...{
        'chaletName': chaletName ?? '',
        'chaletAddress': chaletAddress ?? '',
      },
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'emailVerified': user.emailVerified,
    };

    final snap = await users.get();
    if (!snap.exists || overwriteIfExists) {
      await users.set(data, SetOptions(merge: true));
    }
  }

  // ====================== Email/Password Register ======================

  Future<void> _onRegister() async {
    FocusScope.of(context).unfocus();

    // فحوصات سريعة
    if (_userType == UserType.owner) {
      if (_chaletName.text.trim().isEmpty || _chaletAddress.text.trim().length < 5) {
        _toast('يرجى إدخال اسم وعنوان الشاليه بشكل صحيح');
        return;
      }
    }
    if (!_formKey.currentState!.validate()) return;
    if (!_acceptTerms) {
      _toast('يجب الموافقة على الشروط والأحكام');
      return;
    }

    final email = _email.text.trim().toLowerCase();

    setState(() => _loading = true);
    try {
      // خلي رسائل البريد بالعربي
      await FirebaseAuth.instance.setLanguageCode('ar');

      // فحص مسبق: هل الإيميل مستعمل بأي مزوّد (حتى Google)؟
      final methods = await FirebaseAuth.instance.fetchSignInMethodsForEmail(email);
      if (methods.isNotEmpty) {
        _toast('هذا البريد مستخدم من قبل. جرّب تسجيل الدخول أو استعادة كلمة المرور.');
        return;
      }

      // إنشاء الحساب
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: _password.text,
      );

      // تحديث اسم العرض (اختياري)
      await cred.user?.updateDisplayName('${_first.text.trim()} ${_last.text.trim()}');

      // إنشاء وثيقة المستخدم في Firestore
      await _createUserDoc(
        user: cred.user!,
        first: _first.text.trim(),
        last: _last.text.trim(),
        email: email,
        phone: _phone.text.trim(),
        type: _userType,
        chaletName: _userType == UserType.owner ? _chaletName.text.trim() : null,
        chaletAddress: _userType == UserType.owner ? _chaletAddress.text.trim() : null,
      );

      // ===== إرسال التحقق (بسيطة ومضمونة على الموبايل والويب) =====
      await cred.user!.sendEmailVerification();

      _toast('تم إنشاء الحساب — تفقد بريدك لتأكيده');
      if (!mounted) return;

      // الذهاب لشاشة التحقق
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const VerifyEmailScreen()),
      );
    } on FirebaseAuthException catch (e) {
      // في حال كنت سابقًا تستخدم ActionCodeSettings ممكن تطلع أخطاء روابط
      if (e.code == 'invalid-continue-uri' ||
          e.code == 'missing-android-pkg-name' ||
          e.code == 'unauthorized-continue-uri') {
        _toast('تم إنشاء الحساب لكن فشل إرسال التحقق بإعدادات الرابط. أعد المحاولة بدون إعدادات مخصّصة.');
      } else {
        _toast(_mapAuthError(e));
      }
    } catch (e) {
      _toast('حدث خطأ غير متوقع: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ====================== Google Sign-Up / Sign-In ======================

  Future<void> _onGoogle() async {
    setState(() => _loading = true);
    try {
      await FirebaseAuth.instance.setLanguageCode('ar');

      UserCredential credential;

      if (kIsWeb) {
        final provider = GoogleAuthProvider();
        credential = await FirebaseAuth.instance.signInWithPopup(provider);
      } else {
        final gUser = await GoogleSignIn().signIn();
        if (gUser == null) return; // المستخدم لغى العملية
        final gAuth = await gUser.authentication;
        final googleCred = GoogleAuthProvider.credential(
          accessToken: gAuth.accessToken,
          idToken: gAuth.idToken,
        );
        credential = await FirebaseAuth.instance.signInWithCredential(googleCred);
      }

      final user = credential.user!;
      // إنشاء وثيقة للمرة الأولى فقط
      await _createUserDoc(
        user: user,
        first: _first.text.trim().isEmpty ? (user.displayName?.split(' ').first ?? '') : _first.text.trim(),
        last: _last.text.trim().isEmpty ? (user.displayName?.split(' ').skip(1).join(' ') ?? '') : _last.text.trim(),
        email: (user.email ?? _email.text.trim()).toLowerCase(),
        phone: _phone.text.trim(),
        type: _userType,
        chaletName: _userType == UserType.owner ? _chaletName.text.trim() : null,
        chaletAddress: _userType == UserType.owner ? _chaletAddress.text.trim() : null,
      );

      _toast('تم الدخول عبر Google ✅');
      if (mounted) Navigator.pop(context, true);
    } on FirebaseAuthException catch (e) {
      _toast(_mapAuthError(e));
    } catch (e) {
      _toast('فشل تسجيل Google. تأكد من إضافة SHA-1/256 في Firebase لمشروع Android.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ====================== UI ======================

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl, // عربي RTL
      child: Scaffold(
        appBar: AppBar(
          title: const Align(
            alignment: Alignment.centerRight,
            child: Text('سجّل الآن'),
          ),
        ),
        body: SafeArea(
          child: Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // نوع الحساب
                      const Text('نوع الحساب', style: TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [
                          ChoiceChip(
                            label: const Text('مستخدم عادي'),
                            selected: _userType == UserType.user,
                            onSelected: (_) => setState(() => _userType = UserType.user),
                          ),
                          ChoiceChip(
                            label: const Text('صاحب شاليه'),
                            selected: _userType == UserType.owner,
                            onSelected: (_) => setState(() => _userType = UserType.owner),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // الاسم الأول/الثاني
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _first,
                              decoration: const InputDecoration(
                                labelText: 'الاسم الأول',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.person),
                              ),
                              validator: (v) =>
                              (v == null || v.trim().isEmpty) ? 'أدخل الاسم الأول' : null,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: _last,
                              decoration: const InputDecoration(
                                labelText: 'اسم العائلة',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.person_outline),
                              ),
                              validator: (v) =>
                              (v == null || v.trim().isEmpty) ? 'أدخل اسم العائلة' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // البريد الإلكتروني
                      TextFormField(
                        controller: _email,
                        decoration: const InputDecoration(
                          labelText: 'البريد الإلكتروني',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.email),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'أدخل بريدك الإلكتروني';
                          final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim());
                          return ok ? null : 'البريد الإلكتروني غير صالح';
                        },
                      ),
                      const SizedBox(height: 12),

                      // رقم الهاتف
                      TextFormField(
                        controller: _phone,
                        decoration: const InputDecoration(
                          labelText: 'رقم الهاتف',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.phone),
                        ),
                        keyboardType: TextInputType.phone,
                        validator: (v) {
                          final s = v?.trim() ?? '';
                          return s.isEmpty || s.length >= 7 ? null : 'أدخل رقمًا صحيحًا';
                        },
                      ),
                      const SizedBox(height: 12),

                      // حقول إضافية لصاحب الشاليه
                      if (_userType == UserType.owner) ...[
                        TextFormField(
                          controller: _chaletName,
                          decoration: const InputDecoration(
                            labelText: 'اسم الشاليه',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.home_work),
                          ),
                          validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'أدخل اسم الشاليه' : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _chaletAddress,
                          decoration: const InputDecoration(
                            labelText: 'عنوان الشاليه',
                            hintText: 'المدينة / المنطقة / الشارع',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.location_on),
                          ),
                          validator: (v) =>
                          (v == null || v.trim().length < 5) ? 'أدخل عنوانًا مفصّلًا' : null,
                        ),
                        const SizedBox(height: 12),
                      ],

                      // كلمة المرور
                      TextFormField(
                        controller: _password,
                        obscureText: _obscurePass,
                        decoration: InputDecoration(
                          labelText: 'كلمة المرور',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(_obscurePass ? Icons.visibility : Icons.visibility_off),
                            onPressed: () => setState(() => _obscurePass = !_obscurePass),
                          ),
                        ),
                        validator: (v) =>
                        (v != null && v.length >= 6) ? null : 'الحد الأدنى 6 أحرف',
                      ),
                      const SizedBox(height: 12),

                      // تأكيد كلمة المرور
                      TextFormField(
                        controller: _confirm,
                        obscureText: _obscureConfirm,
                        decoration: InputDecoration(
                          labelText: 'تأكيد كلمة المرور',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(_obscureConfirm ? Icons.visibility : Icons.visibility_off),
                            onPressed: () =>
                                setState(() => _obscureConfirm = !_obscureConfirm),
                          ),
                        ),
                        validator: (v) => (v == _password.text) ? null : 'كلمتا المرور غير متطابقتين',
                      ),
                      const SizedBox(height: 8),

                      // الموافقة على الشروط
                      Row(
                        children: [
                          Checkbox(
                            value: _acceptTerms,
                            onChanged: (v) => setState(() => _acceptTerms = v ?? false),
                          ),
                          const Expanded(
                            child: Text('أوافق على الشروط والأحكام'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // زر التسجيل
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
                          onPressed: _loading ? null : _onRegister,
                          child: _loading
                              ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                              : const Text('سجّل الآن', style: TextStyle(color: Colors.white)),
                        ),
                      ),

                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 12),

                      // التسجيل عبر جوجل
                      const Center(child: Text('أو أنشئ حسابًا بواسطة')),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: OutlinedButton.icon(
                          onPressed: _loading ? null : _onGoogle,
                          icon: const Icon(Icons.g_mobiledata, size: 28),
                          label: const Text('Google'),
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            side: const BorderSide(color: Colors.deepPurple),
                            foregroundColor: Colors.deepPurple,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              if (_loading)
                Container(
                  color: Colors.black.withOpacity(0.08),
                  child: const Center(child: CircularProgressIndicator()),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
