import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

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
      // نتائج وهمية مبدئية — استبدلها بربطك الحقيقي لاحقًا
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
    return Scaffold(
      appBar: AppBar(
        title: Text('بحث', style: GoogleFonts.cairo()),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _q,
              textDirection: TextDirection.rtl,
              decoration: InputDecoration(
                hintText: 'ابحث عن مطعم، شاليه، إعلان…',
                hintStyle: GoogleFonts.cairo(),
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onSubmitted: (_) => _runSearch(),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _runSearch,
              child: Text('بحث', style: GoogleFonts.cairo()),
            ),
            const SizedBox(height: 16),
            if (_query.isNotEmpty)
              Align(
                alignment: Alignment.centerRight,
                child: Text('نتائج عن: $_query', style: GoogleFonts.cairo()),
              ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.separated(
                itemCount: _results.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) => ListTile(
                  title: Text(_results[i], textDirection: TextDirection.rtl, style: GoogleFonts.cairo()),
                  leading: const Icon(Icons.search),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
