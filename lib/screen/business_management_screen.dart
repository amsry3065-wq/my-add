// lib/screen/owner/business_management_screen.dart
import 'package:flutter/material.dart';

class BusinessManagementScreen extends StatefulWidget {
  const BusinessManagementScreen({super.key});

  @override
  State<BusinessManagementScreen> createState() =>
      _BusinessManagementScreenState();
}

class _BusinessManagementScreenState extends State<BusinessManagementScreen> {
  // ألوان الهوية
  static const Color _pink = Color(0xFFFE2C55);
  static const Color _cyan = Color(0xFF06B6D4);

  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _location = TextEditingController();
  final _price = TextEditingController();
  final _description = TextEditingController();

  String? _videoFileName;

  // الشهر المعروض (افتراضي: الشهر الحالي)
  DateTime _visibleMonth = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    1,
  );

  /// خريطة حالة أيام الشهر: true = محجوز | false = متاح
  final Map<String, bool> _booked = {};

  @override
  void initState() {
    super.initState();
    _initMonthGrid(_visibleMonth);
  }

  @override
  void dispose() {
    _name.dispose();
    _location.dispose();
    _price.dispose();
    _description.dispose();
    super.dispose();
  }

  // ===== منطق التقويم =====
  void _initMonthGrid(DateTime month) {
    _booked.clear();
    final int year = month.year;
    final int mon = month.month;
    final int daysInMonth = DateTime(year, mon + 1, 0).day;
    for (int d = 1; d <= daysInMonth; d++) {
      final key = _keyOf(DateTime(year, mon, d));
      _booked.putIfAbsent(key, () => false); // افتراضيًا: متاح
    }
    setState(() {});
  }

  String _keyOf(DateTime d) =>
      "${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";

  void _prevMonth() {
    final m = DateTime(_visibleMonth.year, _visibleMonth.month - 1, 1);
    _visibleMonth = m;
    _initMonthGrid(m);
  }

  void _nextMonth() {
    final m = DateTime(_visibleMonth.year, _visibleMonth.month + 1, 1);
    _visibleMonth = m;
    _initMonthGrid(m);
  }

  void _toggleDay(DateTime day) {
    final key = _keyOf(day);
    if (_booked.containsKey(key)) {
      setState(() => _booked[key] = !(_booked[key]!)); // قلب الحالة
    }
  }

  void _setAll(bool booked) {
    setState(() {
      for (final k in _booked.keys) {
        _booked[k] = booked;
      }
    });
  }

  Color _dayColor(bool isBooked) => isBooked ? Colors.red : Colors.green;
  String _dayLabel(bool isBooked) => isBooked ? 'محجوز' : 'متاح';

  // ===== حفظ البيانات (واجهة) =====
  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final data = {
      'name': _name.text.trim(),
      'location': _location.text.trim(),
      'price': _price.text.trim(),
      'description': _description.text.trim(),
      'month': {'year': _visibleMonth.year, 'month': _visibleMonth.month},
      'days': {
        for (final e in _booked.entries)
          e.key: e.value ? 'booked' : 'available',
      },
      'video': _videoFileName ?? '',
    };

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('تم حفظ بيانات الشاليه ✅')));

    // print(data); // للديبغ إن احتجت
  }

  // ===== واجهة المستخدم =====
  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Stack(
          children: [
            // خلفية متدرجة
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
                  // AppBar
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
                              onPick: () {
                                setState(
                                  () => _videoFileName = 'chalet_video.mp4',
                                ); // mock
                              },
                              onRemove: () =>
                                  setState(() => _videoFileName = null),
                            ),
                            const SizedBox(height: 16),

                            // اسم الشاليه
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

                            // الموقع
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

                            // سعر الحجز
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
                            const SizedBox(height: 12),

                            // وصف الشاليه
                            TextFormField(
                              controller: _description,
                              decoration: _input(
                                'وصف الشاليه (عدد الغرف، المرافق…)',
                                const Icon(Icons.description_rounded),
                              ),
                              minLines: 3,
                              maxLines: 6,
                              maxLength: 500,
                            ),
                            const SizedBox(height: 18),

                            // التقويم الشهري
                            _MonthCalendar(
                              month: _visibleMonth,
                              bookedMap: _booked,
                              onPrev: _prevMonth,
                              onNext: _nextMonth,
                              onToggle: _toggleDay,
                              dayColor: _dayColor,
                              dayLabel: _dayLabel,
                            ),

                            const SizedBox(height: 10),

                            // أزرار سريعة + أسطورة
                            Wrap(
                              alignment: WrapAlignment.center,
                              spacing: 10,
                              runSpacing: 10,
                              children: [
                                OutlinedButton.icon(
                                  icon: const Icon(Icons.event_available),
                                  label: const Text('تحديد الشهر متاح'),
                                  onPressed: () => _setAll(false),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.green.shade700,
                                    side: BorderSide(
                                      color: Colors.green.shade600,
                                    ),
                                  ),
                                ),
                                OutlinedButton.icon(
                                  icon: const Icon(Icons.event_busy),
                                  label: const Text('تحديد الشهر محجوز'),
                                  onPressed: () => _setAll(true),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.red.shade700,
                                    side: BorderSide(
                                      color: Colors.red.shade600,
                                    ),
                                  ),
                                ),
                                _legendBox(color: Colors.green, label: 'متاح'),
                                _legendBox(color: Colors.red, label: 'محجوز'),
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

  // ديكورات
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
        borderSide: const BorderSide(color: Colors.black12),
      ),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }

  Widget _legendBox({required Color color, required String label}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
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
        Text(label, style: const TextStyle(color: Colors.black87)),
      ],
    );
  }
}

// بطاقة رفع فيديو (واجهة)
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

// ==== تقويم شهري مخصص ====
class _MonthCalendar extends StatelessWidget {
  final DateTime month;
  final Map<String, bool> bookedMap; // true=محجوز | false=متاح
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final void Function(DateTime day) onToggle;
  final Color Function(bool isBooked) dayColor;
  final String Function(bool isBooked) dayLabel;

  const _MonthCalendar({
    required this.month,
    required this.bookedMap,
    required this.onPrev,
    required this.onNext,
    required this.onToggle,
    required this.dayColor,
    required this.dayLabel,
  });

  int _daysInMonth(DateTime m) => DateTime(m.year, m.month + 1, 0).day;

  // تحويل weekday لبدء الأسبوع بالسبت
  int _satLeadingBlanks(DateTime m) {
    final w = DateTime(m.year, m.month, 1).weekday; // Mon=1..Sun=7
    if (w == 6) return 0; // Saturday
    if (w == 7) return 1; // Sunday
    return w + 1; // Mon->2 ... Fri->6
  }

  @override
  Widget build(BuildContext context) {
    final daysCount = _daysInMonth(month);
    final leading = _satLeadingBlanks(month);
    final cells = leading + daysCount;
    final rows = (cells / 7).ceil();

    final headerStyle = Theme.of(
      context,
    ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800);

    // سقف بسيط لتكبير النص حتى لا تنكسر عناوين الأيام
    final capped = MediaQuery.of(context).copyWith(
      textScaleFactor: MediaQuery.textScaleFactorOf(context).clamp(1.0, 1.15),
    );

    return Container(
      padding: const EdgeInsets.all(14),
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
      child: Column(
        children: [
          // شريط الشهر ← →
          Row(
            children: [
              IconButton(
                onPressed: onPrev,
                icon: const Icon(Icons.chevron_right),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    "${_arabicMonthName(month.month)} ${month.year}",
                    style: headerStyle,
                  ),
                ),
              ),
              IconButton(
                onPressed: onNext,
                icon: const Icon(Icons.chevron_left),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // عناوين الأيام (السبت أولاً)
          MediaQuery(
            data: capped,
            child: Row(
              children: const [
                _DayHeader('السبت'),
                _DayHeader('الأحد'),
                _DayHeader('الاثنين'),
                _DayHeader('الثلاثاء'),
                _DayHeader('الأربعاء'),
                _DayHeader('الخميس'),
                _DayHeader('الجمعة'),
              ],
            ),
          ),
          const SizedBox(height: 6),

          // الشبكة
          Column(
            children: List.generate(rows, (r) {
              return Row(
                children: List.generate(7, (c) {
                  final cellIndex = r * 7 + c;
                  final dayNumber = cellIndex - leading + 1;
                  if (dayNumber < 1 || dayNumber > daysCount) {
                    return const Expanded(child: SizedBox(height: 54));
                  }
                  final date = DateTime(month.year, month.month, dayNumber);
                  final key =
                      "${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
                  final booked = bookedMap[key] ?? false;

                  return Expanded(
                    child: GestureDetector(
                      onTap: () => onToggle(date),
                      child: Container(
                        height: 54,
                        margin: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: dayColor(booked),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.black.withOpacity(.06),
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              dayNumber.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              dayLabel(booked),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              );
            }),
          ),
        ],
      ),
    );
  }

  String _arabicMonthName(int m) {
    const names = [
      'يناير',
      'فبراير',
      'مارس',
      'أبريل',
      'مايو',
      'يونيو',
      'يوليو',
      'أغسطس',
      'سبتمبر',
      'أكتوبر',
      'نوفمبر',
      'ديسمبر',
    ];
    return names[m - 1];
  }
}

class _DayHeader extends StatelessWidget {
  final String title;
  const _DayHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 34,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFFF7F7F9),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const _NoWrapText(),
      ),
    );
  }
}

// نص مانع للّف مع تصغير تلقائي
class _NoWrapText extends StatelessWidget {
  const _NoWrapText({super.key});

  @override
  Widget build(BuildContext context) {
    final parent = context.findAncestorWidgetOfExactType<_DayHeader>();
    final title = (parent is _DayHeader) ? parent.title : '';
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        softWrap: false,
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
      ),
    );
  }
}

// ==== Clippers للديكور ====
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
