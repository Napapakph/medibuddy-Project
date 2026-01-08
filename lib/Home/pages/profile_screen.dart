import 'package:flutter/material.dart';
import 'package:medibuddy/Model/profile_model.dart';
import 'library_profile.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../services/profile_api.dart';

class ProfileScreen extends StatefulWidget {
  final String accessToken;
  const ProfileScreen({super.key, required this.accessToken});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // final VoidCallback onCameraTap;    // ตอนกดปุ่มกล้อง
  final _formKey = GlobalKey<FormState>();
  var _usernameController = TextEditingController();
  // ตัวควบคุมข้อความชื่อผู้ใช้
  String? username;
  // เก็บชื่อผู้ใช้ที่สร้างเสร็จแล้ว
  // ค่าตั้งต้นของชื่อผู้ใช้
  ImageProvider? _profileImage; // เก็บ URL รูปโปรไฟล์
  String? profileImageUrl;
  bool _isLoading = false; // สถานะการโหลด
  File? _selectedImageFile;

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    debugPrint('=== PROFILE SCREEN ===');
    debugPrint('accessToken from widget: ${widget.accessToken}');
  }

  bool _isSupportedImage(File file) {
    final p = file.path.toLowerCase();
    return p.endsWith('.jpg') ||
        p.endsWith('.jpeg') ||
        p.endsWith('.png') ||
        p.endsWith('.webp');
  }

  void _goNext(ProfileModel profile) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => LibraryProfile(
            accessToken: widget.accessToken, initialProfile: profile),
      ),
    );
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
        // คำนวณขนาดรูปโปรไฟล์จากขนาดจอ
        double avatarSize = maxWidth * 0.50;
        avatarSize = avatarSize.clamp(100.0, 180.0); // อย่างน้อย 100 สูงสุด 180

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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        //SizedBox(height: maxHeight * 0.02),
                        // รูปโปรไฟล์------------------------------------------------
                        Align(
                            alignment: Alignment.center,
                            child: SizedBox(
                              width: avatarSize, // เส้นผ่านศูนย์กลาง
                              height: avatarSize,
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  _buildProfileCircle(avatarSize),
                                  _buildCameraButton(avatarSize),
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
                              fillColor:
                                  const Color.fromARGB(255, 255, 255, 255),
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
                        SizedBox(height: maxHeight * 0.05),
                        // ปุ่มบันทึกข้อมูล----------------------------------------------------------------------
                        Align(
                          alignment: Alignment.center,
                          child: ElevatedButton(
                            onPressed: _isLoading
                                ? null
                                : () async {
                                    if (!_formKey.currentState!.validate())
                                      return;

                                    setState(() => _isLoading = true);

                                    // ✅ สร้าง profile แบบ fallback ก่อน (ใช้ข้อมูล local)
                                    final fallbackProfile = ProfileModel(
                                      username: _usernameController.text.trim(),
                                      imagePath: profileImageUrl ?? '',
                                      profileId: 0,
                                    );

                                    try {
                                      debugPrint(
                                          'TOKEN: ${widget.accessToken}');

                                      // ถ้าไม่ได้เลือกรูป -> ข้ามการส่ง API ไปเลย แล้วไปหน้าถัดไป
                                      if (_selectedImageFile == null) {
                                        if (!mounted) return;
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                              content: Text(
                                                  'ไม่ได้อัปโหลดรูปไป DB (ยังไม่ได้เลือกรูป)')),
                                        );
                                      }

                                      debugPrint(
                                          'IMAGE PATH: ${_selectedImageFile?.path}');
                                      debugPrint(
                                          'IMAGE EXISTS: ${_selectedImageFile?.existsSync()}');

                                      // ✅ 1) สร้าง API client
                                      final api = ProfileApi(
                                          'http://82.26.104.199:3000');

                                      // ✅ 2) พยายามบันทึกลง database
                                      final result = await api.createProfile(
                                        accessToken: widget.accessToken,
                                        profileName:
                                            _usernameController.text.trim(),
                                        imageFile:
                                            _selectedImageFile!, // ตอนนี้ไม่ null แล้ว
                                      );

                                      if (!mounted) return;
                                      debugPrint(
                                          'CREATE PROFILE RESULT: $result');

                                      // ✅ 3) ถ้าสำเร็จ ใช้ข้อมูลจาก backend (กัน null ด้วย)
                                      final profilePicture =
                                          result['profilePicture']
                                                  ?.toString() ??
                                              '';

                                      final successProfile = ProfileModel(
                                        username:
                                            _usernameController.text.trim(),
                                        imagePath: profilePicture.isNotEmpty
                                            ? profilePicture
                                            : (profileImageUrl ?? ''),
                                        profileId: result['profileId'] is int
                                            ? result['profileId'] as int
                                            : int.tryParse(result['profileId']
                                                    .toString()) ??
                                                0,
                                      );

                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                            content:
                                                Text('บันทึกลง DB สำเร็จ')),
                                      );

                                      // ✅ 4) ไปหน้าถัดไป
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => LibraryProfile(
                                              accessToken: widget.accessToken,
                                              initialProfile: successProfile),
                                        ),
                                      );
                                    } catch (e) {
                                      // ✅ ถึงจะ error ก็ไปต่อด้วย fallback
                                      if (!mounted) return;

                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                            content: Text(
                                                'บันทึกลง DB ไม่สำเร็จ แต่จะไปต่อ: $e')),
                                      );
                                    } finally {
                                      if (!mounted) return;
                                      setState(() => _isLoading = false);
                                    }
                                    _goNext(fallbackProfile);
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
                      ],
                    ),
                  ),
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

// วิดเจ็ตรูปโปรไฟล์วงกลม ----------------------------------------
  Widget _buildProfileCircle(double size) {
    final double radius = size / 2;

    return CircleAvatar(
      radius: radius, // ครึ่งหนึ่งของ avatarSize
      backgroundColor: const Color(0xFFE9EEF3),
      backgroundImage: _profileImage,
      child: _profileImage == null
          ? Icon(
              Icons.person,
              size: radius * 0.7, // สัดส่วนตามขนาดวง
              color: Colors.white,
            )
          : null,
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
        onTap: _onCameraTap,
        child: Container(
          width: cameraSize,
          height: cameraSize,
          decoration: BoxDecoration(
            color: const Color(0xFF1F497D),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color:
                    const Color.fromARGB(255, 100, 100, 100).withOpacity(0.50),
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

// ฟังก์ชันตอนกดปุ่มกล้อง --------------------------------------------
  void _onCameraTap() async {
    final ImagePicker picker = ImagePicker(); // ตัวเลือกภาพ

//  ใส่ imageQuality เพื่อลดขนาดไฟล์ (ช่วย server)
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1024, // ทำให้เสถียรขึ้น / ลด timeout
    );
    if (image == null) {
      // ผู้ใช้กดปิด ไม่เลือกภาพ
      return;
    }

    final file = File(image.path);

    // เช็คชนิดรูปด้วย extension ก่อน (กัน heic)

    if (!_isSupportedImage(file)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('ไฟล์รูปนี้ยังไม่รองรับ กรุณาเลือกรูปเป็น JPG/PNG/WebP'),
        ),
      );
      return;
    }
    // ถ้าเลือกภาพได้ → อัปเดต state
    setState(() {
      _selectedImageFile = File(image.path); // ✅ เก็บไฟล์ไว้ส่ง API
      _profileImage = FileImage(_selectedImageFile!); // ใช้แสดง UI
      profileImageUrl = image.path; // (optional) เก็บ path
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('เปลี่ยนรูปโปรไฟล์สำเร็จ')),
    );
  }
}
