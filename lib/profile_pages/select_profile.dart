import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:medibuddy/widgets/app_drawer.dart';
import 'package:lottie/lottie.dart';
import '../services/profile_api.dart';
import '../Model/profile_model.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../services/app_state.dart';
import '../services/auth_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  @override
  void initState() {
    super.initState();
    _imageBaseUrl = dotenv.env['API_BASE_URL'] ?? '';
    _loadProfiles();
  }

  Future<String?> _getAccessToken() async {
    // ใช้ AuthManager แทน Supabase โดยตรง
    return await AuthManager.service.getAccessToken();
  }

  Future<void> saveLastProfile(String profileId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lastProfileId', profileId);
  }

  Future<String?> getLastProfileId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('lastProfileId');
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
      // Sync to AppState cache for AlarmScreen profile name lookup
      AppState.instance.setCachedProfiles(mapped);
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
      backgroundColor: const Color.fromARGB(255, 224, 238, 255),
      appBar: AppBar(
        title: const Text(
          'MediBuddy',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: Color(0xFF2B4C7E),
            fontSize: 28,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: true,
        backgroundColor: Color.fromARGB(255, 191, 223, 255),
        iconTheme: const IconThemeData(color: Color(0xFF5C7A99)),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFEBF4FF), Color.fromARGB(255, 186, 221, 255)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.only(bottom: 15),
                  decoration: const BoxDecoration(
                    color: Color.fromARGB(255, 186, 221, 255),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(32),
                      bottomRight: Radius.circular(32),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      thaiBuddhistDate,
                      style: const TextStyle(
                        fontSize: 18,
                        color: Color(0xFF6B8DB0),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: Container(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4F9FF),
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFCDE0F5).withOpacity(0.5),
                          blurRadius: 24,
                          offset: const Offset(0, 12),
                        ),
                      ],
                      border: Border.all(
                        color: Colors.white,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'เลือกผู้ใช้งาน...',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2B4C7E),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        Expanded(
                          child: profiles.isEmpty && !_loading
                              ? Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text(
                                        'ยังไม่มีโปรไฟล์',
                                        style: TextStyle(
                                            color: Color(0xFF5C7A99),
                                            fontSize: 16),
                                      ),
                                      const SizedBox(height: 16),
                                      ElevatedButton(
                                        onPressed: _loadProfiles,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              const Color(0xFF7BAEE5),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 24, vertical: 12),
                                        ),
                                        child: const Text('โหลดใหม่',
                                            style:
                                                TextStyle(color: Colors.white)),
                                      ),
                                    ],
                                  ),
                                )
                              : ListView.builder(
                                  itemCount: profiles.length,
                                  itemBuilder: (context, index) {
                                    final profile = profiles[index];
                                    final isSelected = selectedIndex == index;

                                    return Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 16),
                                      child: GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            selectedIndex = index;
                                          });

                                          AppState.instance.setSelectedProfile(
                                            profileId: profile.profileId,
                                            name: profile.username,
                                            imagePath: profile.imagePath,
                                          );
                                        },
                                        child: AnimatedContainer(
                                          duration:
                                              const Duration(milliseconds: 200),
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius:
                                                BorderRadius.circular(20),
                                            boxShadow: [
                                              BoxShadow(
                                                color: isSelected
                                                    ? const Color(0xFF7BAEE5)
                                                        .withOpacity(0.4)
                                                    : const Color(0xFFE2EAF2)
                                                        .withOpacity(0.5),
                                                blurRadius: isSelected ? 12 : 8,
                                                offset: const Offset(0, 4),
                                              ),
                                            ],
                                            border: Border.all(
                                              color: isSelected
                                                  ? const Color(0xFF7BAEE5)
                                                  : Colors.transparent,
                                              width: 2,
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              CircleAvatar(
                                                radius: 32,
                                                backgroundColor:
                                                    const Color(0xFFF0F7FF),
                                                backgroundImage:
                                                    _buildProfileImage(
                                                  profile.imagePath,
                                                ),
                                              ),
                                              const SizedBox(width: 20),
                                              Expanded(
                                                child: Text(
                                                  profile.username,
                                                  style: TextStyle(
                                                    fontSize: 20,
                                                    fontWeight: isSelected
                                                        ? FontWeight.bold
                                                        : FontWeight.w600,
                                                    color:
                                                        const Color(0xFF2B4C7E),
                                                  ),
                                                ),
                                              ),
                                              if (isSelected)
                                                const Icon(
                                                  Icons.check_circle_rounded,
                                                  color: Color(0xFF7BAEE5),
                                                  size: 28,
                                                ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: canConfirm
                          ? () async {
                              AppState.instance.currentProfileId =
                                  selectedProfile.profileId;
                              final pid = selectedProfile.profileId;
                              await saveLastProfile(pid.toString());
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
                        backgroundColor:
                            const Color.fromARGB(255, 152, 190, 231),
                        disabledBackgroundColor: const Color(0xFFD6E9FC),
                        shadowColor: const Color(0xFF7BAEE5).withOpacity(0.5),
                        elevation: canConfirm ? 8 : 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      child: Text(
                        'ยืนยัน',
                        style: TextStyle(
                          color: canConfirm
                              ? Colors.white
                              : const Color(0xFF9ABAE0),
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
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
                  Container(
                    padding: const EdgeInsets.all(5),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Lottie.asset(
                          'assets/lottie/loader_cat.json',
                          width: 180,
                          height: 180,
                          repeat: true,
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'กำลังโหลด…',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
