import 'package:flutter/material.dart';

class ProfileWidget extends StatelessWidget {
  const ProfileWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    const double avatarSize = 130.0;

    return SizedBox(
      width: avatarSize,
      height: avatarSize,
      child: Stack(
        children: [
          _buildProfileCircle(avatarSize),
          _buildCameraButton(avatarSize),
        ],
      ),
    );
  }
}

@override
// วิดเจ็ตรูปโปรไฟล์วงกลม ----------------------------------------
Widget _buildProfileCircle(double size) {
  final double radius = size / 2;

  return CircleAvatar(
    radius: radius, // ครึ่งหนึ่งของ avatarSize
    backgroundColor: const Color(0xFFE9EEF3),
    child: Icon(
      Icons.person,
      size: radius * 0.7, // สัดส่วนตามขนาดวง
      color: Colors.white,
    ),
  );
}

// วิดเจ็ตปุ่มกล้อง ------------------------------------------

// ปุ่มกล้องเล็กๆ ที่มุมล่างขวาของรูปโปรไฟล์ ------------------------
Widget _buildCameraButton(double size) {
  final double cameraSize = size * 0.28;

  return Positioned(
    bottom: size * 0.02,
    right: size * 0.02,
    child: GestureDetector(
      child: Container(
        width: cameraSize,
        height: cameraSize,
        decoration: BoxDecoration(
          color: const Color(0xFF1F497D),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color.fromARGB(255, 100, 100, 100).withOpacity(0.50),
              blurRadius: size * 0.03, // ใช้สัดส่วนให้เงาไม่เพี้ยน
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

  //-- ฟังก์ชันตอนกดปุ่มกล้อง ----------------------------------------