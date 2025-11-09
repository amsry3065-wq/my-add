// lib/screen/home_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'search_screen.dart';
import 'profile_screen.dart';
import 'messages_screen.dart'; // ✅ صفحة الرسائل الفعلية

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

// نموذج تعليق
class Comment {
  String text;
  int likes;
  bool liked;
  List<Comment> replies;
  Comment(
    this.text, {
    this.likes = 0,
    this.liked = false,
    List<Comment>? replies,
  }) : replies = replies ?? [];
}

class _HomeScreenState extends State<HomeScreen> {
  // ألوان البراند
  static const Color _pink = Color(0xFFFE2C55);
  static const Color _cyan = Color(0xFF25F4EE);

  // التبويب الحالي
  int _selectedIndex = 0; // 0 الرئيسية، 1 بحث، 2 رسائل، 3 ملفي

  // سكول عمودي للخلاصة
  final PageController _feedController = PageController();

  // بيانات عرض
  final List<String> _images = [
    'assets/images/avatar.jpg',
    'assets/images/cover1.jpg',
    'assets/images/cover2.jpg',
  ];
  final Map<int, bool> _isLiked = {};
  final Map<int, bool> _heartVisible = {};
  final Map<int, List<Comment>> _comments = {};

  void _ensureSeedComments(int index) {
    _comments.putIfAbsent(
      index,
      () => [Comment('كم السعر؟'), Comment('كم السعر؟'), Comment('كم السعر؟')],
    );
  }

  void _onDoubleTapLike(int index) {
    if (_heartVisible[index] == true) return;
    setState(() {
      _heartVisible[index] = true;
      _isLiked[index] = true;
    });
    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      setState(() => _heartVisible[index] = false);
    });
  }

  // BottomSheet: تواصل مع المعلن
  void _showContactOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0E0E0E),
      barrierColor: Colors.black54,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
                const SizedBox(height: 14),
                ShaderMask(
                  shaderCallback: (r) => const LinearGradient(
                    colors: [_pink, _cyan],
                  ).createShader(r),
                  child: Text(
                    'التواصل مع المعلن',
                    style: GoogleFonts.cairo(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                _ContactTile(
                  bg: Colors.white.withOpacity(0.04),
                  border: Colors.white.withOpacity(0.12),
                  text: 'تواصل عبر واتساب  970592000000',
                  leading: const Icon(
                    FontAwesomeIcons.whatsapp,
                    color: Color(0xFF25D366),
                    size: 24,
                  ),
                  trailing: _chevron(),
                  onTap: () async {
                    final uri = Uri.parse('https://wa.me/970592000000');
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(
                        uri,
                        mode: LaunchMode.externalApplication,
                      );
                    }
                  },
                ),
                const SizedBox(height: 10),
                _ContactTile(
                  bg: Colors.white.withOpacity(0.04),
                  border: Colors.white.withOpacity(0.12),
                  text: 'اتصال مباشر  0592835008',
                  leading: const Icon(
                    Icons.phone_in_talk_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                  trailing: _chevron(),
                  onTap: () async {
                    final uri = Uri.parse('tel:0592835008');
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri);
                    }
                  },
                ),
                const SizedBox(height: 12),
                Text(
                  'لن نشارك رقمك مع المعلن.',
                  style: GoogleFonts.cairo(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static Widget _chevron() => Container(
    padding: const EdgeInsets.all(6),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(10),
      gradient: const LinearGradient(colors: [_pink, _cyan]),
    ),
    child: const Icon(
      Icons.arrow_back_ios_new_rounded,
      size: 12,
      color: Colors.white,
    ),
  );

  // شاشة التعليقات
  void _showComments(int index) {
    _ensureSeedComments(index);
    final newCommentCtrl = TextEditingController();
    final Set<int> expandedReplies = {};

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) {
        final halfHeight = MediaQuery.of(ctx).size.height * 0.55;

        return StatefulBuilder(
          builder: (ctx, setSheet) {
            void toggleLike(int i) {
              setState(() {
                final c = _comments[index]![i];
                c.liked = !c.liked;
                c.likes += c.liked ? 1 : -1;
                if (c.likes < 0) c.likes = 0;
              });
              setSheet(() {});
            }

            void addComment() {
              final text = newCommentCtrl.text.trim();
              if (text.isEmpty) return;
              setState(() => _comments[index]!.add(Comment(text)));
              newCommentCtrl.clear();
              setSheet(() {});
            }

            void addReply(int i, String text) {
              if (text.trim().isEmpty) return;
              setState(
                () => _comments[index]![i].replies.add(Comment(text.trim())),
              );
              setSheet(() {});
            }

            return SizedBox(
              height: halfHeight,
              child: SafeArea(
                top: false,
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.black12,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'التعليقات',
                      style: GoogleFonts.cairo(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                        itemCount: _comments[index]!.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, i) {
                          final comment = _comments[index]![i];
                          final replyCtrl = TextEditingController();

                          return Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.035),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const CircleAvatar(
                                      radius: 16,
                                      backgroundColor: Colors.black12,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        comment.text,
                                        style: GoogleFonts.cairo(
                                          fontSize: 14,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    InkWell(
                                      onTap: () => toggleLike(i),
                                      child: Row(
                                        children: [
                                          Icon(
                                            comment.liked
                                                ? Icons.favorite
                                                : Icons.favorite_border,
                                            size: 18,
                                            color: comment.liked
                                                ? _pink
                                                : Colors.black54,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            '${comment.likes}',
                                            style: GoogleFonts.cairo(
                                              fontSize: 13,
                                              color: Colors.black54,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    TextButton(
                                      onPressed: () {
                                        if (expandedReplies.contains(i)) {
                                          expandedReplies.remove(i);
                                        } else {
                                          expandedReplies.add(i);
                                        }
                                        setState(() {});
                                        setSheet(() {});
                                      },
                                      child: Text(
                                        expandedReplies.contains(i)
                                            ? 'إخفاء الردود'
                                            : 'رد',
                                        style: GoogleFonts.cairo(
                                          fontSize: 13,
                                          color: Colors.black87,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (expandedReplies.contains(i)) ...[
                                  if (comment.replies.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4.0),
                                      child: Column(
                                        children: List.generate(
                                          comment.replies.length,
                                          (r) {
                                            final reply = comment.replies[r];
                                            return Padding(
                                              padding: const EdgeInsets.only(
                                                bottom: 6.0,
                                              ),
                                              child: Row(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  const SizedBox(width: 24),
                                                  const CircleAvatar(
                                                    radius: 12,
                                                    backgroundColor:
                                                        Colors.black12,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: Text(
                                                      reply.text,
                                                      style: GoogleFonts.cairo(
                                                        fontSize: 13,
                                                        color: Colors.black87,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          controller: replyCtrl,
                                          textDirection: TextDirection.rtl,
                                          decoration: InputDecoration(
                                            hintText: 'أضف ردًا...',
                                            hintStyle: GoogleFonts.cairo(
                                              color: Colors.black38,
                                            ),
                                            filled: true,
                                            fillColor: Colors.white,
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                  horizontal: 12,
                                                  vertical: 10,
                                                ),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              borderSide: const BorderSide(
                                                color: Colors.black26,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      IconButton(
                                        onPressed: () {
                                          addReply(i, replyCtrl.text);
                                          replyCtrl.clear();
                                        },
                                        style: IconButton.styleFrom(
                                          backgroundColor: Colors.black87,
                                        ),
                                        icon: const Icon(
                                          Icons.send,
                                          color: Colors.white,
                                          size: 18,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(
                        left: 12,
                        right: 12,
                        bottom: MediaQuery.of(ctx).viewInsets.bottom + 12,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: newCommentCtrl,
                              textDirection: TextDirection.rtl,
                              decoration: InputDecoration(
                                hintText: 'اكتب تعليقًا...',
                                hintStyle: GoogleFonts.cairo(
                                  color: Colors.black38,
                                ),
                                filled: true,
                                fillColor: Colors.black.withOpacity(0.04),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _pink,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                            onPressed: addComment,
                            child: Text(
                              'إرسال',
                              style: GoogleFonts.cairo(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ====== UI ======
  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: WillPopScope(
        onWillPop: () async {
          // رجوع الهاردوير: إن كنتِ بغير الرئيسية، ارجعي للرئيسية
          if (_selectedIndex != 0) {
            setState(() => _selectedIndex = 0);
            return false; // لا تغلق التطبيق
          }
          return true;
        },
        child: Scaffold(
          // داكن للرئيسية، فاتح لباقي التبويبات
          backgroundColor: _selectedIndex == 0
              ? Colors.black
              : const Color(0xFFF9FBFC),

          body: IndexedStack(
            index: _selectedIndex,
            children: [
              _buildFeed(), // 0: الرئيسية (داكن)
              // 1: بحث (فاتح) مع كولباك يرجّع للهوم
              SearchScreen(
                onBackToHome: () => setState(() => _selectedIndex = 0),
              ),

              // 2: الرسائل — صفحة فعلية
              const MessagesScreen(),

              // 3: ملفي
              const ProfileScreen(),
            ],
          ),

          // Bottom bar (فاتح ثابت لكل التطبيق)
          bottomNavigationBar: _buildBottomBar(),
        ),
      ),
    );
  }

  // الخلاصة (عمودي)
  Widget _buildFeed() {
    return Stack(
      children: [
        PageView.builder(
          controller: _feedController,
          scrollDirection: Axis.vertical,
          itemCount: _images.length,
          itemBuilder: (context, index) {
            final isLiked = _isLiked[index] ?? false;
            final heartVisible = _heartVisible[index] ?? false;

            return GestureDetector(
              onDoubleTap: () => _onDoubleTapLike(index),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(_images[index], fit: BoxFit.cover),
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.center,
                          colors: [
                            Colors.black.withOpacity(0.72),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 16,
                    bottom: 88,
                    right: 90,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '@user$index',
                          style: GoogleFonts.cairo(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'إعلان رقم ${index + 1} 🔥',
                          style: GoogleFonts.cairo(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    right: 10,
                    bottom: 88,
                    child: Column(
                      children: [
                        _iconButton(
                          Icons.favorite,
                          count: '120K',
                          color: isLiked ? _pink : Colors.white,
                          onTap: () =>
                              setState(() => _isLiked[index] = !isLiked),
                        ),
                        const SizedBox(height: 18),
                        _iconButton(
                          Icons.comment_outlined,
                          count: '${(_comments[index]?.length ?? 3)}',
                          onTap: () => _showComments(index),
                        ),
                        const SizedBox(height: 18),
                        _iconButton(
                          Icons.chat_bubble_outline,
                          count: 'تواصل',
                          onTap: _showContactOptions,
                        ),
                        const SizedBox(height: 18),
                        const CircleAvatar(
                          radius: 22,
                          backgroundImage: AssetImage(
                            'assets/images/logo_ilanati.png',
                          ),
                        ),
                      ],
                    ),
                  ),
                  IgnorePointer(
                    child: Center(
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 150),
                        opacity: heartVisible ? 1 : 0,
                        child: AnimatedScale(
                          duration: const Duration(milliseconds: 350),
                          scale: heartVisible ? 1.0 : 0.4,
                          child: const Icon(
                            Icons.favorite,
                            color: Colors.redAccent,
                            size: 110,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 48,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Text(
                          'اعلاناتي',
                          style: GoogleFonts.cairo(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  // Bottom bar (فاتح ثابت لكل التطبيق)
  Widget _buildBottomBar() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFDFDFE), Color(0xFFF5FBFC)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        border: Border(top: BorderSide(color: Color(0xFFE7EDF1))),
        boxShadow: [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: Colors.black87,
          unselectedItemColor: Colors.black54,
          onTap: (i) => setState(() => _selectedIndex = i),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'الرئيسية'),
            BottomNavigationBarItem(icon: Icon(Icons.search), label: 'اكتشف'),
            BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline),
              label: 'الرسائل',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              label: 'ملفي',
            ),
          ],
        ),
      ),
    );
  }

  Widget _iconButton(
    IconData icon, {
    String count = '',
    Color color = Colors.white,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.25),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 6),
          Text(
            count,
            style: GoogleFonts.cairo(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

// بلاطة تواصل
class _ContactTile extends StatelessWidget {
  const _ContactTile({
    required this.text,
    required this.leading,
    required this.trailing,
    required this.onTap,
    required this.bg,
    required this.border,
  });

  final String text;
  final Widget leading;
  final Widget trailing;
  final VoidCallback onTap;
  final Color bg;
  final Color border;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: border),
        ),
        child: Row(
          children: [
            leading,
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: GoogleFonts.cairo(color: Colors.white, fontSize: 15),
              ),
            ),
            const SizedBox(width: 8),
            trailing,
          ],
        ),
      ),
    );
  }
}
