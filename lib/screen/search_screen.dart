import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ألوان ثابتة
const Color kPrimary = Color(0xFFFE2C55);
const Color kAccent = Color(0xFF25F4EE);
const Color kBg = Color(0xFFF9FBFC);
const Color kFieldBorder = Color(0xFFE7EDF1);

class SearchScreen extends StatefulWidget {
  final VoidCallback?
  onBackToHome; // ← كولباك الرجوع للرئيسية داخل الـIndexedStack
  const SearchScreen({super.key, this.onBackToHome});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _q = TextEditingController();
  String _query = '';
  final List<String> _results = [];

  void _runSearch() {
    final q = _q.text.trim();
    if (q.isEmpty) return;
    setState(() {
      _query = q;
      _results
        ..clear()
        ..addAll(List.generate(5, (i) => 'نتيجة "$q" رقم ${i + 1}'));
    });
  }

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: kBg,

        /// AppBar مع زر رجوع:
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          // نتحكم بالـ leading يدويًا
          automaticallyImplyLeading: false,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.black87,
            ),
            onPressed: () async {
              // لو الصفحة مفتوحة بـ push رجّع Pop، غير هيك ارجع للرئيسية داخل الـHome
              final popped = await Navigator.maybePop(context);
              if (!popped) widget.onBackToHome?.call();
            },
            tooltip: 'رجوع',
          ),
          title: Text(
            'بحث',
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
                height: 180,
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
                    topLeft: Radius.circular(120),
                  ),
                ),
              ),
            ),

            // المحتوى في منتصف الشاشة
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: Column(
                children: [
                  const Spacer(),

                  // اللوجو الدائري
                  Container(
                    width: 110,
                    height: 110,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [kPrimary, kAccent],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x33000000),
                          blurRadius: 20,
                          offset: Offset(0, 10),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'إعلاناتي',
                      style: GoogleFonts.cairo(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ),

                  const SizedBox(height: 22),

                  // حقل البحث
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: kFieldBorder),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 10),
                        const Icon(Icons.search, color: Colors.black54),
                        const SizedBox(width: 6),
                        Expanded(
                          child: TextField(
                            controller: _q,
                            style: GoogleFonts.cairo(
                              fontSize: 15,
                              color: Colors.black87,
                            ),
                            cursorColor: kPrimary,
                            decoration: InputDecoration(
                              hintText: 'ابحث عن مطعم، شاليه، إعلان…',
                              hintStyle: GoogleFonts.cairo(
                                color: Colors.black45,
                              ),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 14,
                              ),
                            ),
                            onSubmitted: (_) => _runSearch(),
                            onChanged: (_) =>
                                setState(() {}), // لإظهار/إخفاء زر الإغلاق
                          ),
                        ),
                        if (_q.text.isNotEmpty)
                          IconButton(
                            onPressed: () {
                              _q.clear();
                              setState(() {});
                            },
                            icon: const Icon(
                              Icons.close_rounded,
                              color: Colors.black38,
                            ),
                            tooltip: 'مسح',
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // زر البحث
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _runSearch,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'بحث',
                        style: GoogleFonts.cairo(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),

                  const Spacer(),

                  // نتائج مبسطة (لو موجودة)
                  if (_query.isNotEmpty) ...[
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        'نتائج عن: $_query',
                        style: GoogleFonts.cairo(
                          fontSize: 14,
                          color: Colors.black87,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView.separated(
                        itemCount: _results.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) => _ResultCard(text: _results[i]),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final String text;
  const _ResultCard({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kFieldBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.store_mall_directory_rounded, color: Colors.black54),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.cairo(
                fontSize: 15,
                color: Colors.black87,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const Icon(Icons.chevron_left_rounded, color: Colors.black38),
        ],
      ),
    );
  }
}
