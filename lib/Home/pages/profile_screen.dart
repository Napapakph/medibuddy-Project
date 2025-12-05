import 'package:flutter/material.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false; // สถานะการโหลด

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title:
            const Text('โปรไฟล์ของฉัน', style: TextStyle(color: Colors.white)),
        backgroundColor: Color(0xFF1F497D),
      ),
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.white,
      body: SafeArea(child: LayoutBuilder(builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final maxHeight = constraints.maxHeight;

        //ถ้าจอกว้างแบบแท็บเล็ต
        final bool isTablet = maxWidth > 600;

        //จำกัดความกว้างสูงสุดของหน้าจอ
        final double containerWidth = isTablet ? 500 : maxWidth;
        return Center(
          child: SizedBox(
            width: containerWidth,
            child: Padding(
              padding: EdgeInsetsGeometry.fromLTRB(24, maxHeight * 0.06, 24,
                  maxHeight * 0.04), // ระยะห่างด้านบน),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: maxHeight * 0.02),
                  Form(
                    child: TextFormField(
                      decoration: InputDecoration(
                        labelText: 'ชื่อผู้ใช้',
                        filled: true,
                        fillColor: Colors.grey[200],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: maxHeight * 0.02),
                  Align(
                    alignment: Alignment.center,
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                            vertical: maxHeight * 0.02,
                            horizontal: maxWidth * 0.03),
                        backgroundColor: Color(0xFF1F497D),
                        foregroundColor: Colors.black87,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      child: const Text(
                        'บันทึกข้อมูล',
                        style: TextStyle(
                            fontSize: 16,
                            color: Color.fromARGB(255, 255, 255, 255)),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        );
      })),
    );
  }
}
