import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:medibuddy/widgets/app_drawer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../pages/login.dart';
import 'select_profile.dart';
import '../../Model/profile_model.dart';
import 'add_medicine/list_medicine.dart';
//import 'package:buddhist_datetime_dateformat/buddhist_datetime_dateformat.dart';

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
  static const String _imageBaseUrl = 'http://82.26.104.199:3000';
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
  bool _isLoading = false; // สถานะการโหลด

  @override
  void dispose() {
    super.dispose();
  }

  // Hamburger menu function --------------------------------------------------

  Future<void> logout(BuildContext context) async {
    await Supabase.instance.client.auth.signOut();

    if (!context.mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }
  // Hamburger menu function --------------------------------------------------

  ImageProvider _buildProfileImage(String path) {
    if (path.isEmpty) {
      return const AssetImage('assets/images/default_profile.png');
    }

    if (path.startsWith('/')) {
      return NetworkImage('$_imageBaseUrl$path');
    }

    if (path.startsWith('http')) {
      return NetworkImage(path);
    }

    return FileImage(File(path));
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

  // Bottom bar widget ----------------------------------------------------------
  Widget _buildBottomBar() {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: Color(0xFF1F497D),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.calendar_today, color: Colors.white),
          ),
          GestureDetector(
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const Home()),
              );
            },
            child: Container(
              width: 52,
              height: 52,
              decoration: const BoxDecoration(
                color: Color(0xFFB7DAFF),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.home, color: Color(0xFF1F497D)),
            ),
          ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ListMedicinePage()),
              );
            },
            icon: const Icon(Icons.medication, color: Color(0xFFB7DAFF)),
          ),
        ],
      ),
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
            final profile = widget.selectedProfile;
            final profileImage = _buildProfileImage(profile?.imagePath ?? '');
            final profileName = profile?.username ?? 'Profile';

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
                              Row(
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
                  _buildBottomBar(),
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
