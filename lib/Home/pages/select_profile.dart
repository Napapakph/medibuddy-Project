import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:medibuddy/widgets/app_drawer.dart';

import '../../services/profile_api.dart';
import '../../Model/profile_model.dart';
import 'home.dart';

class SelectProfile extends StatefulWidget {
  final String accessToken;

  const SelectProfile({
    super.key,
    required this.accessToken,
  });

  @override
  State<SelectProfile> createState() => _SelectProfileState();
}

class _SelectProfileState extends State<SelectProfile> {
  // เก็บ list profile ที่ดึงมาจาก API
  List<ProfileModel> profiles = [];

  // เก็บ index ของ profile ที่ผู้ใช้เลือก
  int? selectedIndex;

  // ใช้ควบคุมสถานะ loading ของหน้า
  bool _loading = true;

  // base url สำหรับต่อรูปจาก server (เพราะ profilePicture เป็น /uploads/...)
  final String _imageBaseUrl = 'http://82.26.104.199:3000';

  @override
  void initState() {
    super.initState();
    _loadProfiles();
  }

  /// ดึงข้อมูล profile จาก API list
  Future<void> _loadProfiles() async {
    setState(() => _loading = true);

    try {
      final api = ProfileApi('http://82.26.104.199:3000');

      final result = await api.fetchProfiles(
        accessToken: widget.accessToken,
      );

      // แปลงข้อมูลจาก API ให้เป็นโมเดลที่ UI ใช้ได้
      final mapped = result.map((e) {
        return ProfileModel(
          profileId: e['profileId'].toString(),
          username: (e['profileName'] ?? '').toString(),
          imagePath: (e['profilePicture'] ?? '').toString(),
        );
      }).toList();

      // อัปเดต state
      if (!mounted) return;
      setState(() {
        profiles = mapped;
      });
    } catch (e) {
      // ถ้าโหลดไม่สำเร็จ ให้แจ้งผู้ใช้
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('โหลดโปรไฟล์ไม่สำเร็จ: $e')),
      );
    } finally {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  /// สร้าง ImageProvider ให้รองรับทั้งรูปจาก server และกรณีไม่มีรูป
  /// - ถ้า path ว่าง: ใช้รูป default ใน assets
  /// - ถ้า path เริ่มด้วย "/uploads/..." : ต่อเป็น URL แล้วใช้ NetworkImage
  ImageProvider _buildProfileImage(String path) {
    if (path.isEmpty) {
      return const AssetImage('assets/images/default_profile.png');
    }

    // กรณี backend ส่งเป็น path เช่น /uploads/profile-pictures/xxx.jpg
    if (path.startsWith('/')) {
      return NetworkImage('$_imageBaseUrl$path');
    }

    // กรณีอื่น ๆ (กันพัง) ให้ fallback เป็น default
    return const AssetImage('assets/images/default_profile.png');
  }

  @override
  Widget build(BuildContext context) {
    // สร้างวันที่ไทยแบบ พ.ศ.
    final now = DateTime.now();
    final ce = now.year;
    final buddhistYear = now.year + 543;
    //แก้เป็น พ.ศ.
    final dayMonth = DateFormat('d MMMM').format(now);
    final thaiBuddhistDate = '$dayMonth $buddhistYear';

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'MediBuddy',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F497D),
            fontSize: 30,
          ),
        ),
        backgroundColor: const Color(0xFFB7DAFF),
        centerTitle: true,
      ),
      drawer: const AppDrawer(),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxWidth = constraints.maxWidth;
            final maxHeight = constraints.maxHeight;

            return Column(
              children: [
                // แถบสีฟ้าด้านบน + วันที่
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.only(bottom: maxHeight * 0.03),
                  color: const Color(0xFFB7DAFF),
                  child: Column(
                    children: [
                      Text(
                        thaiBuddhistDate,
                        style: const TextStyle(
                          fontSize: 18,
                          color: Color(0xFF1F497D),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: maxHeight * 0.05),

                // หัวข้อ
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: maxWidth * 0.05),
                  child: const Text(
                    'เลือกผู้ใช้งาน...',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                SizedBox(height: maxHeight * 0.03),

                // ส่วนแสดงข้อมูล (Loading / Empty / List)
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: _loading
                        // ถ้ากำลังโหลด แสดงวงกลม loading
                        ? const Center(child: CircularProgressIndicator())
                        : profiles.isEmpty
                            // ถ้าโหลดแล้วแต่ไม่มีข้อมูล
                            ? Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text('ยังไม่มีโปรไฟล์'),
                                    const SizedBox(height: 12),
                                    ElevatedButton(
                                      onPressed: _loadProfiles,
                                      child: const Text('โหลดใหม่'),
                                    ),
                                  ],
                                ),
                              )
                            // ถ้ามีข้อมูล แสดง list โปรไฟล์
                            : ListView.builder(
                                itemCount: profiles.length,
                                itemBuilder: (context, index) {
                                  final profile = profiles[index];
                                  final isSelected = selectedIndex == index;

                                  return GestureDetector(
                                    onTap: () {
                                      // เมื่อกดเลือกโปรไฟล์ ให้เก็บ index ไว้
                                      setState(() {
                                        selectedIndex = index;
                                      });
                                    },
                                    child: Container(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? Colors.blue.shade50
                                            : Colors.white,
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: isSelected
                                              ? Colors.blue
                                              : Colors.transparent,
                                          width: 2,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          // รูปโปรไฟล์ (วงกลม)
                                          CircleAvatar(
                                            radius: 30,
                                            backgroundImage: _buildProfileImage(
                                              profile.imagePath,
                                            ),
                                          ),
                                          const SizedBox(width: 16),

                                          // ชื่อโปรไฟล์
                                          Expanded(
                                            child: Text(
                                              profile.username,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                  ),
                ),

                SizedBox(height: maxHeight * 0.03),

                // ปุ่มยืนยัน
                Padding(
                  padding: EdgeInsets.only(bottom: maxHeight * 0.02),
                  child: ElevatedButton(
                    // ถ้ายังไม่เลือกโปรไฟล์ ให้ปุ่มกดไม่ได้
                    onPressed: _loading
                        ? null
                        : () {
                            // ดึงโปรไฟล์ที่เลือก
                            final selectedProfile = selectedIndex == null
                                ? null
                                : profiles[selectedIndex!];

                            // ไปหน้า Home พร้อมส่งข้อมูลโปรไฟล์ที่เลือกไปด้วย
                            // หมายเหตุ: Home ต้องมี constructor รับ selectedProfile
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => Home(
                                  selectedProfile: selectedProfile,
                                ),
                              ),
                            );
                          },
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        vertical: maxHeight * 0.02,
                        horizontal: maxWidth * 0.1,
                      ),
                      backgroundColor: const Color(0xFF1F497D),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: const Text(
                      'ยืนยัน',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
