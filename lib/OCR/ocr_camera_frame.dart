import 'package:flutter/material.dart';

/// วิดเจ็ตกรอบกล้อง (live preview + โครงสี่เหลี่ยม + ปุ่มทั้งสาม)
/// แยก UI ออกมาจากหน้า CameraOcrPage เพื่อให้โค้ดหน้า main สั้นลง
class OcrCameraFrame extends StatelessWidget {
  const OcrCameraFrame({
    super.key,
    required this.width,
    required this.height,
    required this.isCaptureEnabled,
    required this.cameraPreview,
    required this.isProcessing,
    required this.onPickFromGallery,
    required this.onCapture,
    required this.onToggleCamera,
  });

  final double width;
  final double height;
  final bool isCaptureEnabled;
  final Widget cameraPreview;
  final bool isProcessing;
  final VoidCallback onPickFromGallery;
  final VoidCallback onCapture;
  final VoidCallback onToggleCamera;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // พื้นหลังกล้อง (live preview)
          ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: Container(
              color: const Color(0xFFF2F5F9),
              child: cameraPreview,
            ),
          ),
          // เส้นกรอบสี่เหลี่ยม
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: const Color(0xFFB0BEC8),
                width: 2,
              ),
            ),
          ),
          // ขีดแนวตั้งด้านบน
          Positioned(
            top: 24,
            left: 24,
            right: 24,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSideBar(),
                _buildSideBar(),
              ],
            ),
          ),
          // ขีดแนวตั้งด้านล่าง
          Positioned(
            bottom: 24,
            left: 24,
            right: 24,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSideBar(),
                _buildSideBar(),
              ],
            ),
          ),
          // ระหว่างกำลังประมวลผล OCR แสดง overlay ทับ
          if (isProcessing)
            Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(32),
              ),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Color(0xFF1F497D),
                  ),
                ),
              ),
            ),
          // แถวปุ่มด้านล่าง (แกลเลอรี, ถ่ายรูป, สลับกล้อง)
          Positioned(
            bottom: -40,
            left: 0,
            right: 0,
            child: Material(
              color: Colors.transparent,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildIconButton(
                      onTap: isProcessing ? null : onPickFromGallery,
                      child: _buildGalleryButton(),
                    ),
                    _buildCaptureButton(
                      enabled: isCaptureEnabled && !isProcessing,
                      onTap:
                          isCaptureEnabled && !isProcessing ? onCapture : null,
                    ),
                    _buildIconButton(
                      onTap: isProcessing ? null : onToggleCamera,
                      child: _buildSwitchCameraButton(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ขีดแนวตั้งสีเทาด้านข้างกรอบ
  Widget _buildSideBar() {
    return Container(
      width: 4,
      height: 60,
      decoration: BoxDecoration(
        color: const Color(0xFF707070),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Widget _buildIconButton({
    required VoidCallback? onTap,
    required Widget child,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      splashColor: const Color(0xFF1F497D).withValues(alpha: 0.1),
      highlightColor: const Color(0xFF1F497D).withValues(alpha: 0.05),
      child: child,
    );
  }

  // ปุ่มเลือกรูปจากแกลเลอรี (ซ้ายล่าง)
  Widget _buildGalleryButton() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFB0BEC8),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: const Icon(
        Icons.photo_library_outlined,
        size: 24,
        color: Color(0xFF1F497D),
      ),
    );
  }

  // ปุ่มถ่ายรูป (ตรงกลางล่าง)
  Widget _buildCaptureButton({
    required bool enabled,
    required VoidCallback? onTap,
  }) {
    final Color activeColor = const Color(0xFF1F497D);
    final Color borderColor = enabled ? activeColor : const Color(0xFFB0BEC8);
    final Color iconColor = enabled ? activeColor : const Color(0xFFB0BEC8);

    return InkWell(
      onTap: enabled ? onTap : null,
      customBorder: const CircleBorder(),
      splashColor: activeColor.withValues(alpha: 0.2),
      highlightColor: activeColor.withValues(alpha: 0.1),
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          border: Border.all(
            color: borderColor,
            width: 4,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Icon(
            Icons.pets,
            color: iconColor,
            size: 36,
          ),
        ),
      ),
    );
  }

  // ปุ่มสลับกล้องหน้า/หลัง (ขวาล่าง)
  Widget _buildSwitchCameraButton() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(
          color: const Color(0xFFB0BEC8),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: const Icon(
        Icons.cameraswitch,
        size: 26,
        color: Color(0xFF1F497D),
      ),
    );
  }
}
