import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';

/// ตัวช่วยครอปรูปภาพก่อนนำไปทำ OCR
/// แยกออกมาจากหน้า UI เพื่อให้โค้ดอ่านง่ายและเปลี่ยนสไตล์การครอปได้ง่ายขึ้น
class OcrImageCropper {
  const OcrImageCropper();

  /// รับไฟล์รูปต้นฉบับ แล้วเปิดหน้าให้ผู้ใช้ครอป
  /// ถ้าผู้ใช้กดยกเลิก จะคืนค่า null
  Future<File?> crop(File original) async {
    final cropped = await ImageCropper().cropImage(
      sourcePath: original.path,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'ครอบรูปชื่อยา',
          toolbarColor: const Color(0xFF1F497D),
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.original,
          lockAspectRatio: false,
        ),
        IOSUiSettings(
          title: 'ครอบรูปชื่อยา',
        ),
      ],
    );

    if (cropped == null) return null;
    return File(cropped.path);
  }
}
