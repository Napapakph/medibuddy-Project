import 'dart:io';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// ตัวช่วยทำ OCR ด้วย ML Kit
class OcrTextService {
  final TextRecognizer _recognizer =
      TextRecognizer(script: TextRecognitionScript.latin);

  /// รับไฟล์รูปภาพ แล้วคืนค่าข้อความที่อ่านได้ (trim แล้ว)
  Future<String> recognize(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final recognized = await _recognizer.processImage(inputImage);
    return recognized.text.trim();
  }

  /// ปิดทรัพยากรของ TextRecognizer
  void dispose() {
    _recognizer.close();
  }
}
