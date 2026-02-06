import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:medibuddy/widgets/app_drawer.dart';
import 'package:lottie/lottie.dart';
import '../../services/profile_api.dart';
import '../../Model/profile_model.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/app_state.dart';

// ถ้าคุณมีหน้า login จริง ๆ ให้ import แล้วเปลี่ยน route ได้
// import 'login.dart';

class SelectProfile extends StatefulWidget {
  const SelectProfile({super.key});

  @override
  State<SelectProfile> createState() => _SelectProfileState();
}

class _SelectProfileState extends State<SelectProfile> {
  List<ProfileModel> profiles = [];
  int? selectedIndex;
  bool _loading = true;
  String _imageBaseUrl = '';

  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _imageBaseUrl = dotenv.env['API_BASE_URL'] ?? '';
    _loadProfiles();
  }

  Future<String?> _getAccessToken() async {
    // ปกติจะมีอยู่แล้วหลัง login
    final token = supabase.auth.currentSession?.accessToken;
    if (token != null && token.isNotEmpty) return token;

    return null;
  }

  Future<void> _loadProfiles() async {
    if (!mounted) return;
    setState(() => _loading = true);

    try {
      final token = await _getAccessToken();

      if (token == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ไม่พบการเข้าสู่ระบบ กรุณา Login ใหม่')),
        );

        Navigator.of(context).pop();

        return;
      }

      final api = ProfileApi();
      final result = await api.fetchProfiles(accessToken: token);

      final mapped = result.map((e) {
        return ProfileModel(
          profileId: e['profileId'] is int
              ? e['profileId'] as int
              : int.tryParse((e['profileId'] ?? '').toString()) ?? 0,
          username: (e['profileName'] ?? '').toString(),
          imagePath: (e['profilePicture'] ?? '').toString(),
        );
      }).toList();

      if (!mounted) return;
      setState(() {
        profiles = mapped;
        // ถ้า list เปลี่ยนแล้ว index เดิมเกินขอบเขต ให้ reset
        if (selectedIndex != null && selectedIndex! >= profiles.length) {
          selectedIndex = null;
        }
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('โหลดโปรไฟล์ไม่สำเร็จ: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  ImageProvider _buildProfileImage(String path) {
    if (path.isEmpty) {
      return const AssetImage('assets/default_profile.png');
    }

    if (path.startsWith('/')) {
      return NetworkImage('$_imageBaseUrl$path');
    }

    return const AssetImage('assets/default_profile.png');
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final buddhistYear = now.year + 543;
    final dayMonth = DateFormat('d MMMM').format(now);
    final thaiBuddhistDate = '$dayMonth $buddhistYear';

    final selectedProfile =
        (selectedIndex == null) ? null : profiles[selectedIndex!];

    final canConfirm = !_loading && selectedProfile != null;

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
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      drawer: const AppDrawer(),
      body: Stack(
        children: [
          SafeArea(
            child: LayoutBuilder(
          builder: (context, constraints) {
            final maxWidth = constraints.maxWidth;
            final maxHeight = constraints.maxHeight;

            return Column(
              children: [
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
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: profiles.isEmpty
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
                            : ListView.builder(
                                itemCount: profiles.length,
                                itemBuilder: (context, index) {
                                  final profile = profiles[index];
                                  final isSelected = selectedIndex == index;

                                  return GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        selectedIndex = index;
                                      });

                                      // ✅ จุดสำคัญ: บอก AppState ว่าเลือกโปรไฟล์ไหน
                                      AppState.instance.setSelectedProfile(
                                        profileId: profile.profileId,
                                        name: profile.username,
                                        imagePath: profile.imagePath,
                                      );

                                      debugPrint(
                                        '✅ Selected profile: '
                                        'id=${profile.profileId}, '
                                        'name=${profile.username}, '
                                        'image=${profile.imagePath}',
                                      );
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
                                          CircleAvatar(
                                            radius: 30,
                                            backgroundImage: _buildProfileImage(
                                              profile.imagePath,
                                            ),
                                          ),
                                          const SizedBox(width: 16),
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
                Padding(
                  padding: EdgeInsets.only(bottom: maxHeight * 0.02),
                  child: ElevatedButton(
                    onPressed: canConfirm
                        ? () {
                            AppState.instance.currentProfileId =
                                selectedProfile.profileId;
                            final pid = selectedProfile.profileId;
                            Navigator.pushReplacementNamed(
                              context,
                              '/home',
                              arguments: {
                                'profileId': pid,
                                'profileName': selectedProfile.username,
                                'profileImage': selectedProfile.imagePath,
                              },
                            );

                            debugPrint(
                                '================= check select ProfileID ==================');
                            debugPrint(
                                'Selected Profile ID: ${selectedProfile.profileId}');
                          }
                        : null,
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
      if (_loading)
        Positioned.fill(
          child: Stack(
            alignment: Alignment.center,
            children: [
              const ModalBarrier(
                dismissible: false,
                color: Colors.black26,
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Lottie.asset(
                    'assets/lottie/loader_cat.json',
                    width: 180,
                    height: 180,
                    repeat: true,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'กำลังโหลด…',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ],
          ),
        ),
        ],
      ),
    );
  }
}
