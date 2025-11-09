import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'auth/login_screen.dart';

// ألوان موحّدة
const Color kPrimary = Color(0xFFFE2C55);
const Color kAccent = Color(0xFF25F4EE);
const Color kBg = Color(0xFFF9FBFC);

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, this.onBackToPrevTab});

  /// يُمرَّر من الـHome ليعيدك لآخر تبويب
  final VoidCallback? onBackToPrevTab;

  Future<void> _signOut(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      try {
        await GoogleSignIn().signOut();
      } catch (_) {}
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ أثناء تسجيل الخروج: $e')),
        );
      }
    }
  }

  String _initials(User? u) {
    final name = (u?.displayName ?? '').trim();
    if (name.isEmpty) return 'إ';
    final parts = name.split(RegExp(r'\s+'));
    final first = parts.first.characters.firstOrNull ?? '';
    final last =
        (parts.length > 1 ? parts.last.characters.firstOrNull : '') ?? '';
    return (first + last).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: kBg,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          automaticallyImplyLeading: false,
          leading: IconButton(
            tooltip: 'رجوع',
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.black87,
            ),
            onPressed: () async {
              final popped = await Navigator.maybePop(context);
              if (!popped) onBackToPrevTab?.call(); // ← يرجع آخر تبويب
            },
          ),
          title: Text(
            'ملفي',
            style: GoogleFonts.cairo(
              color: Colors.black87,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x33FE2C55),
                  Color(0x3325F4EE),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        body: Stack(
          children: [
            // موجة خفيفة أسفل
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                height: 200,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0x11FE2C55),
                      Color(0x1125F4EE),
                      Color(0x00FFFFFF),
                    ],
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(140),
                  ),
                ),
              ),
            ),
            // المحتوى
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: Column(
                children: [
                  const Spacer(flex: 2),
                  // أفاتار
                  _Avatar(photoUrl: user?.photoURL, initials: _initials(user)),
                  const SizedBox(height: 12),
                  Text(
                    user?.displayName?.trim().isNotEmpty == true
                        ? user!.displayName!.trim()
                        : 'مستخدم إعلاناتي',
                    style: GoogleFonts.cairo(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?.email ?? 'بدون بريد',
                    style: GoogleFonts.cairo(
                      color: Colors.black54,
                      fontSize: 13.5,
                    ),
                  ),
                  const Spacer(flex: 3),
                  // زر تسجيل الخروج
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () => _signOut(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'تسجيل الخروج',
                        style: GoogleFonts.cairo(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.photoUrl, required this.initials});
  final String? photoUrl;
  final String initials;

  @override
  Widget build(BuildContext context) {
    final hasPhoto = (photoUrl ?? '').isNotEmpty;
    return Container(
      width: 118,
      height: 118,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [kPrimary, kAccent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.all(5),
      child: CircleAvatar(
        backgroundColor: Colors.white,
        child: hasPhoto
            ? ClipOval(
                child: Image.network(
                  photoUrl!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                ),
              )
            : Text(
                initials,
                style: GoogleFonts.cairo(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                ),
              ),
      ),
    );
  }
}
