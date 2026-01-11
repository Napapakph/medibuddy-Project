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

  // ขนาดกรอบกล้องที่หน้าหลักกำหนดมา
  final double width;
  final double height;

  // ใช้กำหนดว่า “อนุญาตให้กดถ่ายรูป” ได้ไหม (เช่น กล้องพร้อมใช้งานหรือยัง)
  final bool isCaptureEnabled;

  // ตัว preview ของกล้อง (เช่น CameraPreview(controller))
  final Widget cameraPreview;

  // สถานะกำลังทำ OCR/ประมวลผลอยู่ไหม (ถ้า true จะโชว์ overlay + ปิดการกดปุ่ม)
  final bool isProcessing;

  // callback ตอนกดปุ่มเลือกรูปจากแกลเลอรี
  final VoidCallback onPickFromGallery;

  // callback ตอนกดปุ่มถ่ายรูป
  final VoidCallback onCapture;

  // callback ตอนกดสลับกล้องหน้า/หลัง
  final VoidCallback onToggleCamera;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      // จำกัดพื้นที่ของกรอบทั้งหมดให้อยู่ใน width/height นี้
      width: width,
      height: height,
      child: Stack(
        // clip แค่ “การวาดภาพ” ไม่ให้ตัดขอบ (เห็นของที่ล้นได้)
        // แต่ไม่ได้รับประกันว่า “แตะได้” นอกขอบ parent
        clipBehavior: Clip.none,
        children: [
          // พื้นหลังกล้อง (live preview) ทำมุมโค้ง
          ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: Container(
              // สีพื้นหลังกรณี preview ยังไม่พร้อม/มีช่องว่าง
              color: const Color(0xFFF2F5F9),
              child: cameraPreview,
            ),
          ),

          // เส้นกรอบสี่เหลี่ยมทับบน preview
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: const Color(0xFFB0BEC8),
                width: 2,
              ),
            ),
          ),

          // ขีดแนวตั้งด้านบนซ้าย/ขวา (ตกแต่ง)
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

          // ขีดแนวตั้งด้านล่างซ้าย/ขวา (ตกแต่ง)
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

          // ถ้ากำลังประมวลผล (OCR) ให้แสดง overlay ทับ + วงโหลด
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
            bottom: -40, // ⚠️🔎 จุดเสี่ยง: วางปุ่มให้ “ล้นออกนอก SizedBox”
            left: 0,
            right: 0,
            child: Material(
              // ใส่ Material เพื่อให้ InkWell มี surface สำหรับเอฟเฟกต์ ripple
              color: Colors.transparent,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // ปุ่มแกลเลอรี: ถ้า isProcessing เป็น true จะปิดการกด (onTap null)
                    _buildIconButton(
                      onTap: isProcessing ? null : onPickFromGallery,
                      child: _buildGalleryButton(),
                    ),

                    // ✅📸 จุดสำคัญ: ปุ่มถ่ายรูป
                    // enabled = กล้องพร้อม && ไม่ได้กำลังประมวลผล
                    _buildCaptureButton(
                      enabled: isCaptureEnabled && !isProcessing,
                      onTap:
                          isCaptureEnabled && !isProcessing ? onCapture : null,
                    ),

                    // ปุ่มสลับกล้อง: ถ้า isProcessing เป็น true จะปิดการกด
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

  // ขีดแนวตั้งสีเทาด้านข้างกรอบ (ตกแต่ง)
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

  // ห่อปุ่มไอคอนซ้าย/ขวาให้กดได้ด้วย InkWell + ripple
  Widget _buildIconButton({
    required VoidCallback? onTap,
    required Widget child,
  }) {
    return InkWell(
      onTap: onTap, // ถ้า null = ปุ่มกดไม่ได้
      borderRadius: BorderRadius.circular(24),
      splashColor: const Color(0xFF1F497D).withValues(alpha: 0.1),
      highlightColor: const Color(0xFF1F497D).withValues(alpha: 0.05),
      child: child,
    );
  }

  // ปุ่มเลือกรูปจากแกลเลอรี (ซ้ายล่าง) เป็นแค่หน้าตา UI
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

  // ✅📸 ปุ่มถ่ายรูป (ตรงกลางล่าง)
  Widget _buildCaptureButton({
    required bool enabled,
    required VoidCallback? onTap,
  }) {
    // สีหลักของปุ่มตอน active
    final Color activeColor = const Color(0xFF1F497D);

    // ถ้า enabled=false จะเปลี่ยนสีให้ดู disabled
    final Color borderColor = enabled ? activeColor : const Color(0xFFB0BEC8);
    final Color iconColor = enabled ? activeColor : const Color(0xFFB0BEC8);

    return InkWell(
      // ✅📸 ถ้า enabled=false จะ set onTap=null ทำให้ “กดไม่ได้”
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
            // ตอนนี้ใช้ icon รูปเท้าแมวแทนชัตเตอร์ (แค่หน้าตา)
            Icons.pets,
            color: iconColor,
            size: 36,
          ),
        ),
      ),
    );
  }

  // ปุ่มสลับกล้องหน้า/หลัง (ขวาล่าง) เป็นแค่หน้าตา UI
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
