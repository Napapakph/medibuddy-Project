import 'package:flutter/material.dart';
import 'package:medibuddy/Model/profile_model.dart';
import 'profile_screen.dart';
import 'dart:io';

class LibraryProfile extends StatefulWidget {
  const LibraryProfile({Key? key, this.initialProfile}) : super(key: key);

  final ProfileModel? initialProfile;

  @override
  State<LibraryProfile> createState() => _LibraryProfileState();
}

class _LibraryProfileState extends State<LibraryProfile> {
  final List<ProfileModel> profiles = [];
  // เก็บสถานะรูปโปรไฟล์ (ตอนนี้ยังไม่มีรูปจริง ใช้ null ไปก่อน)

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
            'ห้องสมุดโปรไฟล์',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: const Color(0xFF1F497D),
        ),
        backgroundColor: const Color.fromARGB(255, 235, 246, 255),
        body: SafeArea(
          child: LayoutBuilder(builder: (context, constraints) {
            final maxWidth = constraints.maxWidth;
            final maxHeight = constraints.maxHeight;

            //ถ้าจอกว้างแบบแท็บเล็ต
            final bool isTablet = maxWidth > 600;

            //จำกัดความกว้างสูงสุดของหน้าจอ
            final double containerWidth = isTablet ? 500 : maxWidth;

            return ListView.builder(
              itemCount: profiles.length,
              itemBuilder: (context, index) {
                final profile = profiles[index];
                return ListTile(
                  leading: (profile.imagePath != null &&
                          profile.imagePath!.isNotEmpty)
                      ? CircleAvatar(
                          backgroundImage: FileImage(File(profile.imagePath!)),
                        )
                      : const CircleAvatar(child: Icon(Icons.person)),
                  title: Text(profile.username),
                );
              },
            );
          }),
        ));
  }
}

/*
สรุป Flow การส่งข้อมูลทำงานแบบนี้
1. ProfileScreen
ผู้ใช้กรอกชื่อ
เลือกรูปจาก gallery → ได้ image.path
กดบันทึก → สร้าง ProfileModel(username, imagePath)
ส่งไปหน้า LibraryProfile

2. LibraryProfile
รับ model จากหน้าแรก
แสดงรูปด้วย FileImage(File(path))
แสดงชื่อด้วย Text(profile.username)
*/
