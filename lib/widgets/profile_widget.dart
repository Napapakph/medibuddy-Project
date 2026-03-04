import 'package:flutter/material.dart';

class ProfileWidget extends StatelessWidget {
  final double size; // ขนาดวงโปรไฟล์
  final ImageProvider? image; // รูปโปรไฟล์ (ถ้า null → แสดงไอคอนคน)
  final VoidCallback onCameraTap; // ฟังก์ชันตอนกดปุ่มกล้อง

  const ProfileWidget({
    super.key,
    required this.size,
    required this.image,
    required this.onCameraTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          _buildProfileCircle(size),
          _buildCameraButton(size),
        ],
      ),
    );
  }

  // วงกลมรูปโปรไฟล์
  Widget _buildProfileCircle(double size) {
    final radius = size / 2;

    return CircleAvatar(
      radius: radius,
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      backgroundImage: image,
      child: image == null
          ? Icon(
              Icons.person,
              size: radius * 0.7,
              color: const Color.fromARGB(255, 188, 201, 219),
            )
          : null,
    );
  }

  // ปุ่มกล้อง
  Widget _buildCameraButton(double size) {
    final cameraSize = size * 0.28;

    return Positioned(
      bottom: size * 0.02,
      right: size * 0.02,
      child: GestureDetector(
        onTap: onCameraTap, // 🔥 เรียก callback ที่ส่งมาจากข้างนอก
        child: Container(
          width: cameraSize,
          height: cameraSize,
          decoration: BoxDecoration(
            color: const Color(0xFF1F497D),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: size * 0.03,
                offset: Offset(0, size * 0.01),
              ),
            ],
          ),
          child: Icon(
            Icons.camera_alt,
            color: Colors.white,
            size: cameraSize * 0.5,
          ),
        ),
      ),
    );
  }
}
