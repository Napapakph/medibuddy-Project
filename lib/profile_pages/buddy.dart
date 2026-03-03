import 'package:flutter/material.dart';
import 'select_profile.dart';

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
      backgroundColor: const Color(0xFFF0F6FF),
      appBar: AppBar(
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color.fromARGB(255, 234, 244, 255),
                Color.fromARGB(255, 193, 222, 255),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF5A81BB)),
        centerTitle: true,
        title: const Text(
          'บัดดี้ของคุณ',
          style: TextStyle(
            color: Color(0xFF2B4C7E),
            fontWeight: FontWeight.w700,
            fontSize: 20,
            letterSpacing: 0.3,
          ),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxWidth = constraints.maxWidth;
            final maxHeight = constraints.maxHeight;

            //ถ้าจอกว้างแบบแท็บเล็ต
            final bool isTablet = maxWidth > 600;

            return Align(
              child: Column(
                children: [
                  // ⭐ ส่วนบนทั้งหมด → อยู่ TopCenter เสมอ
                  Expanded(
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
                                color: Color(0xFF7BAEE5),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.only(top: maxHeight * 0.05),
                            child: _buildBuddyAvatar(maxWidth),
                          ),
                          Padding(
                            padding: EdgeInsets.only(top: maxHeight * 0.05),
                            child: Text(
                              'Meow',
                              style: TextStyle(
                                fontSize: 30,
                                color: Color(0xFF2B4C7E),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ⭐ ปุ่มด้านล่างสุด
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: maxWidth * 0.05,
                        bottom: maxHeight * 0.05,
                      ),
                      child: IconButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SelectProfile(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.navigate_next_outlined),
                        iconSize: maxWidth * 0.13,
                        color: const Color(0xFF5A81BB),
                      ),
                    ),
                  ),
                ],
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
        //  วงกลมพื้นหลังสีฟ้า
        Container(
          width: size,
          height: size, // ใช้ size เดียวกัน จะได้เป็นวงกลมจริง ๆ
          decoration: const BoxDecoration(
            color: Color(0xFFDAEBFF),
            shape: BoxShape.circle,
          ),
        ),

        //  รูปแมวทับด้านบน (ไม่ตัดรูป)
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
