// lib/screen/owner/business_management_screen.dart
import 'package:flutter/material.dart';

class BusinessManagementScreen extends StatefulWidget {
  const BusinessManagementScreen({super.key});

  @override
  State<BusinessManagementScreen> createState() =>
      _BusinessManagementScreenState();
}

class _BusinessManagementScreenState extends State<BusinessManagementScreen> {
  // ثيم موحّد (pastel TikTok)
  static const Color _pink = Color(0xFFFE2C55);
  static const Color _cyan = Color(0xFF06B6D4);

  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _location = TextEditingController();
  final _price = TextEditingController();

  // حالة الفيديو (واجهة فقط الآن)
  String? _videoFileName;

  // أيام الأسبوع بالعربي (ابدأ بالسبت)
  final List<String> _days = const [
    'السبت',
    'الأحد',
    'الاثنين',
    'الثلاثاء',
    'الأربعاء',
    'الخميس',
    'الجمعة',
  ];

  // حالات التوفر
  // 0 = غير محدد (رمادي)  |  1 = متاح (أخضر)  |  2 = محجوز (أحمر)
  final Map<int, int> _availability = {for (int i = 0; i < 7; i++) i: 0};

  @override
  void dispose() {
    _name.dispose();
    _location.dispose();
    _price.dispose();
    super.dispose();
  }

  void _cycleDay(int index) {
    setState(() {
      _availability[index] = (_availability[index]! + 1) % 3;
    });
  }

  Color _statusColor(int s) {
    switch (s) {
      case 1:
        return Colors.green; // متاح
      case 2:
        return Colors.red; // محجوز
      default:
        return Colors.grey.shade300; // غير محدد
    }
  }

  String _statusLabel(int s) {
    switch (s) {
      case 1:
        return 'متاح';
      case 2:
        return 'محجوز';
      default:
        return 'غير محدد';
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final data = {
      'name': _name.text.trim(),
      'location': _location.text.trim(),
      'price': _price.text.trim(),
      'availability': {
        for (int i = 0; i < 7; i++) _days[i]: _statusLabel(_availability[i]!),
      },
      'video': _videoFileName ?? '',
    };

    // هنا لاحقاً: ارفع الفيديو لـ Storage، واحفظ data في Firestore.
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('تم حفظ بيانات الشاليه ✅')));

    // debug print
    // print(data);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Stack(
          children: [
            // خلفية متدرجة ناعمة (مطابقة للشاشات السابقة)
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFFDFDFE), Color(0xFFF5FBFC)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            // تموج علوي
            Positioned.fill(
              child: Align(
                alignment: Alignment.topCenter,
                child: ClipPath(
                  clipper: _TopWaveClipper(),
                  child: Container(
                    height: 210,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _cyan.withOpacity(.12),
                          _cyan.withOpacity(.04),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // تموج سفلي
            Positioned.fill(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: ClipPath(
                  clipper: _BottomWaveClipper(),
                  child: Container(
                    height: 250,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _pink.withOpacity(.10),
                          _pink.withOpacity(.03),
                        ],
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // توهجات خفيفة
            Positioned(
              top: -90,
              right: -70,
              child: _softBlob(_pink.withOpacity(.06), 220),
            ),
            Positioned(
              bottom: -80,
              left: -80,
              child: _softBlob(_cyan.withOpacity(.07), 260),
            ),

            SafeArea(
              child: Column(
                children: [
                  // AppBar بسيط
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_back_ios_new,
                            color: Colors.black87,
                          ),
                          onPressed: () => Navigator.pop(context),
                          tooltip: 'رجوع',
                        ),
                        const Spacer(),
                        const Text(
                          'إدارة الشاليه',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        const SizedBox(width: 48),
                      ],
                    ),
                  ),

                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 20,
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // كارد رفع فيديو
                            _VideoCard(
                              pink: _pink,
                              cyan: _cyan,
                              fileName: _videoFileName,
                              onPick: () async {
                                // هنا لاحقاً: افتح File/Video picker
                                // حالياً: نعمل اسم وهمي للتجربة
                                setState(
                                  () => _videoFileName = 'chalet_video.mp4',
                                );
                              },
                              onRemove: () =>
                                  setState(() => _videoFileName = null),
                            ),
                            const SizedBox(height: 16),

                            // حقول أساسية
                            TextFormField(
                              controller: _name,
                              decoration: _input(
                                'اسم الشاليه',
                                const Icon(Icons.home_work),
                              ),
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? 'أدخل اسم الشاليه'
                                  : null,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _location,
                              decoration: _input(
                                'الموقع (المدينة/المنطقة/الشارع)',
                                const Icon(Icons.location_on),
                              ),
                              validator: (v) =>
                                  (v == null || v.trim().length < 3)
                                  ? 'أدخل موقعًا صحيحًا'
                                  : null,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _price,
                              keyboardType: TextInputType.number,
                              decoration: _input(
                                'سعر الحجز (₪)',
                                const Icon(Icons.attach_money),
                              ),
                              validator: (v) {
                                final s = v?.trim() ?? '';
                                if (s.isEmpty) return 'أدخل سعر الحجز';
                                final n = num.tryParse(s);
                                return (n == null || n <= 0)
                                    ? 'أدخل رقمًا صحيحًا'
                                    : null;
                              },
                            ),
                            const SizedBox(height: 18),

                            // جدول التوفر
                            const Text(
                              'التوفر خلال الأسبوع',
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: List.generate(_days.length, (i) {
                                final st = _availability[i]!;
                                return GestureDetector(
                                  onTap: () => _cycleDay(i),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _statusColor(st),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: Colors.black.withOpacity(.08),
                                      ),
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          _days[i],
                                          style: TextStyle(
                                            color: st == 0
                                                ? Colors.black87
                                                : Colors.white,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _statusLabel(st),
                                          style: TextStyle(
                                            color: st == 0
                                                ? Colors.black54
                                                : Colors.white,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }),
                            ),
                            const SizedBox(height: 10),

                            // دليل الألوان
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _legendBox(color: Colors.green, label: 'متاح'),
                                const SizedBox(width: 12),
                                _legendBox(color: Colors.red, label: 'محجوز'),
                                const SizedBox(width: 12),
                                _legendBox(
                                  color: Colors.grey.shade300,
                                  label: 'غير محدد',
                                  textColor: Colors.black87,
                                ),
                              ],
                            ),

                            const SizedBox(height: 24),

                            // زر حفظ
                            SizedBox(
                              height: 50,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _pink,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                ),
                                onPressed: _save,
                                child: const Text(
                                  'حفظ البيانات',
                                  style: TextStyle(fontSize: 16),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ديكورات موحدة
  static Widget _softBlob(Color c, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: c, blurRadius: 90, spreadRadius: 50)],
      ),
    );
  }

  InputDecoration _input(String label, Icon prefix) {
    return InputDecoration(
      labelText: label,
      prefixIcon: prefix,
      filled: true,
      fillColor: Colors.white,
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _cyan, width: 1.4),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.black12),
      ),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }

  Widget _legendBox({
    required Color color,
    required String label,
    Color? textColor,
  }) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(color: textColor ?? Colors.black87)),
      ],
    );
  }
}

// بطاقة رفع فيديو (واجهة فقط الآن)
class _VideoCard extends StatelessWidget {
  final Color pink;
  final Color cyan;
  final String? fileName;
  final VoidCallback onPick;
  final VoidCallback onRemove;

  const _VideoCard({
    required this.pink,
    required this.cyan,
    required this.fileName,
    required this.onPick,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withOpacity(.08)),
        boxShadow: const [
          BoxShadow(
            blurRadius: 10,
            color: Colors.black12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [pink, cyan],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Icon(Icons.videocam_rounded, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              fileName ?? 'ارفع فيديو للشاليه (MP4/Mov)…',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: fileName == null ? Colors.black54 : Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          if (fileName != null)
            IconButton(
              tooltip: 'إزالة',
              icon: const Icon(Icons.close_rounded),
              onPressed: onRemove,
            ),
          ElevatedButton(
            onPressed: onPick,
            style: ElevatedButton.styleFrom(
              backgroundColor: pink,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
            child: Text(fileName == null ? 'رفع' : 'تغيير'),
          ),
        ],
      ),
    );
  }
}

// ==== Clippers للتموجات ====
class _TopWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final p = Path();
    p.lineTo(0, size.height * .60);
    p.quadraticBezierTo(
      size.width * .25,
      size.height * .40,
      size.width * .50,
      size.height * .55,
    );
    p.quadraticBezierTo(
      size.width * .80,
      size.height * .75,
      size.width,
      size.height * .50,
    );
    p.lineTo(size.width, 0);
    p.close();
    return p;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class _BottomWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final p = Path();
    p.moveTo(0, 0);
    p.quadraticBezierTo(
      size.width * .20,
      size.height * .35,
      size.width * .48,
      size.height * .28,
    );
    p.quadraticBezierTo(
      size.width * .78,
      size.height * .20,
      size.width,
      size.height * .50,
    );
    p.lineTo(size.width, size.height);
    p.lineTo(0, size.height);
    p.close();
    return p;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
