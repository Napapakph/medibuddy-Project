import 'package:flutter/material.dart';
import 'package:medibuddy/Model/profile_model.dart';
import 'library_profile.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // final VoidCallback onCameraTap;    // ตอนกดปุ่มกล้อง
  final _formKey = GlobalKey<FormState>();
  var _usernameController =
      TextEditingController(); // ตัวควบคุมข้อความชื่อผู้ใช้
  String? username; // เก็บชื่อผู้ใช้ที่สร้างเสร็จแล้ว
  // ค่าตั้งต้นของชื่อผู้ใช้
  ImageProvider? _profileImage; // เก็บ URL รูปโปรไฟล์
  String? profileImageUrl;
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
                  // รูปโปรไฟล์------------------------------------------------
                  Align(
                      alignment: Alignment.center,
                      child: SizedBox(
                        width: 140, // เส้นผ่านศูนย์กลาง
                        height: 140,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            _buildProfileCircle(),
                            _buildCameraButton(),
                          ],
                        ),
                      )),
                  // รูปโปรไฟล์------------------------------------------------
                  SizedBox(height: maxHeight * 0.04),
                  // ช่องกรอกชื่อผู้ใช้-----------------------------------------------
                  Form(
                    key: _formKey,
                    child: TextFormField(
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
                      validator: (value) => value == null || value.isEmpty
                          ? 'กรุณากรอกชื่อผู้ใช้'
                          : null,
                    ),
                  ),
                  // ช่องกรอกชื่อผู้ใช้---------------------------------------------------------------------
                  SizedBox(height: maxHeight * 0.02),
                  // ปุ่มบันทึกข้อมูล----------------------------------------------------------------------
                  Align(
                    alignment: Alignment.center,
                    child: ElevatedButton(
                      onPressed: _isLoading
                          ? null
                          : () async {
                              if (!_formKey.currentState!.validate()) return;
                              setState(() => _isLoading = true);
                              final profile = ProfileModel(
                                  _usernameController.text.trim(),
                                  profileImageUrl ?? '');

                              profiles.add(profile);
                              // เพิ่มโปรไฟล์ใหม่ลงในรายการ
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content:
                                      Text('บันทึกข้อมูลเรียบร้อย: $profile'),
                                ),
                              );

                              setState(() => _isLoading = false);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      LibraryProfile(initialProfile: profile),
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

  Widget _buildProfileCircle() {
    return CircleAvatar(
      radius: 70, // ครึ่งนึงของ SizedBox 140
      backgroundColor: const Color(0xFFE9EEF3), // สีพื้นหลังเวลายังไม่มีรูป
      backgroundImage: _profileImage, // ถ้ามีรูปจะแสดงแทน backgroundColor
      child: _profileImage == null
          ? const Icon(
              Icons.person,
              size: 60,
              color: Colors.white,
            )
          : null,
      // ถ้ามีรูปแล้วจะไม่แสดงไอคอน
    );
  }

  Widget _buildCameraButton() {
    return Positioned(
      bottom: 4,
      right: 4,
      child: GestureDetector(
        onTap: _onCameraTap, // เรียกฟังก์ชันตอนกด
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFF1F497D),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(
            Icons.camera_alt,
            color: Colors.white,
            size: 20,
          ),
        ),
      ),
    );
  }

  void _onCameraTap() async {
    final ImagePicker picker = ImagePicker(); // ตัวเลือกภาพ

    // เปิดแกลเลอรี
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image == null) {
      // ผู้ใช้กดปิด ไม่เลือกภาพ
      return;
    }

    // ถ้าเลือกภาพได้ → อัปเดต state
    setState(() {
      _profileImage = FileImage(File(image.path));
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('เปลี่ยนรูปโปรไฟล์สำเร็จ')),
    );

    // 🔜 ภายหลัง: ตรงนี้เราสามารถใส่โค้ด image_picker เลือกรูปจากแกลเลอรี
    // แล้วเรียก setState(() { _profileImage = FileImage(file); });
  }
}
