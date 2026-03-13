import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';

Future<File?> cropImageFile(
  File original, {
  String toolbarTitle = 'Crop image',
  CropAspectRatioPreset? aspectRatioPreset,
  bool lockAspectRatio = false,
}) async {
  final cropped = await ImageCropper().cropImage(
    sourcePath: original.path,
    uiSettings: [
      AndroidUiSettings(
        toolbarTitle: toolbarTitle,
        toolbarColor: const Color(0xFFC1DEFF),
        toolbarWidgetColor: const Color(0xFF2B4C7E),
        initAspectRatio: aspectRatioPreset ?? CropAspectRatioPreset.original,
        lockAspectRatio: lockAspectRatio,
      ),
      IOSUiSettings(
        title: toolbarTitle,
      ),
    ],
  );

  if (cropped == null) return null;
  return File(cropped.path);
}
