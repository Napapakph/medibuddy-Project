import 'dart:io';
import 'package:flutter/material.dart';
import 'package:medibuddy/Model/profile_model.dart';
import 'profile_screen.dart';
import '../../widgets/profile_widget.dart';

class LibraryProfile extends StatefulWidget {
  const LibraryProfile({Key? key, this.initialProfile}) : super(key: key);

  final ProfileModel? initialProfile;

  @override
  State<LibraryProfile> createState() => _LibraryProfileState();
}

class _LibraryProfileState extends State<LibraryProfile> {
  final List<ProfileModel> profiles = [];

  @override
  void initState() {
    super.initState();
    if (widget.initialProfile != null) {
      profiles.add(widget.initialProfile!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'เพิ่มโปรไฟล์ผู้ใช้',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1F497D),
      ),
      backgroundColor: const Color.fromARGB(255, 235, 246, 255),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxWidth = constraints.maxWidth;
            final maxHeight = constraints.maxHeight;

            final bool isTablet = maxWidth > 600;
            final double containerWidth = isTablet ? 500 : maxWidth;

            final double listMaxHeight = maxHeight * 0.7;

            double avatarSize = constraints.maxWidth * 0.01;
            avatarSize = avatarSize.clamp(30, 60);

            return Align(
              alignment: Alignment.topCenter,
              child: SizedBox(
                width: containerWidth,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    maxWidth * 0.02,
                    maxHeight * 0.008,
                    maxWidth * 0.02,
                    maxHeight * 0.04,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 🔹 กรอบครอบรายการโปรไฟล์
                      SizedBox(
                        height: listMaxHeight,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: profiles.isEmpty
                              ? const Center(
                                  child: Text(
                                    'ยังไม่มีผู้ใช้งาน',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                )
                              : ListView.builder(
                                  padding: EdgeInsets.symmetric(
                                      vertical: maxHeight * 0.01,
                                      horizontal: maxWidth * 0.01),
                                  itemCount: profiles.length,
                                  itemBuilder: (context, index) {
                                    final profile = profiles[index];
                                    return ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      // ปิด padding default ของ ListTile
                                      horizontalTitleGap: maxWidth * 0.01,
                                      // ระยะห่างระหว่างภาพ กับ title
                                      minLeadingWidth: 0,
                                      // ทำให้ leading ไม่กินพื้นที่เกินจริง

                                      leading: (profile.imagePath.isNotEmpty)
                                          ? CircleAvatar(
                                              backgroundImage: FileImage(
                                                  File(profile.imagePath)),
                                              radius: avatarSize,
                                            )
                                          : const CircleAvatar(
                                              child: Icon(Icons.person)),
                                      title: Container(
                                        padding: EdgeInsets.symmetric(
                                          vertical: maxHeight * 0.02,
                                          horizontal: maxWidth * 0.05,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color.fromARGB(
                                              137, 217, 217, 217),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: Align(
                                          alignment: Alignment.centerLeft,

                                          child: Text(
                                            profile.username,
                                            style: const TextStyle(
                                              fontSize: 18,
                                              color: Colors.black,
                                            ),
                                          ), // ⭐ บังคับให้ชิดซ้าย),
                                        ),
                                      ),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          InkWell(
                                            onTap: () => _editProfile(index),
                                            child: Padding(
                                              padding: EdgeInsets.all(1),
                                              // เล็กมาก! ปรับได้
                                              child: Icon(Icons.edit,
                                                  size: 25,
                                                  color: Colors.blueGrey),
                                            ),
                                          ),
                                          SizedBox(width: 6),
                                          InkWell(
                                            onTap: () =>
                                                _confirmDeleteProfile(index),
                                            child: Padding(
                                              padding: EdgeInsets.all(1),
                                              child: Icon(Icons.delete,
                                                  size: 25,
                                                  color: Colors.redAccent),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ),
                      SizedBox(height: maxHeight * 0.03),
                      // 🔹 ปุ่มเพิ่มผู้ใช้งานใหม่ — จะอยู่ชิดกรอบเสมอ
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1F497D),
                            padding: EdgeInsets.symmetric(
                              horizontal: maxWidth * 0.1,
                              vertical: maxHeight * 0.02,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          onPressed: () {
                            print(
                                'เพิ่มผู้ใช้งานใหม่'); // TODO: Navigator.push ไปหน้าเพิ่มโปรไฟล์ แล้วรับค่า ProfileModel กลับมา
                          },
                          child: const Text(
                            'เพิ่มโปรไฟล์ใหม่',
                            style: TextStyle(color: Colors.white, fontSize: 18),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ฟังก์ชันแก้ไขชื่อโปรไฟล์ตาม index ที่เลือก
  void _editProfile(int index) {
    final profile = profiles[index];
    final TextEditingController editCtrl =
        TextEditingController(text: profile.username);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Color(0xFFF5F5F5),
          content: TextField(
            controller: editCtrl,
            decoration: InputDecoration(
              labelText: 'ชื่อโปรไฟล์',
              fillColor: Color.fromARGB(255, 237, 237, 237),
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('ยกเลิก'),
            ),
            TextButton(
              onPressed: () {
                final newName = editCtrl.text.trim();
                if (newName.isNotEmpty) {
                  setState(() {
                    profiles[index] =
                        ProfileModel(newName, profiles[index].imagePath);
                  }); // อัปเดตชื่อโปรไฟล์ในลิสต์
                }
                Navigator.of(context).pop();

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('แก้ไขข้อมูลเรียบร้อย')),
                );
              },
              child: const Text('บันทึก'),
            ),
          ],
        );
      },
    );
  }

  // ฟังก์ชันแจ้งเตือนถามยืนยันก่อนลบโปรไฟล์
  void _confirmDeleteProfile(int index) {
    final profile = profiles[index];
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('ลบโปรไฟล์'),
          content: Text('ต้องการลบโปรไฟล์ "${profile.username}" หรือไม่?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('ยกเลิก'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteProfile(index); // ลบจริงเมื่อกดยืนยัน
              },
              child: const Text(
                'ลบ',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  // ฟังก์ชันลบโปรไฟล์ออกจากลิสต์แล้วแจ้งเตือน
  void _deleteProfile(int index) {
    setState(() {
      profiles.removeAt(index);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('ลบโปรไฟล์เรียบร้อย')),
    );
  }
}

// widget สำหรับใช้ Navigator.push ถ้าต้องการหน้าฟอร์มเต็ม
class AddProfile extends StatefulWidget {
  const AddProfile({Key? key}) : super(key: key);

  @override
  State<AddProfile> createState() => _AddProfileState();
}

class _AddProfileState extends State<AddProfile> {
  @override
  Widget build(BuildContext context) {
    return const ProfileScreen();
  }
}
