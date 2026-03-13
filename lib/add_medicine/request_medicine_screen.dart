import 'dart:io';
import '../services/request_api.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../OCR/ocr_global.dart';
import '../services/auth_manager.dart';
import 'package:bot_toast/bot_toast.dart';
import '../widgets/image_cropper_helper.dart';

class RequestMedicinePage extends StatefulWidget {
  final String medicineName;

  const RequestMedicinePage({
    super.key,
    required this.medicineName,
  });

  @override
  State<RequestMedicinePage> createState() => _RequestMedicinePageState();
}

class _RequestMedicinePageState extends State<RequestMedicinePage> {
  String _imagePath = '';
  bool _saving = false;
  static const int _maxImageBytes = 5 * 1024 * 1024;

  String _formatBytes(int bytes) {
    final mb = bytes / (1024 * 1024);
    return '${mb.toStringAsFixed(2)} MB';
  }

  Future<File> _resizeImageIfNeeded(File file) async {
    final originalBytes = await file.length();
    debugPrint(
      '🖼️ image size before resize: ${_formatBytes(originalBytes)} ($originalBytes bytes)',
    );

    if (originalBytes <= _maxImageBytes) {
      return file;
    }

    var targetPath =
        file.path.replaceFirst(RegExp(r'\.[a-zA-Z0-9]+$'), '_resized.jpg');
    if (targetPath == file.path) {
      targetPath = '${file.path}_resized.jpg';
    }

    final XFile? result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      targetPath,
      quality: 85,
      minWidth: 1920,
      minHeight: 1920,
      format: CompressFormat.jpeg,
    );

    final outputFile = result != null ? File(result.path) : file;
    final outputBytes = await outputFile.length();
    debugPrint(
      '🖼️ image size after resize: ${_formatBytes(outputBytes)} ($outputBytes bytes)',
    );
    return outputFile;
  }

  @override
  void initState() {
    super.initState();
    if (globalOcrImage != null) {
      _imagePath = globalOcrImage!.path;
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: source);
    if (image == null) return;

    File file = File(image.path);
    if (source == ImageSource.gallery) {
      final cropped = await cropImageFile(
        file,
        toolbarTitle: 'ครอบรูปยา',
      );
      if (cropped == null) return;
      file = cropped;
    }

    final resizedFile = await _resizeImageIfNeeded(file);
    if (!mounted) return;

    setState(() {
      _imagePath = resizedFile.path;
    });
  }

  Future<String?> _getToken() async {
    return await AuthManager.service.getAccessToken();
  }

  Future<void> _submitRequest() async {
    try {
      final token = await _getToken();

      if (token == null || token.isEmpty) {
        throw Exception('ไม่พบ token กรุณาเข้าสู่ระบบใหม่');
      }

      await sendUserRequest(
        accessToken: token, // ✅ ตอนนี้เป็น String แน่นอน
        requestType: 'ADD_MEDICINE',
        requestTitle: widget.medicineName,
        requestDetails: 'add medicine for user',
        pictureFile: _imagePath.isNotEmpty
            ? await _resizeImageIfNeeded(File(_imagePath))
            : null,
      );

      if (!mounted) return;
      globalOcrImage = null;
      BotToast.showCustomText(
        duration: const Duration(seconds: 2),
        align: const Alignment(0, 0.5),
        toastBuilder: (_) {
          return Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 114, 178, 121),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'ส่งคำร้องเรียบร้อยแล้ว',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          );
        },
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      BotToast.showCustomText(
        duration: const Duration(seconds: 2),
        align: const Alignment(0, 0.5),
        toastBuilder: (_) {
          return Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 114, 178, 121),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'ส่งคำร้องไม่สำเร็จ',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color.fromARGB(255, 234, 244, 255),
                Color.fromARGB(255, 193, 222, 255)
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF5A81BB)),
        title: const Text(
          'ส่งคำร้องขอเพิ่มยา',
          style: TextStyle(
              color: Color(0xFF2B4C7E),
              fontWeight: FontWeight.w700,
              fontSize: 18),
        ),
      ),
      backgroundColor: const Color(0xFFF0F6FF),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'ชื่อยา',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2B4C7E),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 255, 255, 255),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(widget.medicineName),
              ),
              const SizedBox(height: 20),
              const Text(
                'รูปยา',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2B4C7E),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 255, 255, 255),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Stack(
                    children: [
                      if (_imagePath.isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.file(
                            File(_imagePath),
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.scaleDown,
                          ),
                        )
                      else
                        const Center(
                          child: Icon(
                            Icons.photo,
                            size: 64,
                            color: Color(0xFF9AA7B8),
                          ),
                        ),
                      if (_imagePath.isNotEmpty)
                        Positioned(
                          top: 12,
                          right: 12,
                          child: _ImageCircleButton(
                            icon: Icons.close_rounded,
                            onTap: () {
                              setState(() {
                                _imagePath = '';
                                globalOcrImage = null;
                              });
                            },
                          ),
                        ),
                      Positioned(
                        right: 12,
                        bottom: 12,
                        child: Row(
                          children: [
                            _ImageCircleButton(
                              icon: Icons.camera_alt,
                              onTap: () => _pickImage(ImageSource.camera),
                            ),
                            const SizedBox(width: 8),
                            _ImageCircleButton(
                              icon: Icons.photo_library,
                              onTap: () => _pickImage(ImageSource.gallery),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _submitRequest,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5A81BB),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'ยืนยัน',
                          style: TextStyle(color: Colors.white, fontSize: 16),
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

class _ImageCircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _ImageCircleButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(
          color: Color(0xFF5A81BB),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}
