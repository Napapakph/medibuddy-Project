import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:medibuddy/Model/profile_model.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  var _usernameController =
      TextEditingController(); // ตัวควบคุมข้อความชื่อผู้ใช้
  String? username; // เก็บชื่อผู้ใช้ที่สร้างเสร็จแล้ว
  // ค่าตั้งต้นของชื่อผู้ใช้
  String? profileImageUrl; // เก็บ URL รูปโปรไฟล์
  bool _isLoading = false; // สถานะการโหลด

  @override
  void dispose() {
    _usernameController.dispose();
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
      backgroundColor: const Color.fromARGB(255, 235, 246, 255),
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
              padding: EdgeInsetsGeometry.fromLTRB(24, maxHeight * 0.03, 24,
                  maxHeight * 0.02), // ระยะห่างด้านบน),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  //SizedBox(height: maxHeight * 0.02),
                  Align(
                    alignment: Alignment.center,
                    child: Icon(Icons.insert_photo,
                        size: maxHeight * 0.25, color: Colors.grey),
                  ),
                  SizedBox(height: maxHeight * 0.04),
                  // ช่องกรอกชื่อผู้ใช้-----------------------------------------------
                  Form(
                    child: TextFormField(
                      key: _formKey,
                      controller: _usernameController,
                      decoration: InputDecoration(
                        labelText: 'ชื่อผู้ใช้',
                        filled: true,
                        fillColor: const Color.fromARGB(255, 255, 255, 255),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  // ช่องกรอกชื่อผู้ใช้---------------------------------------------------------------------
                  SizedBox(height: maxHeight * 0.02),
                  // ปุ่มบันทึกข้อมูล----------------------------------------------------------------------
                  Align(
                    alignment: Alignment.center,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          //ProfileModel profile = new ProfileModel(username, profileImageUrl)
                          username = _usernameController.text.trim();
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('บันทึกข้อมูลเรียบร้อย: $username'),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                            vertical: maxHeight * 0.02,
                            horizontal: maxWidth * 0.03),
                        backgroundColor: Color(0xFF1F497D),
                        foregroundColor: Colors.black87,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text(
                        'บันทึกข้อมูล',
                        style: TextStyle(
                            fontSize: 16,
                            color: Color.fromARGB(255, 255, 255, 255)),
                      ),
                    ),
                  ),
                  // ปุ่มบันทึกข้อมูล---------------------------------------------------------------------
                  //รูปแมว ---------------------------------------------------------------------------

                  Align(
                    alignment: Alignment.bottomCenter,
                    child: SizedBox(
                      height: maxHeight * 0.4,
                      child: Image.asset(
                        'assets/cat_profile.png',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      })),
    );
  }
}
