// lib/screen/home_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

import 'messages_screen.dart';
import 'profile_screen.dart';
import 'search_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const Color _pink = Color(0xFFFE2C55);
  static const String _avatarUrl =
      'assets/images/chalet.jpg';

  final PageController _feedController = PageController();
  int _selectedIndex = 0;
  int _currentPage = 0;

  // local UI state
  final Map<String, bool> _isLiked = {};
  final Map<String, bool> _heartVisible = {};
  final Map<String, bool> _likeBusy = {};
  final Map<String, int> _likesCache = {};

  late Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> _chaletsFuture;

  // Check if user is authenticated (not a guest)
  bool get _isAuthenticated => FirebaseAuth.instance.currentUser != null;

  @override
  void initState() {
    super.initState();
    _chaletsFuture = _loadChalets(); // load once -> no refresh on like
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> _loadChalets() async {
    final snap = await FirebaseFirestore.instance
        .collection('chalets')
        .orderBy('updatedAvailabilityAt', descending: true)
        .get();
    // Filter out chalets without videos
    return snap.docs.where((doc) {
      final data = doc.data();
      final videoFileName = data['videoFileName'] as String? ?? '';
      return videoFileName.isNotEmpty;
    }).toList();
  }

  @override
  void dispose() {
    _feedController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: WillPopScope(
        onWillPop: () async {
          if (_selectedIndex != 0) {
            setState(() => _selectedIndex = 0);
            return false;
          }
          return true;
        },
        child: Scaffold(
          backgroundColor:
          _selectedIndex == 0 ? Colors.black : const Color(0xFFF9FBFC),
          body: IndexedStack(
            index: _selectedIndex,
            children: [
              _buildFeed(),
              SearchScreen(
                onBackToHome: () => setState(() => _selectedIndex = 0),
              ),
              const MessagesScreen(),
              const ProfileScreen(),
            ],
          ),
          bottomNavigationBar: _buildBottomBar(),
        ),
      ),
    );
  }

  // ================= FEED (FULL-SCREEN SWIPE, NO REFRESH ON LIKE) ============

  Widget _buildFeed() {
    return FutureBuilder<List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
      future: _chaletsFuture,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return Container(
            color: Colors.black,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(_pink),
                    strokeWidth: 3,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'جاري التحميل...',
                    style: GoogleFonts.cairo(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        if (!snap.hasData || snap.data!.isEmpty) {
          return Container(
            color: Colors.black,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.video_library_outlined,
                    size: 64,
                    color: Colors.white.withOpacity(0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'لا توجد اعلانات حتى الآن 👀',
                    style: GoogleFonts.cairo(
                      color: Colors.white70,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'كن أول من ينشر إعلانًا',
                    style: GoogleFonts.cairo(
                      color: Colors.white54,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final docs = snap.data!;

        return PageView.builder(
          controller: _feedController,
          scrollDirection: Axis.vertical,
          physics: const BouncingScrollPhysics(),
          onPageChanged: (index) {
            setState(() => _currentPage = index);
          },
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final isActive = index == _currentPage;
            return AnimatedOpacity(
              opacity: isActive ? 1.0 : 0.7,
              duration: const Duration(milliseconds: 300),
              child: _buildReel(doc, isActive),
            );
          },
        );
      },
    );
  }

  Widget _buildReel(
      QueryDocumentSnapshot<Map<String, dynamic>> doc,
      bool isActive,
      ) {
    final data = doc.data();

    final adId = doc.id;
    final ownerId = data['ownerId'] as String? ?? '';
    final videoFileName = data['videoFileName'] as String? ?? '';
    final videoUrl = data['videoUrl'] as String? ?? ''; // Use videoUrl from Firestore
    final likesFromDoc = (data['likes'] ?? 0) as int;
    final commentsCount = (data['commentsCount'] ?? 0) as int;

    // init cache once per ad
    _likesCache.putIfAbsent(adId, () => likesFromDoc);
    final isLiked = _isLiked[adId] ?? false;
    final heartVisible = _heartVisible[adId] ?? false;
    final displayLikes = _likesCache[adId] ?? likesFromDoc;

    return GestureDetector(
      onDoubleTap: _isAuthenticated
          ? () => _handleLikeToggle(adId, doc.reference)
          : () => _showGuestLoginPrompt(),
      child: Stack(
        fit: StackFit.expand,
        children: [
          _ReelVideoBackground(
            videoFileName: videoFileName,
            videoUrl: videoUrl, // Pass videoUrl to use directly
            isActive: isActive, // only active page plays
          ),

          // Enhanced gradient overlay for better text readability
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.0, 0.3, 0.7, 1.0],
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.1),
                    Colors.black.withOpacity(0.5),
                    Colors.black.withOpacity(0.85),
                  ],
                ),
              ),
            ),
          ),

          // Enhanced text at left bottom with better styling
          Positioned(
            left: 16,
            bottom: 88,
            right: 90,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    'إعلان مميز',
                    style: GoogleFonts.cairo(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  data['name'] as String? ?? 'شاليه',
                  style: GoogleFonts.cairo(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                if ((data['description'] as String? ?? '').isNotEmpty)
                  Text(
                    data['description'] as String? ?? '',
                    style: GoogleFonts.cairo(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.9),
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),

          // action column (right)
          Positioned(
            right: 10,
            bottom: 88,
            child: Column(
              children: [
                _iconButton(
                  Icons.favorite,
                  count: '$displayLikes',
                  color: isLiked ? _pink : Colors.white,
                  onTap: _isAuthenticated
                      ? () => _handleLikeToggle(adId, doc.reference)
                      : _showGuestLoginPrompt,
                ),
                const SizedBox(height: 18),
                _iconButton(
                  Icons.comment_outlined,
                  count: '$commentsCount',
                  onTap: _isAuthenticated
                      ? () => _showCommentsSheet(adId, doc.reference)
                      : _showGuestLoginPrompt,
                ),
                const SizedBox(height: 18),
                _iconButton(
                  Icons.chat_bubble_outline,
                  count: 'تواصل',
                  onTap: _isAuthenticated
                      ? () => _showContactSheet(ownerId)
                      : _showGuestLoginPrompt,
                ),
                const SizedBox(height: 18),
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 2.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const CircleAvatar(
                    radius: 22,
                    backgroundImage: AssetImage(_avatarUrl),
                  ),
                ),
              ],
            ),
          ),

          // Enhanced big heart animation with particles effect
          IgnorePointer(
            child: Center(
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: heartVisible ? 1 : 0,
                child: AnimatedScale(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.elasticOut,
                  scale: heartVisible ? 1.0 : 0.0,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: heartVisible
                          ? [
                              BoxShadow(
                                color: _pink.withOpacity(0.6),
                                blurRadius: 40,
                                spreadRadius: 10,
                              ),
                              BoxShadow(
                                color: Colors.redAccent.withOpacity(0.4),
                                blurRadius: 60,
                                spreadRadius: 20,
                              ),
                            ]
                          : [],
                    ),
                    child: const Icon(
                      Icons.favorite,
                      color: Colors.redAccent,
                      size: 110,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Modern top header with glassmorphism
          Positioned(
            top: 48,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [_pink, Color(0xFF25F4EE)],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.local_fire_department,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'اعلاناتي',
                      style: GoogleFonts.cairo(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================= GUEST MODE HANDLING =======================

  void _showGuestLoginPrompt() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'تسجيل الدخول مطلوب',
          style: GoogleFonts.cairo(
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        content: Text(
          'يجب تسجيل الدخول للتفاعل مع المحتوى (إعجاب، تعليق، تواصل)',
          style: GoogleFonts.cairo(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'إلغاء',
              style: GoogleFonts.cairo(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pushNamed(context, '/login');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _pink,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'تسجيل الدخول',
              style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  // ================= LIKES (INSTANT, NO FEED REFRESH) =======================

  Future<void> _handleLikeToggle(
      String adId,
      DocumentReference<Map<String, dynamic>> ref,
      ) async {
    // Safety check: prevent likes if not authenticated
    if (!_isAuthenticated) {
      _showGuestLoginPrompt();
      return;
    }

    if (_likeBusy[adId] == true) return;

    final prevLiked = _isLiked[adId] ?? false;
    final newLiked = !prevLiked;
    final delta = newLiked ? 1 : -1;
    final currentLikes = _likesCache[adId] ?? 0;

    setState(() {
      _isLiked[adId] = newLiked;
      _likeBusy[adId] = true;
      _likesCache[adId] = currentLikes + delta;
      if (newLiked) {
        _heartVisible[adId] = true;
      }
    });

    try {
      await ref.update({'likes': FieldValue.increment(delta)});
    } catch (e) {
      // rollback UI if failed
      setState(() {
        _isLiked[adId] = prevLiked;
        _likesCache[adId] = currentLikes;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في حفظ الإعجاب: $e')),
      );
    } finally {
      if (!mounted) return;
      if (newLiked) {
        Future.delayed(const Duration(milliseconds: 600), () {
          if (!mounted) return;
          setState(() => _heartVisible[adId] = false);
        });
      }
      setState(() => _likeBusy[adId] = false);
    }
  }

  // ================= COMMENTS ==============================================

  void _showCommentsSheet(String adId, DocumentReference ref) {
    // Safety check: prevent comments if not authenticated
    if (!_isAuthenticated) {
      _showGuestLoginPrompt();
      return;
    }

    final newCommentCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) {
        final halfHeight = MediaQuery.of(ctx).size.height * 0.55;

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
                  child: StreamBuilder<QuerySnapshot>(
                    stream: ref
                        .collection('comments')
                        .orderBy('createdAt', descending: false)
                        .snapshots(),
                    builder: (ctx, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return const Center(
                            child: CircularProgressIndicator());
                      }
                      if (!snap.hasData || snap.data!.docs.isEmpty) {
                        return Center(
                          child: Text(
                            'لا توجد تعليقات بعد، كن أول من يعلق ✨',
                            style: GoogleFonts.cairo(
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                          ),
                        );
                      }

                      final comments = snap.data!.docs;

                      return ListView.separated(
                        padding:
                        const EdgeInsets.fromLTRB(12, 8, 12, 8),
                        itemCount: comments.length,
                        separatorBuilder: (_, __) =>
                        const SizedBox(height: 8),
                        itemBuilder: (_, i) {
                          final cData = comments[i].data()
                          as Map<String, dynamic>? ??
                              {};
                          final text =
                              cData['text'] as String? ?? '';
                          final userName =
                              cData['userName'] as String? ?? 'مستخدم';

                          return Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.035),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                const CircleAvatar(
                                  radius: 16,
                                  backgroundColor: Colors.black12,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        userName,
                                        style: GoogleFonts.cairo(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        text,
                                        style: GoogleFonts.cairo(
                                          fontSize: 14,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(
                    left: 12,
                    right: 12,
                    bottom:
                    MediaQuery.of(ctx).viewInsets.bottom + 12,
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
                            fillColor:
                            Colors.black.withOpacity(0.04),
                            contentPadding:
                            const EdgeInsets.symmetric(
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
                        onPressed: _isAuthenticated
                            ? () async {
                                final text = newCommentCtrl.text.trim();
                                if (text.isEmpty) return;
                                newCommentCtrl.clear();

                                try {
                                  final userName =
                                  await _loadCurrentUserName();

                                  await ref.collection('comments').add({
                                    'text': text,
                                    'userName': userName,
                                    'createdAt':
                                    FieldValue.serverTimestamp(),
                                  });

                                  await ref.update({
                                    'commentsCount':
                                    FieldValue.increment(1),
                                  });
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text(
                                            'خطأ في حفظ التعليق: $e')),
                                  );
                                }
                              }
                            : () {
                                Navigator.pop(ctx);
                                _showGuestLoginPrompt();
                              },
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
                        child: Text(
                          'إرسال',
                          style: GoogleFonts.cairo(
                              color: Colors.white),
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
  }

  Future<String> _loadCurrentUserName() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return 'مستخدم';

    final snap =
    await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final data = snap.data() as Map<String, dynamic>?;

    if (data == null) return 'مستخدم';

    final first = data['firstName'] as String? ?? '';
    final last = data['lastName'] as String? ?? '';
    final name = '$first $last'.trim();
    return name.isEmpty ? 'مستخدم' : name;
  }

  // ================= تواصل (CONTACT) ========================================

  void _showContactSheet(String ownerId) async {
    // Safety check: prevent contact if not authenticated
    if (!_isAuthenticated) {
      _showGuestLoginPrompt();
      return;
    }

    if (ownerId.isEmpty) return;

    try {
      final ownerSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(ownerId)
          .get();

      final data =
          ownerSnap.data() as Map<String, dynamic>? ?? {};

      final chaletName =
          data['chaletName'] as String? ?? 'الشالية';
      final phone = data['phone'] as String? ?? 'غير متوفر';

      final waPhone = _normalizePhoneForWhatsApp(phone);

      showModalBottomSheet(
        context: context,
        backgroundColor: const Color(0xFF0E0E0E),
        barrierColor: Colors.black54,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        builder: (ctx) {
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
                  Text(
                    chaletName,
                    style: GoogleFonts.cairo(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    phone,
                    style: GoogleFonts.cairo(
                      color: Colors.white70,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _ContactTile(
                    bg: Colors.white.withOpacity(0.04),
                    border: Colors.white.withOpacity(0.12),
                    text: 'تواصل عبر واتساب  $phone',
                    leading: const Icon(
                      FontAwesomeIcons.whatsapp,
                      color: Color(0xFF25D366),
                      size: 24,
                    ),
                    trailing: _chevron(),
                    onTap: () async {
                      final uri = Uri.parse('https://wa.me/$waPhone');
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
                    text: 'اتصال مباشر  $phone',
                    leading: const Icon(
                      Icons.phone_in_talk_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                    trailing: _chevron(),
                    onTap: () async {
                      final uri = Uri.parse('tel:$phone');
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'لن نشارك رقمك مع المعلن.',
                    style: GoogleFonts.cairo(
                      color: Colors.white54,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في جلب بيانات المعلن: $e')),
      );
    }
  }

  String _normalizePhoneForWhatsApp(String raw) {
    final trimmed = raw.replaceAll(' ', '');
    if (trimmed.startsWith('970')) return trimmed;
    if (trimmed.startsWith('0')) return '970${trimmed.substring(1)}';
    return '970$trimmed';
  }

  // ================= BOTTOM NAV =============================================

  Widget _buildBottomBar() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFDFDFE), Color(0xFFF5FBFC)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        border: Border(
          top: BorderSide(
            color: Colors.black.withOpacity(0.08),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, -4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.home_rounded, 'الرئيسية', 0),
              _buildNavItem(Icons.search_rounded, 'اكتشف', 1),
              _buildNavItem(Icons.chat_bubble_outline_rounded, 'الرسائل', 2),
              _buildNavItem(Icons.person_outline_rounded, 'ملفي', 3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _selectedIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedIndex = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: isSelected
                ? _pink.withOpacity(0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isSelected
                      ? _pink.withOpacity(0.15)
                      : Colors.transparent,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: isSelected ? _pink : Colors.black54,
                  size: isSelected ? 24 : 22,
                ),
              ),
              const SizedBox(height: 2),
              Flexible(
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.cairo(
                    fontSize: isSelected ? 11 : 10,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? _pink : Colors.black54,
                    height: 1.2,
                  ),
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
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
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 1.0, end: 1.0),
      duration: const Duration(milliseconds: 200),
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            onTapDown: (_) {
              // Tap feedback animation handled by Material
            },
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.35),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.15),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    count,
                    style: GoogleFonts.cairo(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ================= CONTACT TILE + BUTTON ====================================

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

Widget _chevron() => Container(
  padding: const EdgeInsets.all(6),
  decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(10),
    gradient: const LinearGradient(
      colors: [Color(0xFFFE2C55), Color(0xFF25F4EE)],
    ),
  ),
  child: const Icon(
    Icons.arrow_back_ios_new_rounded,
    size: 12,
    color: Colors.white,
  ),
);

// ================= VIDEO BACKGROUND (ONLY ACTIVE PLAYS, NO GHOST AUDIO) =====

class _ReelVideoBackground extends StatefulWidget {
  const _ReelVideoBackground({
    required this.videoFileName,
    this.videoUrl,
    required this.isActive,
  });

  final String videoFileName;
  final String? videoUrl; // Optional: use direct URL from Firestore
  final bool isActive;

  @override
  State<_ReelVideoBackground> createState() => _ReelVideoBackgroundState();
}

class _ReelVideoBackgroundState extends State<_ReelVideoBackground>
    with WidgetsBindingObserver {
  VideoPlayerController? _controller;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initVideo();
  }

  Future<void> _initVideo() async {
    if (widget.videoFileName.isEmpty) {
      setState(() => _loading = false);
      return;
    }

    try {
      String url;
      
      // Use videoUrl from Firestore if available (works for guests)
      // Otherwise, get it from Storage (requires auth)
      if (widget.videoUrl != null && widget.videoUrl!.isNotEmpty) {
        url = widget.videoUrl!;
      } else {
        // Fallback: get URL from Storage (might require auth)
        final ref = FirebaseStorage.instance
            .ref()
            .child('chalets_videos/${widget.videoFileName}');
        url = await ref.getDownloadURL();
      }

      final controller =
      VideoPlayerController.networkUrl(Uri.parse(url));

      await controller.initialize();

      if (!mounted) {
        controller.dispose();
        return;
      }

      setState(() {
        _controller = controller;
        _loading = false;
      });

      _updatePlayback();
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  void _updatePlayback() {
    if (_controller == null) return;
    if (!mounted) return;

    final lifecycle = WidgetsBinding.instance.lifecycleState;
    final isResumed = lifecycle == AppLifecycleState.resumed;

    if (widget.isActive && isResumed) {
      _controller!
        ..setLooping(true)
        ..play();
    } else {
      _controller!.pause();
    }
  }

  @override
  void didUpdateWidget(covariant _ReelVideoBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isActive != widget.isActive ||
        oldWidget.videoFileName != widget.videoFileName ||
        oldWidget.videoUrl != widget.videoUrl) {
      // Reinitialize if video changed
      if (oldWidget.videoFileName != widget.videoFileName ||
          oldWidget.videoUrl != widget.videoUrl) {
        _controller?.dispose();
        _controller = null;
        _loading = true;
        _initVideo();
      } else {
        _updatePlayback();
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    _updatePlayback();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_controller == null || !_controller!.value.isInitialized) {
      return Container(color: Colors.black);
    }

    return FittedBox(
      fit: BoxFit.cover,
      child: SizedBox(
        width: _controller!.value.size.width,
        height: _controller!.value.size.height,
        child: VideoPlayer(_controller!),
      ),
    );
  }
}
