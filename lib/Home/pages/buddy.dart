import 'package:flutter/material.dart';
import '../../widgets/profile_widget.dart';

class MyBuddy extends StatefulWidget {
  const MyBuddy({super.key});

  @override
  State<MyBuddy> createState() => _MyBuddyState();
}

class _MyBuddyState extends State<MyBuddy> {
  bool _isLoading = false; // สถานะการโหลด

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: const Color.fromARGB(255, 235, 246, 255),
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          'บัดดี้ของคุณ',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1F497D),
        centerTitle: true,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxWidth = constraints.maxWidth;
            final maxHeight = constraints.maxHeight;

            //ถ้าจอกว้างแบบแท็บเล็ต
            final bool isTablet = maxWidth > 600;

            //จำกัดความกว้างสูงสุดของหน้าจอ
            final double containerWidth = isTablet ? 500 : maxWidth;

            return Center(
              child: Align(
                alignment: Alignment.topCenter,
                child: Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.only(top: maxHeight * 0.15),
                      child: Text(
                        'ผู้ช่วยคุณคือ . . .',
                        style: TextStyle(
                            fontSize: 30,
                            color: Color.fromARGB(255, 123, 187, 255),
                            fontWeight: FontWeight.bold,
                            fontStyle: FontStyle.normal), // รอฟ้อนใหม่
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(top: maxHeight * 0.05),
                      child: _buildBuddyAvatar(maxWidth), // 👈 ก้อนแมว+วงฟ้า
                    ),
                    Padding(
                      padding: EdgeInsets.only(top: maxHeight * 0.05),
                      child: Text(
                        'Meow',
                        style: TextStyle(
                            fontSize: 30,
                            color: Color(0xFF1F497D),
                            fontWeight: FontWeight.bold,
                            fontStyle: FontStyle.normal), // รอฟ้อนใหม่
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBuddyAvatar(double maxWidth) {
    // กำหนดขนาดก้อน avatar เป็นสี่เหลี่ยมจัตุรัส
    final double size = maxWidth * 0.6; // ขนาดวงกลมฟ้า
    final double catSize = size * 0.75; // ขนาดรูปแมวด้านใน

    return Stack(
      alignment: Alignment.center,
      children: [
        // 🔵 วงกลมพื้นหลังสีฟ้า
        Container(
          width: size,
          height: size, // ใช้ size เดียวกัน จะได้เป็นวงกลมจริง ๆ
          decoration: const BoxDecoration(
            color: Color(0xFFB7DAFF),
            shape: BoxShape.circle,
          ),
        ),

        // 🐱 รูปแมวทับด้านบน (ไม่ตัดรูป)
        Image.asset(
          'assets/main_mascot.png',
          width: catSize,
          height: catSize,
          fit: BoxFit.contain,
        ),
      ],
    );
  }
}
