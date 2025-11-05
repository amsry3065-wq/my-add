import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

// ↓↓↓ أضف هذه الاستيرادات للشاشات الجديدة ↓↓↓
import 'search_screen.dart';
import 'upload_video_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

/// نموذج تعليق مع إعجاب وردود
class Comment {
  String text;
  int likes;
  bool liked;
  List<Comment> replies;
  Comment(this.text, {this.likes = 0, this.liked = false, List<Comment>? replies})
      : replies = replies ?? [];
}

class _HomeScreenState extends State<HomeScreen> {
  // للتحريك الأفقي بين (الخلاصة) و(الملف)
  final PageController _tabsController = PageController(initialPage: 0);

  // للسكول العمودي داخل صفحة الخلاصة (كما كان)
  final PageController _pageController = PageController();

  // تتبّع عنصر البوتوم بار المحدد
  int _selectedIndex = 0; // 0 = الرئيسية، 4 = ملفي

  final List<String> _images = [
    'assets/images/avatar.jpg',
    'assets/images/cover1.jpg',
    'assets/images/cover2.jpg',
  ];

  final Map<int, bool> _isLiked = {};
  final Map<int, bool> _heartVisible = {};

  /// تعليقات لكل بطاقة — 3 تعليقات افتراضيًا
  final Map<int, List<Comment>> _comments = {};

  void _ensureSeedComments(int index) {
    _comments.putIfAbsent(index, () => [
      Comment('كم السعر؟'),
      Comment('كم السعر؟'),
      Comment('كم السعر؟'),
    ]);
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

  // نافذة تواصل (واتساب + اتصال)
  void _showContactOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black87,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 16),
            Text('التواصل مع المعلن',
                style: GoogleFonts.cairo(
                    color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            _contactButton(
              icon: FontAwesomeIcons.whatsapp,
              color: Colors.green,
              text: 'تواصل عبر واتساب 970592000000',
              onTap: () async {
                final uri = Uri.parse('https://wa.me/970592000000');
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
            ),
            const SizedBox(height: 12),
            _contactButton(
              icon: Icons.phone,
              color: Colors.blueAccent,
              text: 'اتصال مباشر 0592835008',
              onTap: () async {
                final uri = Uri.parse('tel:0592835008');
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri);
                }
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _contactButton({
    required IconData icon,
    required String text,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(text,
                  style: GoogleFonts.cairo(color: Colors.white, fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  /// شاشة التعليقات مع إعجاب + ردود
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
          builder: (ctx, setSheetState) {
            void toggleLike(int i) {
              setState(() {
                final c = _comments[index]![i];
                c.liked = !c.liked;
                c.likes += c.liked ? 1 : -1;
                if (c.likes < 0) c.likes = 0;
              });
              setSheetState(() {});
            }

            void addComment() {
              final text = newCommentCtrl.text.trim();
              if (text.isEmpty) return;
              setState(() => _comments[index]!.add(Comment(text)));
              newCommentCtrl.clear();
              setSheetState(() {});
            }

            void addReply(int i, String text) {
              if (text.trim().isEmpty) return;
              setState(() => _comments[index]![i].replies.add(Comment(text.trim())));
              setSheetState(() {});
            }

            return SizedBox(
              height: halfHeight,
              child: SafeArea(
                top: false,
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    Container(
                      width: 36, height: 4,
                      decoration: BoxDecoration(
                        color: Colors.black12,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('التعليقات',
                        style: GoogleFonts.cairo(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        )),
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
                                            fontSize: 14, color: Colors.black87),
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
                                                ? Colors.redAccent
                                                : Colors.black54,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            '${comment.likes}',
                                            style: GoogleFonts.cairo(
                                                fontSize: 13,
                                                color: Colors.black54),
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
                                        setSheetState(() {});
                                      },
                                      child: Text(
                                        expandedReplies.contains(i)
                                            ? 'إخفاء الردود'
                                            : 'رد',
                                        style: GoogleFonts.cairo(
                                            fontSize: 13,
                                            color: Colors.black87,
                                            fontWeight: FontWeight.w700),
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
                                              padding: const EdgeInsets.only(bottom: 6.0),
                                              child: Row(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  const SizedBox(width: 24),
                                                  const CircleAvatar(
                                                    radius: 12,
                                                    backgroundColor: Colors.black12,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: Text(
                                                      reply.text,
                                                      style: GoogleFonts.cairo(
                                                          fontSize: 13,
                                                          color: Colors.black87),
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
                                                color: Colors.black38),
                                            filled: true,
                                            fillColor: Colors.white,
                                            contentPadding: const EdgeInsets.symmetric(
                                                horizontal: 12, vertical: 10),
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(10),
                                              borderSide: const BorderSide(color: Colors.black26),
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
                                        icon: const Icon(Icons.send,
                                            color: Colors.white, size: 18),
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
                                hintStyle:
                                GoogleFonts.cairo(color: Colors.black38),
                                filled: true,
                                fillColor: Colors.black.withOpacity(0.04),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 10),
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
                              backgroundColor: Colors.black87,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                            ),
                            onPressed: addComment,
                            child: Text('إرسال',
                                style: GoogleFonts.cairo(color: Colors.white)),
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
    return Scaffold(
      backgroundColor: Colors.black,
      body: PageView(
        controller: _tabsController,
        scrollDirection: Axis.horizontal,
        onPageChanged: (page) {
          // مزامنة السواب الأفقي مع البوتوم بار:
          // الصفحة 0 = الرئيسية, الصفحة 1 = ملفي
          setState(() => _selectedIndex = (page == 0) ? 0 : 4);
        },
        children: [
          _buildFeed(),          // الصفحة 0: الخلاصة (كما كانت)
          const ProfileScreen(), // الصفحة 1: ملفي (أبيض)
        ],
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildFeed() {
    final red = const Color(0xFFFE2C55);

    return Stack(
      children: [
        // Scroll عمودي بين الصور
        PageView.builder(
          controller: _pageController,
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
                            Colors.black.withOpacity(0.70),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 16,
                    bottom: 80,
                    right: 90,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('@user$index',
                            style: GoogleFonts.cairo(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                        const SizedBox(height: 8),
                        Text('إعلان رقم ${index + 1} 🔥',
                            style: GoogleFonts.cairo(
                                color: Colors.white, fontSize: 14)),
                      ],
                    ),
                  ),
                  Positioned(
                    right: 10,
                    bottom: 80,
                    child: Column(
                      children: [
                        _iconButton(
                          Icons.favorite,
                          count: '120K',
                          color: isLiked ? red : Colors.white,
                          onTap: () => setState(() => _isLiked[index] = !isLiked),
                        ),
                        const SizedBox(height: 18),
                        _iconButton(
                          Icons.comment_outlined,
                          count: '${(_comments[index]?.length ?? 3)}',
                          onTap: () => _showComments(index),
                        ),
                        const SizedBox(height: 18),
                        _iconButton(Icons.chat_bubble_outline,
                            count: 'تواصل', onTap: _showContactOptions),
                        const SizedBox(height: 18),
                        const CircleAvatar(
                          radius: 22,
                          backgroundImage:
                          AssetImage('assets/images/logo_ilanati.png'),
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
                          child: const Icon(Icons.favorite,
                              color: Colors.redAccent, size: 110),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        Positioned(
          top: 48, left: 0, right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(24)),
              child: Text('اعلاناتي',
                  style: GoogleFonts.cairo(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    return Container(
      color: Colors.black.withOpacity(0.02),
      child: BottomNavigationBar(
        currentIndex: _selectedIndex,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.black.withOpacity(0.35),
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        onTap: (i) {
          // الخرائط المطلوبة:
          // 0: الرئيسية → صفحة 0
          // 1: البحث  → افتح SearchScreen
          // 2: إضافة   → افتح UploadVideoScreen
          // 3: الرسائل → (اختياري) تنبيه مؤقت
          // 4: ملفي    → صفحة 1
          switch (i) {
            case 0:
              _tabsController.animateToPage(
                0,
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOut,
              );
              setState(() => _selectedIndex = 0);
              break;
            case 1:
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SearchScreen()),
              );
              break;
            case 2:
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const UploadVideoScreen()),
              );
              break;
            case 3:
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('قسم الرسائل لاحقًا')),
              );
              break;
            case 4:
              _tabsController.animateToPage(
                1,
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOut,
              );
              setState(() => _selectedIndex = 4);
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'الرئيسية'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'اكتشف'),
          BottomNavigationBarItem(icon: Icon(Icons.add_box), label: 'إضافة'),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: 'الرسائل'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'ملفي'),
        ],
      ),
    );
  }

  Widget _iconButton(IconData icon,
      {String count = '', Color color = Colors.white, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 4),
          Text(count,
              style: GoogleFonts.cairo(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }
}
