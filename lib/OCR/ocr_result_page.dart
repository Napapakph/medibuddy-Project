import 'dart:io';

import 'package:flutter/material.dart';
import '../widgets/medicine_step_timeline.dart';
import '../Model/medicine_model.dart';

// หน้าจอแสดงข้อความ "สแกนสำเร็จ!" สั้น ๆ ก่อนเด้งไปหน้าแก้ไขผลลัพธ์
class OcrSuccessPage extends StatefulWidget {
  final MedicineDraft draft;

  const OcrSuccessPage({
    super.key,
    required this.imageFile,
    required this.recognizedText,
    required this.draft,
  });

  final File imageFile;
  final String recognizedText;

  @override
  State<OcrSuccessPage> createState() => _OcrSuccessPageState();
}

class _OcrSuccessPageState extends State<OcrSuccessPage> {
  // ดีเลย์ 1 วินาที แล้วเปลี่ยนไปหน้า OcrResultPage
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => OcrResultPage(
            imageFile: widget.imageFile,
            recognizedText: widget.recognizedText,
          ),
        ),
      );
    });
  }

  // UI หน้าสแกนสำเร็จ
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1F497D),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFE8F0F8),
                border: Border.all(
                  color: Colors.white,
                  width: 4,
                ),
              ),
              child: const Center(
                child: Icon(
                  Icons.check,
                  size: 72,
                  color: Color(0xFF1F497D),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'สแกน\nสำเร็จ!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// หน้าจอแสดงผลลัพธ์ OCR และให้แก้ไข/กดค้นหา
class OcrResultPage extends StatefulWidget {
  const OcrResultPage({
    super.key,
    required this.imageFile,
    required this.recognizedText,
  });

  final File imageFile;
  final String recognizedText;

  @override
  State<OcrResultPage> createState() => _OcrResultPageState();
}

class _OcrResultPageState extends State<OcrResultPage> {
  late final TextEditingController _controller;

  // สร้าง controller พร้อมเอาข้อความจาก OCR มาใส่เริ่มต้น
  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.recognizedText);
  }

  // ลบ controller ตอนออกจากหน้านี้
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // UI หลักของหน้าแก้ไข/ค้นหายาที่ได้จาก OCR
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1F497D),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: true,
        title: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'แก้ไขยาที่เกี่ยวข้อง',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 4),
            Text(
              '> ค้นหายา',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  MedicineStepTimeline(currentStep: 2),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F5F9),
                  borderRadius: BorderRadius.circular(24),
                ),
                padding: const EdgeInsets.all(16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.file(
                    widget.imageFile,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'ชื่อยา',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _controller,
                maxLines: 3,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFFF2F5F9),
                  hintText: 'ผลลัพธ์ที่สแกนได้จะแสดงที่นี่',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1F497D),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () {
                    final text = _controller.text.trim();
                    if (text.isEmpty) return;
                    Navigator.of(context).pop(text);
                  },
                  icon: const Icon(Icons.search, color: Colors.white),
                  label: const Text(
                    'ค้นหา',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({
    required this.icon,
    this.disabled = false,
  });

  final IconData icon;
  final bool disabled;

  // ปุ่มวงกลมไอคอนด้านบนรูปยา
  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: disabled ? 0.4 : 1,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          border: Border.all(
            color: const Color(0xFF1F497D),
            width: 2,
          ),
        ),
        child: Icon(
          icon,
          size: 20,
          color: const Color(0xFF1F497D),
        ),
      ),
    );
  }
}
