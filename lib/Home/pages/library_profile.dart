import 'dart:io';
import 'package:flutter/material.dart';
import 'package:medibuddy/Model/profile_model.dart';
import 'package:medibuddy/services/in_memory_store.dart';
import '../../widgets/profile_widget.dart';
import 'package:image_picker/image_picker.dart';
import 'buddy.dart';
import '../../services/profile_api.dart';

class LibraryProfile extends StatefulWidget {
  final String accessToken;
  const LibraryProfile({
    Key? key,
    required this.accessToken,
    this.initialProfile,
  }) : super(key: key);

  final ProfileModel? initialProfile;

  @override
  State<LibraryProfile> createState() => _LibraryProfileState();
}

class _LibraryProfileState extends State<LibraryProfile> {
  final List<ProfileModel> profiles = [];
  static const String _imageBaseUrl =
      'http://82.26.104.199:3000'; //สร้าง base URL ของรูป

  bool _containsProfile(ProfileModel candidate) {
    return profiles.any((profile) {
      if (candidate.profileId.isNotEmpty) {
        return profile.profileId == candidate.profileId;
      }
      return profile.profileId.isEmpty &&
          profile.username == candidate.username &&
          profile.imagePath == candidate.imagePath;
    });
  }

  ImageProvider? buildProfileImage(String imagePath) {
    if (imagePath.isEmpty) return null;

    // รูปจาก server (public)
    if (imagePath.startsWith('/uploads')) {
      return NetworkImage('$_imageBaseUrl$imagePath');
    }

    // เผื่อ backend ส่ง URL เต็มมา
    if (imagePath.startsWith('http')) {
      return NetworkImage(imagePath);
    }

    // รูปจากเครื่อง (local)
    return FileImage(File(imagePath));
  }

  bool _loading = false;

  Future<void> _loadProfiles() async {
    setState(() => _loading = true);
    debugPrint('set loading=true');

    try {
      final api = ProfileApi('http://82.26.104.199:3000');
      final rows = await api.fetchProfiles(accessToken: widget.accessToken);

      debugPrint('=== FETCH PROFILES FROM API ===');
      debugPrint('RAW RESPONSE: $rows');

      final loaded = rows.map((m) {
        debugPrint('--- PROFILE ROW ---');
        debugPrint('profileId: ${m['profileId']}');
        debugPrint('profileName: ${m['profileName']}');
        debugPrint('profilePicture: ${m['profilePicture']}');

        return ProfileModel(
          username: (m['profileName'] ?? '').toString(),
          imagePath: (m['profilePicture'] ?? '').toString(),
          profileId: (m['profileId'] ?? '') is int
              ? m['profileId'] as int
              : int.tryParse((m['profileId'] ?? '').toString()) ?? 0,
        );
      }).toList();

      final merged = ProfileStore.mergeApi(loaded);

      if (!mounted) return;

      setState(() {
        profiles
          ..clear()
          ..addAll(merged);
      });
      ProfileStore.replaceAll(merged);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('โหลดโปรไฟล์ไม่สำเร็จ: $e')),
      );
    } finally {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    profiles.addAll(ProfileStore.items);

    // ถ้าอยากโชว์ initialProfile ทันที (ก่อนโหลด DB)
    if (widget.initialProfile != null) {
      final initial = widget.initialProfile!;
      if (!_containsProfile(initial)) {
        profiles.add(initial);
        ProfileStore.replaceAll(profiles);
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProfiles();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
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
              alignment: const Alignment(0, -0.8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Align(
                    child: SizedBox(
                      width: containerWidth,
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          maxWidth * 0.02,
                          maxHeight * 0.00,
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
                                child: _loading
                                    ? const Center(
                                        child: CircularProgressIndicator())
                                    : profiles.isEmpty
                                        ? const Center(
                                            child: Text(
                                              'ยังไม่มีผู้ใช้งาน',
                                              style:
                                                  TextStyle(color: Colors.grey),
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
                                                horizontalTitleGap:
                                                    maxWidth * 0.01,
                                                // ระยะห่างระหว่างภาพ กับ title
                                                minLeadingWidth: 0,
                                                // ทำให้ leading ไม่กินพื้นที่เกินจริง

                                                leading: profile
                                                        .imagePath.isNotEmpty
                                                    ? CircleAvatar(
                                                        radius: avatarSize,
                                                        backgroundImage:
                                                            buildProfileImage(
                                                                profile
                                                                    .imagePath),
                                                        child: profile.imagePath
                                                                .isEmpty
                                                            ? const Icon(
                                                                Icons.person)
                                                            : null,
                                                      )
                                                    : CircleAvatar(
                                                        radius: avatarSize,
                                                        backgroundColor:
                                                            const Color
                                                                .fromARGB(255,
                                                                224, 212, 233),
                                                        child: const Icon(
                                                            Icons.person),
                                                      ),

                                                title: Container(
                                                  padding: EdgeInsets.symmetric(
                                                    vertical: maxHeight * 0.02,
                                                    horizontal: maxWidth * 0.05,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: const Color.fromARGB(
                                                        136, 203, 219, 240),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            20),
                                                  ),
                                                  child: Align(
                                                    alignment:
                                                        Alignment.centerLeft,

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
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    InkWell(
                                                      onTap: () =>
                                                          _editProfile(index),
                                                      child: Padding(
                                                        padding:
                                                            EdgeInsets.all(1),
                                                        // เล็กมาก! ปรับได้
                                                        child: Icon(Icons.edit,
                                                            size: 25,
                                                            color: Colors
                                                                .blueGrey),
                                                      ),
                                                    ),
                                                    SizedBox(width: 6),
                                                    InkWell(
                                                      onTap: () =>
                                                          _confirmDeleteProfile(
                                                              index),
                                                      child: Padding(
                                                        padding:
                                                            EdgeInsets.all(1),
                                                        child: Icon(
                                                            Icons.delete,
                                                            size: 25,
                                                            color: Colors
                                                                .redAccent),
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
                                onPressed: _addProfile,
                                child: const Text(
                                  'เพิ่มโปรไฟล์ใหม่',
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 18),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(0, 0, maxWidth * 0.02, 0),
                      child: IconButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => MyBuddy()),
                            //หน้า OTP จะรู้แล้วว่า OTP นี้เป็นของอีเมลไหน
                          );
                        },
                        icon: Icon(Icons.navigate_next_outlined),
                        iconSize: maxWidth * 0.13,
                        color: Color(0xFF1F497D),
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

  // ฟังก์ชันแก้ไขชื่อโปรไฟล์ตาม index ที่เลือก
  void _editProfile(int index) {
    final profile = profiles[index];
    final TextEditingController editNameCtrl =
        TextEditingController(text: profile.username);

    // ⭐ เก็บ path รูปชั่วคราวไว้ใน dialog
    String? tempImagePath =
        profile.imagePath.isNotEmpty ? profile.imagePath : null;

    final size = MediaQuery.of(context).size;
    final maxWidth = size.width;
    final maxHeight = size.height;
    final avatarSize = maxWidth * 0.35;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          // ⭐ ให้ dialog มี state ของตัวเอง
          builder: (dialogContext, setStateDialog) {
            ImageProvider? currentImage;
            if (tempImagePath != null && tempImagePath!.isNotEmpty) {
              currentImage = FileImage(File(tempImagePath!));
            }

            return AlertDialog(
              insetPadding: EdgeInsets.symmetric(
                horizontal: maxWidth * 0.05,
                vertical: maxHeight * 0.05,
              ),
              backgroundColor: const Color(0xFFF5F5F5),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 🔹 ใช้ ProfileWidget ที่แยกไฟล์ไว้
                  ProfileWidget(
                    size: avatarSize, // ขนาดรูป
                    image: currentImage, // รูปปัจจุบัน
                    onCameraTap: () async {
                      final picker = ImagePicker();
                      final img =
                          await picker.pickImage(source: ImageSource.gallery);

                      if (img != null) {
                        // ✅ อัปเดต "tempImagePath" รูปใน popup เปลี่ยน
                        setStateDialog(() {
                          tempImagePath = img.path;
                        });
                      }
                    },
                  ),

                  SizedBox(height: maxHeight * 0.02),

                  TextField(
                    controller: editNameCtrl,
                    decoration: InputDecoration(
                      labelText: 'ชื่อโปรไฟล์',
                      fillColor: const Color.fromARGB(255, 237, 237, 237),
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('ยกเลิก'),
                ),
                TextButton(
                  onPressed: () async {
                    final newName = editNameCtrl.text.trim();
                    if (newName.isNotEmpty) {
                      setState(() {
                        profiles[index] = ProfileModel(
                          username: newName,
                          imagePath: tempImagePath ?? '',
                          profileId: profile.profileId,
                        );
                      });
                      ProfileStore.replaceAll(profiles);
                      final api = ProfileApi('http://82.26.104.199:3000');

                      File? newImageFile;
                      if (tempImagePath != null && tempImagePath!.isNotEmpty) {
                        final p = tempImagePath!;
                        final isLocalFile =
                            !p.startsWith('/uploads') && !p.startsWith('http');
                        if (isLocalFile) newImageFile = File(p);
                      }

                      setState(() => _loading = true);
                      try {
                        await api.updateProfile(
                          accessToken: widget.accessToken,
                          profileId: profile.profileId,
                          profileName: newName,
                          imageFile: newImageFile,
                        );

                        // ✅ รีโหลดจาก DB เพื่อให้ได้ profilePicture ล่าสุดจาก server แน่นอน
                        if (!mounted) return;
                        await _loadProfiles();

                        if (!mounted) return;
                        Navigator.of(dialogContext).pop();

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('แก้ไขข้อมูลเรียบร้อย')),
                        );
                      } catch (e) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('แก้ไขไม่สำเร็จ: $e')),
                        );
                      } finally {
                        if (!mounted) return;
                        setState(() => _loading = false);
                      }
                    }

                    Navigator.of(dialogContext).pop();

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
  Future<void> _deleteProfile(int index) async {
    final profile = profiles[index];
    final api = ProfileApi('http://82.26.104.199:3000');

    setState(() => _loading = true);

    try {
      await api.deleteProfile(
        accessToken: widget.accessToken,
        profileId: profile.profileId,
      );

      if (!mounted) return;
      setState(() {
        profiles.removeAt(index);
      });
      ProfileStore.replaceAll(profiles);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ลบโปรไฟล์เรียบร้อย')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ลบไม่สำเร็จ: $e')),
      );
    } finally {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

// เพิ่มโปรไฟล์ --------------------------------------------------------------------
  void _addProfile() {
    final TextEditingController nameCtrl = TextEditingController();

    // path รูปที่เลือกใน popup (ยังไม่มี → null)
    String? tempImagePath;

    final size = MediaQuery.of(context).size;
    final maxWidth = size.width;
    final maxHeight = size.height;
    final avatarSize = maxWidth * 0.35;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setStateDialog) {
            // แปลง path → ImageProvider เพื่อส่งเข้า ProfileWidget
            ImageProvider? currentImage;
            if (tempImagePath != null && tempImagePath!.isNotEmpty) {
              currentImage = buildProfileImage(tempImagePath!) ??
                  const AssetImage(''); // ถ้าไม่มี asset ก็ใช้ null ได้
            }

            return AlertDialog(
              insetPadding: EdgeInsets.symmetric(
                horizontal: maxWidth * 0.05,
                vertical: maxHeight * 0.05,
              ),
              backgroundColor: const Color(0xFFF5F5F5),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 🔹 วงกลมโปรไฟล์ + ปุ่มกล้อง (ใช้ widget เดิมเลย)
                  ProfileWidget(
                    size: avatarSize,
                    image: currentImage,
                    onCameraTap: () async {
                      final picker = ImagePicker();
                      final img =
                          await picker.pickImage(source: ImageSource.gallery);
                      if (img == null) return;

                      // ✅ อัปเดตรูปใน popup
                      setStateDialog(() {
                        tempImagePath = img.path;
                      });
                    },
                  ),

                  SizedBox(height: maxHeight * 0.02),

                  // 🔹 ช่องกรอกชื่อโปรไฟล์
                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      labelText: 'ชื่อโปรไฟล์',
                      fillColor: const Color.fromARGB(255, 237, 237, 237),
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('ยกเลิก'),
                ),
                TextButton(
                  onPressed: () {
                    final newName = nameCtrl.text.trim();
                    if (newName.isEmpty) {
                      // ถ้ายังไม่กรอกชื่อ ก็บอกผู้ใช้หน่อย
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('กรุณากรอกชื่อโปรไฟล์')),
                      );
                      return;
                    }

                    // ✅ เพิ่มโปรไฟล์ใหม่เข้า list หลัก
                    setState(() {
                      profiles.add(
                        ProfileModel(
                            username: newName,
                            imagePath: tempImagePath ?? '',
                            profileId: 0),
                      );
                    });
                    ProfileStore.replaceAll(profiles);

                    Navigator.of(dialogContext).pop();

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('เพิ่มโปรไฟล์ใหม่เรียบร้อย')),
                    );
                  },
                  child: const Text('บันทึก'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
