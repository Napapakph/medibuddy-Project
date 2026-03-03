import 'dart:io';
import 'package:flutter/material.dart';
import '../authen_pages/login_screen.dart';
import '../services/auth_manager.dart';
import '../services/app_state.dart';
import 'package:icofont_flutter/icofont_flutter.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  static const _navy = Color(0xFF1F497D);
  static const _iconColor = Color.fromARGB(255, 69, 68, 87);

  void _go(
    BuildContext context,
    String route, {
    Object? arguments,
  }) {
    if (route == '/library_profile' || route == '/user_request') {
      final pid = AppState.instance.currentProfileId;
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/home',
        (Route<dynamic> route) => false,
        arguments: {
          'profileId': pid,
          'profileName': AppState.instance.currentProfileName,
          'profileImage': AppState.instance.currentProfileImagePath,
        },
      );
      Navigator.of(context).pushNamed(route, arguments: arguments);
    } else {
      Navigator.pushReplacementNamed(
        context,
        route,
        arguments: arguments,
      );
    }
  }

  Future<void> logout(BuildContext context) async {
    await AuthManager.service.logout();

    if (!context.mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final pid = AppState.instance.currentProfileId;

    return Drawer(
      backgroundColor: const Color.fromARGB(255, 253, 254, 255),
      child: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final h = constraints.maxHeight;

            final drawerWidth = w.clamp(280.0, 420.0);
            final pad = (drawerWidth * 0.05).clamp(12.0, 20.0);
            final bottomPad = (h * 0.02).clamp(8.0, 16.0);

            return Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: drawerWidth,
                child: Column(
                  children: [
                    // ========== Header with gradient ==========
                    Container(
                      height: (h * 0.18).clamp(120.0, 170.0),
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0xFF6FA8DC), // ฟ้าเข้มด้านบน
                            Color(0xFFBFE1FF), // ฟ้าอ่อนกลาง
                            Color(0xFFF5FAFF), // เกือบขาวด้านล่าง
                          ],
                          stops: [0.0, 0.5, 1.0],
                        ),
                      ),
                      child: const Center(
                        child: Padding(
                          padding: EdgeInsets.only(top: 40),
                          child: Text(
                            'MediBuddy',
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.w800,
                              color: _navy,
                              letterSpacing: 1.2,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),

                    // ========== Menu ==========
                    Expanded(
                      child: ListView(
                        padding: EdgeInsets.zero,
                        children: [
                          const SizedBox(height: 4),

                          // --- กลุ่ม 1: หลัก ---
                          _DrawerMenuItem(
                            icon: Image.asset(
                              'assets/cat_home_drawer.png',
                              width: 30,
                              height: 30,
                              color: _iconColor,
                            ),
                            title: 'หน้าหลัก',
                            onTap: () => _go(
                              context,
                              '/home',
                              arguments: {
                                'profileId': pid,
                                'profileName':
                                    AppState.instance.currentProfileName,
                                'profileImage':
                                    AppState.instance.currentProfileImagePath,
                              },
                            ),
                          ),
                          _DrawerMenuItem(
                            icon: const Icon(IcoFontIcons.pills,
                                color: _iconColor, size: 28),
                            title: 'รายการยาของฉัน',
                            onTap: () => _go(context, '/list_medicine',
                                arguments:
                                    pid == null ? null : {'profileId': pid}),
                          ),
                          _DrawerMenuItem(
                            icon: const Icon(Icons.find_in_page_rounded,
                                size: 28, color: _iconColor),
                            title: 'ค้นหายา',
                            onTap: () => _go(context, '/search_medicine',
                                arguments:
                                    pid == null ? null : {'profileId': pid}),
                          ),

                          // --- Divider ---
                          const _DrawerDivider(),

                          // --- กลุ่ม 2: ประวัติ + ติดตาม ---
                          _DrawerMenuItem(
                            icon: const Icon(Icons.history,
                                size: 28, color: _iconColor),
                            title: 'ประวัติการทานยา',
                            onTap: () => _go(context, '/history'),
                          ),
                          _DrawerMenuItem(
                            icon: Icon(MdiIcons.heartCircle,
                                size: 28, color: _iconColor),
                            title: 'กำลังติดตาม',
                            onTap: () => _go(context, '/following'),
                          ),
                          _DrawerMenuItem(
                            icon: const Icon(Icons.people,
                                size: 28, color: _iconColor),
                            title: 'ผู้ติดตาม',
                            onTap: () => _go(context, '/follower'),
                          ),

                          // --- Divider ---
                          const _DrawerDivider(),

                          // --- กลุ่ม 3: โปรไฟล์ + อื่นๆ ---
                          _DrawerMenuItem(
                            icon: const Icon(Icons.person_add_alt_rounded,
                                size: 28, color: _iconColor),
                            title: 'โปรไฟล์ผู้ใช้',
                            onTap: () => _go(context, '/library_profile'),
                          ),
                          _DrawerMenuItem(
                            icon: const Icon(Icons.account_circle,
                                size: 28, color: _iconColor),
                            title: 'เลือกผู้ใช้โปรไฟล์',
                            onTap: () => _go(context, '/select_profile'),
                          ),
                          _DrawerMenuItem(
                            icon: const Icon(Icons.feedback,
                                size: 28, color: _iconColor),
                            title: 'ข้อเสนอแนะ',
                            onTap: () => _go(context, '/user_request'),
                          ),
                        ],
                      ),
                    ),

                    // ========== Logout ==========
                    Padding(
                      padding: EdgeInsets.only(bottom: 20, left: 100),
                      child: SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () => logout(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                const Color.fromARGB(255, 178, 65, 65),
                            foregroundColor: Colors.white,
                            elevation: 3,
                            shadowColor: Colors.black26,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            'ออกจากระบบ',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
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
    );
  }
}

// ===== Custom Menu Item =====
class _DrawerMenuItem extends StatelessWidget {
  final Widget icon;
  final String title;
  final VoidCallback onTap;

  const _DrawerMenuItem({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      splashColor: const Color(0xFFE3F1FF),
      highlightColor: const Color(0xFFE3F1FF),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            SizedBox(width: 36, height: 30, child: Center(child: icon)),
            const SizedBox(width: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1F3A5F),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ===== Divider =====
class _DrawerDivider extends StatelessWidget {
  const _DrawerDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Divider(
        height: 1,
        thickness: 1,
        color: const Color(0xFFD6E3F3),
      ),
    );
  }
}
