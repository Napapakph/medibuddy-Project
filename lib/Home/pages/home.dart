import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:medibuddy/widgets/app_drawer.dart';
import '../../Model/profile_model.dart';
import 'select_profile.dart';
import '../../services/app_state.dart';
import '../../Home/pages/select_profile.dart';
import '../../widgets/bottomBar.dart';

class Home extends StatefulWidget {
  final ProfileModel? selectedProfile;

  const Home({
    super.key,
    this.selectedProfile,
  });

  @override
  State<Home> createState() => _Home();
}

class _Home extends State<Home> {
  static const String _imageBaseUrl = 'http://82.26.104.98:3000';
  final List<_MedicineReminder> _reminders = [
    _MedicineReminder(
      time: '07:00 น.',
      name: 'ยาแก้แพ้',
      meal: 'หลังอาหาร',
      pills: '1 เม็ด',
    ),
    _MedicineReminder(
      time: '12:00 น.',
      name: 'ยาแก้ไอ',
      meal: 'หลังอาหาร',
      pills: '1 เม็ด',
    ),
    _MedicineReminder(
      time: '18:00 น.',
      name: 'ยาแก้แพ้',
      meal: 'หลังอาหาร',
      pills: '1 เม็ด',
    ),
    _MedicineReminder(
      time: '21:00 น.',
      name: 'ยาฆ่าเชื้อ',
      meal: 'ก่อนอาหาร',
      pills: '1 เม็ด',
    ),
  ];
  String? _profileName; // ✅ PROFILE_BIND: resolved name
  String? _profileImagePath; // ✅ PROFILE_BIND: resolved image path
  bool _profileBound = false; // ⚠️ GUARD: bind once
  int? _profileId;
  bool _isLoading = false; // สถานะการโหลด

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_profileBound) return; // ⚠️ GUARD: bind once

    final routeArgs =
        ModalRoute.of(context)?.settings.arguments; // ✅ PROFILE_BIND

    int? resolvedProfileId;
    String? resolvedProfileName;
    String? resolvedProfileImagePath;
    _profileId = resolvedProfileId ?? AppState.instance.currentProfileId;

    if (routeArgs is Map) {
      final rawId = routeArgs['profileId'];
      if (rawId is int) {
        resolvedProfileId = rawId;
      } else if (rawId != null) {
        resolvedProfileId = int.tryParse(rawId.toString());
      }

      final rawName = routeArgs['profileName'] ?? routeArgs['username'];
      resolvedProfileName = rawName?.toString();

      final rawImage = routeArgs['profileImage'] ?? routeArgs['imagePath'];
      resolvedProfileImagePath = rawImage?.toString();
    } else if (routeArgs is int) {
      resolvedProfileId = routeArgs;
    }

    resolvedProfileId ??= widget.selectedProfile?.profileId;
    resolvedProfileName ??= widget.selectedProfile?.username;
    resolvedProfileImagePath ??= widget.selectedProfile?.imagePath;

    setState(() {
      // 🔥 FIX: trigger UI rebuild after binding

      _profileName =
          (resolvedProfileName != null && resolvedProfileName.trim().isNotEmpty)
              ? resolvedProfileName.trim()
              : 'Profile'; // ✅ PROFILE_BIND
      _profileImagePath =
          (resolvedProfileImagePath ?? '').trim(); // ✅ PROFILE_BIND
      _profileBound = true; // ⚠️ GUARD
    });

    debugPrint(
        '🏠 HOME bound profileId=$_profileId name="$_profileName" image="$_profileImagePath"');
    debugPrint(
        '🧪 HOME routeArgs = ${ModalRoute.of(context)?.settings.arguments} '
        '(type=${ModalRoute.of(context)?.settings.arguments.runtimeType})');
  }

  @override
  void dispose() {
    super.dispose();
  }

  ImageProvider _buildProfileImage(String path) {
    final p = path.trim(); // 🔥 FIX: trim

    if (p.isEmpty || p.toLowerCase() == 'null') {
      return const AssetImage('assets/cat_profile.png');
    }

    if (p.startsWith('http://') || p.startsWith('https://')) {
      return NetworkImage(p);
    }

    // ✅ FIX: server-relative "/uploads/..."
    if (p.startsWith('/')) {
      return NetworkImage('$_imageBaseUrl$p');
    }

    // ✅ FIX: relative "uploads/..." -> treat as network
    if (p.contains('/')) {
      return NetworkImage('$_imageBaseUrl/$p');
    }

    return FileImage(File(p));
  }

  void _toggleReminder(int index) {
    setState(() {
      _reminders[index].isTaken = !_reminders[index].isTaken;
    });
  }

  Widget _buildReminderCard(BuildContext context, int index) {
    final reminder = _reminders[index];
    final isTaken = reminder.isTaken;
    final checkColor =
        isTaken ? const Color(0xFF1F497D) : const Color(0xFF9EC6F5);
    final timeColor =
        isTaken ? const Color(0xFF1F497D) : const Color(0xFF6FA8DC);

    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color:
                    isTaken ? const Color(0xFF1F497D) : const Color(0xFFD6E3F3),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                InkWell(
                  onTap: () => _toggleReminder(index),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: checkColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.check, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reminder.time,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: timeColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        reminder.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.circle,
                            size: 6,
                            color: Color(0xFF6FA8DC),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            reminder.meal,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6FA8DC),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 56,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        reminder.pills,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6FA8DC),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Comments coming soon')),
            );
          },
          icon: const Icon(
            Icons.chat_bubble_outline,
            color: Color(0xFF7FA9DD),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'MediBuddy',
          style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F497D),
              fontSize: 30),
        ),
        backgroundColor: Color(0xFFB7DAFF),
        centerTitle: true,
        leading: Builder(
          builder: (context) {
            return IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            );
          },
        ),
      ),
      drawer: const AppDrawer(),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxWidth = constraints.maxWidth;
            final maxHeight = constraints.maxHeight;

            //ถ้าจอกว้างแบบแท็บเล็ต
            final bool isTablet = maxWidth > 600;

            //จำกัดความกว้างสูงสุดของหน้าจอ
            final double containerWidth = isTablet ? 500 : maxWidth;
            // ใช้ DateTime + intl ได้เลย เพราะ main() init ไว้แล้ว
            final now = DateTime.now();
            final buddhistYear = now.year + 543;
            final dayMonth = DateFormat('d MMMM').format(now);
            final thaiBuddhistDate = '$dayMonth $buddhistYear';
            final profileImage = _buildProfileImage(
                _profileImagePath ?? ''); // ✅ PROFILE_BIND: image
            final profileName =
                _profileName ?? 'Profile'; // ✅ PROFILE_BIND: name

            return Align(
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.only(bottom: maxHeight * 0.03),
                    color: const Color(0xFFB7DAFF), // สีฟ้าของเดียร์
                    child: Column(
                      children: [
                        Text(
                          thaiBuddhistDate,
                          style: TextStyle(
                            fontSize: 18,
                            color: Color(0xFF1F497D),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: SizedBox(
                        width: containerWidth,
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: maxWidth * 0.05,
                            vertical: maxHeight * 0.02,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              InkWell(
                                borderRadius: BorderRadius.circular(40),
                                onTap: () {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const SelectProfile(),
                                    ),
                                  );
                                },
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 22,
                                      backgroundImage: profileImage,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      profileName,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF1F497D),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: maxHeight * 0.02),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE8F2FF),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: _reminders.isEmpty
                                      ? const Center(
                                          child: Text('No reminders yet'),
                                        )
                                      : ListView.separated(
                                          itemCount: _reminders.length,
                                          separatorBuilder: (_, __) =>
                                              const SizedBox(height: 12),
                                          itemBuilder: _buildReminderCard,
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  BottomBar(
                    currentRoute: '/home',
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _MedicineReminder {
  final String time;
  final String name;
  final String meal;
  final String pills;
  bool isTaken;

  _MedicineReminder({
    required this.time,
    required this.name,
    required this.meal,
    required this.pills,
    this.isTaken = false,
  });
}
