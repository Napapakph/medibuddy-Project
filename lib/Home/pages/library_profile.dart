import 'dart:io';
import 'package:flutter/material.dart';
import 'package:medibuddy/Model/profile_model.dart';
import '../../widgets/profile_widget.dart';
import 'package:image_picker/image_picker.dart';
import 'buddy.dart';
import '../../services/profile_api.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LibraryProfile extends StatefulWidget {
  const LibraryProfile({
    Key? key,
    this.initialProfile,
  }) : super(key: key);

  final ProfileModel? initialProfile;

  @override
  State<LibraryProfile> createState() => _LibraryProfileState();
}

class _LibraryProfileState extends State<LibraryProfile> {
  final List<ProfileModel> profiles = [];
  String _imageBaseUrl = '';
  final ProfileApi api = ProfileApi();

  String? _getToken() {
    return Supabase.instance.client.auth.currentSession?.accessToken;
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

  ImageProvider ProfileImageDefault(String path) {
    if (path.isEmpty) {
      return const AssetImage('assets/default_profile.png');
    }

    if (path.startsWith('/')) {
      return NetworkImage('$_imageBaseUrl$path');
    }

    return const AssetImage('assets/default_profile.png');
  }

  bool _loading = false;

  Future<void> _loadProfiles() async {
    setState(() => _loading = true);

    try {
      final token = Supabase.instance.client.auth.currentSession?.accessToken;
      if (token == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Session หมดอายุ กรุณาเข้าสู่ระบบใหม่')),
        );
        return;
      }

      final rows = await api.fetchProfiles(accessToken: token);

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

      if (!mounted) return;

      setState(() {
        profiles
          ..clear()
          ..addAll(loaded);
      });
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

    // ถ้าอยากโชว์ initialProfile ทันที (ก่อนโหลด DB)
    if (widget.initialProfile != null) {
      profiles.add(widget.initialProfile!);
    }
    _imageBaseUrl = dotenv.env['API_BASE_URL'] ?? '';

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
          'โปรไฟล์ผู้ใช้',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1F497D),
      ),
      backgroundColor: const Color.fromARGB(255, 227, 242, 255),
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
                          maxWidth * 0.01,
                          maxHeight * 0.00,
                          maxWidth * 0.02,
                          maxHeight * 0.126,
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
                                                        radius: 30,
                                                        backgroundImage:
                                                            ProfileImageDefault(
                                                          profile.imagePath,
                                                        ),
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
                          ],
                        ),
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1F497D),
                        padding: EdgeInsets.symmetric(
                          horizontal: maxWidth * 0.06,
                          vertical: maxHeight * 0.02,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      onPressed: _addProfile,
                      child: const Text(
                        'เพิ่มโปรไฟล์ใหม่',
                        style: TextStyle(color: Colors.white, fontSize: 16),
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
                        iconSize: maxWidth * 0.15,
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

  // ฟังก์ชันแก้ไขชื่อโปรไฟล์ตาม index ที่เลือก -------------------------------------
  void _editProfile(int index) {
    final profile = profiles[index];
    final TextEditingController editNameCtrl =
        TextEditingController(text: profile.username);

    String? tempImagePath =
        profile.imagePath.isNotEmpty ? profile.imagePath : null;

    final size = MediaQuery.of(context).size;
    final maxWidth = size.width;
    final maxHeight = size.height;
    final avatarSize = maxWidth * 0.35;

    showDialog(
      context: context,
      builder: (dialogContext) {
        String? errorMessage; // เพิ่มตัวแปรเก็บ error message
        bool saving = false;

        return StatefulBuilder(
          builder: (dialogContext, setStateDialog) {
            ImageProvider? currentImage;

            if (tempImagePath != null && tempImagePath!.isNotEmpty) {
              currentImage = buildProfileImage(tempImagePath!);
            }

            return AlertDialog(
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 30.0,
                vertical: 24.0,
              ),
              backgroundColor: const Color(0xFFF5F5F5),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: double.maxFinite,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ProfileWidget(
                        size: avatarSize,
                        image: currentImage,
                        onCameraTap: () async {
                          final picker = ImagePicker();
                          final img = await picker.pickImage(
                              source: ImageSource.gallery);

                          if (img != null) {
                            setStateDialog(() {
                              tempImagePath = img.path;
                            });
                          }
                        },
                      ),
                      SizedBox(height: maxHeight * 0.03), // เพิ่มระยะห่าง
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
                          errorText: errorMessage, // แสดง error message
                        ),
                        onChanged: (value) {
                          if (errorMessage != null) {
                            setStateDialog(() {
                              errorMessage = null;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed:
                      saving ? null : () => Navigator.of(dialogContext).pop(),
                  child: const Text('ยกเลิก'),
                ),
                TextButton(
                  onPressed: saving
                      ? null
                      : () async {
                          final newName = editNameCtrl.text.trim();
                          if (newName.isEmpty) {
                            setStateDialog(() {
                              errorMessage = 'กรุณากรอกชื่อโปรไฟล์';
                            });
                            return;
                          }

                          // เช็คชื่อซ้ำ (ยกเว้นชื่อตัวเอง)
                          final isDuplicate = profiles.any((p) =>
                              p.username == newName &&
                              p.profileId != profile.profileId);
                          if (isDuplicate) {
                            setStateDialog(() {
                              errorMessage =
                                  'ชื่อโปรไฟล์นี้มีอยู่แล้ว กรุณาตั้งชื่อใหม่';
                            });
                            return;
                          }

                          File? newImageFile;
                          final p = tempImagePath;
                          if (p != null && p.isNotEmpty) {
                            final isLocalFile = !p.startsWith('/uploads') &&
                                !p.startsWith('http');
                            if (isLocalFile) newImageFile = File(p);
                          }

                          setStateDialog(() => saving = true);

                          try {
                            final api = ProfileApi();

                            await api.updateProfile(
                              accessToken: _getToken()!,
                              profileId: profile.profileId,
                              profileName: newName,
                              imageFile: newImageFile,
                            );

                            if (!mounted) return;

                            await _loadProfiles();
                            if (!mounted) return;

                            Navigator.of(dialogContext).pop();
                          } catch (e) {
                            if (!mounted) return;
                            setStateDialog(() {
                              errorMessage = 'แก้ไขไม่สำเร็จ: $e';
                              saving = false;
                            });
                          }
                        },
                  child: saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('บันทึก'),
                ),
              ],
            );
          },
        );
      },
    );
  }
  //--------------------------------------------------------------------

// Menu Item: Delete Profile -------------------------------------------
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
    final api = ProfileApi();

    setState(() => _loading = true);

    try {
      await api.deleteProfile(
        accessToken: _getToken()!,
        profileId: profile.profileId,
      );

      if (!mounted) return;
      setState(() {
        profiles.removeAt(index);
      });
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
//--------------------------------------------------------------------

  // เพิ่มโปรไฟล์ ---------------------------------------------------------
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
        String? errorMessage; // เพิ่มตัวแปรเก็บ error message
        bool isLoading = false; // ตัวแปร loading เฉพาะ dialog นี้

        return StatefulBuilder(
          builder: (dialogContext, setStateDialog) {
            // แปลง path → ImageProvider เพื่อส่งเข้า ProfileWidget
            ImageProvider? currentImage;
            if (tempImagePath != null && tempImagePath!.isNotEmpty) {
              currentImage = buildProfileImage(tempImagePath!);
            }

            return AlertDialog(
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 30,
                vertical: 24.0,
              ),
              backgroundColor: const Color(0xFFF5F5F5),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: double.maxFinite,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // วงกลมโปรไฟล์ + ปุ่มกล้อง (ใช้ widget เดิมเลย)
                      ProfileWidget(
                        size: avatarSize,
                        image: currentImage,
                        onCameraTap: () async {
                          final picker = ImagePicker();
                          final img = await picker.pickImage(
                              source: ImageSource.gallery);
                          if (img == null) return;

                          // อัปเดตรูปใน popup
                          setStateDialog(() {
                            tempImagePath = img.path;
                          });
                        },
                      ),

                      SizedBox(height: maxHeight * 0.03), // เพิ่มระยะห่าง

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
                          errorText: errorMessage, // แสดง error message
                        ),
                        onChanged: (value) {
                          if (errorMessage != null) {
                            setStateDialog(() {
                              errorMessage = null;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('ยกเลิก'),
                ),
                TextButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          final newName = nameCtrl.text.trim();
                          if (newName.isEmpty) {
                            setStateDialog(() {
                              errorMessage = 'กรุณากรอกชื่อโปรไฟล์';
                            });
                            return;
                          }

                          // เช็คชื่อซ้ำ
                          final isDuplicate =
                              profiles.any((p) => p.username == newName);
                          if (isDuplicate) {
                            setStateDialog(() {
                              errorMessage =
                                  'ชื่อโปรไฟล์นี้มีอยู่แล้ว กรุณาตั้งชื่อใหม่';
                            });
                            return;
                          }

                          setStateDialog(() => isLoading = true);

                          try {
                            await create_profile(
                              profileName: newName,
                              tempImagePath: tempImagePath, // อาจเป็น null ได้
                            );

                            if (!mounted) return;
                            Navigator.of(dialogContext)
                                .pop(); // ปิด dialog ก่อน
                          } catch (e) {
                            if (!mounted) return;
                            setStateDialog(() {
                              errorMessage = 'เพิ่มโปรไฟล์ไม่สำเร็จ: $e';
                              isLoading = false;
                            });
                          }
                        },
                  child: isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('บันทึก'),
                ),
              ],
            );
          },
        );
      },
    );
  }

// ฟังก์ชันสร้างโปรไฟล์ใหม่ในฐานข้อมูล
  Future<void> create_profile({
    required String profileName,
    String? tempImagePath,
  }) async {
    File? imageFile;

    if (tempImagePath != null && tempImagePath.isNotEmpty) {
      final isLocal = !tempImagePath.startsWith('/uploads') &&
          !tempImagePath.startsWith('http');
      if (isLocal) imageFile = File(tempImagePath);
    }

    setState(() => _loading = true);
    try {
      final api = ProfileApi();
      await api.createProfile(
        accessToken: _getToken()!,
        profileName: profileName.trim(),
        imageFile: imageFile,
      );

      if (!mounted) return;
      await _loadProfiles();
    } finally {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  //--------------------------------------------------------------------

// ฟังก์ชันอัปเดตโปรไฟล์ในฐานข้อมูล
  Future<void> update_profile({
    required int profileId,
    required String profileName,
    required String? tempImagePath,
  }) async {
    if (profileName.trim().isEmpty) {
      throw Exception('กรุณากรอกชื่อโปรไฟล์');
    }

    // ส่งไฟล์เฉพาะตอนเป็นไฟล์ local จริง ๆ
    File? imageFile;
    if (tempImagePath != null && tempImagePath.isNotEmpty) {
      final isLocal = !tempImagePath.startsWith('/uploads') &&
          !tempImagePath.startsWith('http');
      if (isLocal) imageFile = File(tempImagePath);
    }

    setState(() => _loading = true);
    try {
      await api.updateProfile(
        accessToken: _getToken()!,
        profileId: profileId,
        profileName: profileName.trim(),
        imageFile: imageFile, // ถ้าเป็น /uploads หรือ http จะไม่ส่งไฟล์ซ้ำ
      );

      if (!mounted) return;
      await _loadProfiles(); // sync กับ DB
    } finally {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }
}
