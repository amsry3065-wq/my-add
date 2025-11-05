import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

class UploadVideoScreen extends StatefulWidget {
  const UploadVideoScreen({super.key});

  @override
  State<UploadVideoScreen> createState() => _UploadVideoScreenState();
}

class _UploadVideoScreenState extends State<UploadVideoScreen> {
  XFile? _pickedVideo;
  bool _uploading = false;

  Future<void> _pickVideo() async {
    final picker = ImagePicker();
    final file = await picker.pickVideo(source: ImageSource.gallery);
    if (file != null) {
      setState(() => _pickedVideo = file);
    }
  }

  Future<void> _fakeUpload() async {
    if (_pickedVideo == null) return;
    setState(() => _uploading = true);
    await Future.delayed(const Duration(seconds: 1)); // محاكاة رفع
    if (!mounted) return;
    setState(() => _uploading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم رفع الفيديو (تجريبي)')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final f = _pickedVideo?.path ?? '';

    return Scaffold(
      appBar: AppBar(title: Text('رفع فيديو', style: GoogleFonts.cairo())),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton.icon(
              onPressed: _pickVideo,
              icon: const Icon(Icons.video_library),
              label: Text('اختر فيديو من الهاتف', style: GoogleFonts.cairo()),
            ),
            const SizedBox(height: 16),
            if (_pickedVideo != null)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.play_circle),
                  title: Text(
                    'المسار: ${File(f).uri.pathSegments.isNotEmpty ? File(f).uri.pathSegments.last : f}',
                    style: GoogleFonts.cairo(),
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(f, style: GoogleFonts.cairo(fontSize: 12)),
                ),
              ),
            const Spacer(),
            ElevatedButton(
              onPressed: _uploading ? null : _fakeUpload,
              child: _uploading
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text('رفع', style: GoogleFonts.cairo()),
            ),
          ],
        ),
      ),
    );
  }
}
