import 'dart:io';
import 'package:flutter/material.dart';
import '../pages/login.dart';
import '../services/authen_login.dart';
import '../services/app_state.dart';
import 'package:icofont_flutter/icofont_flutter.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  void _go(
    BuildContext context,
    String route, {
    Object? arguments,
  }) {
    // ถ้าไปหน้า LibraryProfile หรือ UserRequest ให้เคลียร์ Stack แล้วเอา Home รองไว้ข้างล่าง
    // เพื่อให้กด Back แล้วกลับไปหน้า Home เสมอ และมีปุ่มย้อนกลับ
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
    final _authLogoutAPI = AuthenLogout();

    // await Supabase.instance.client.auth.signOut();
    await _authLogoutAPI.signOut();

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
      backgroundColor: const Color.fromARGB(255, 245, 250, 255),
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final h = constraints.maxHeight;

            // ✅ Responsive: จำกัดความกว้าง drawer บนจอใหญ่
            final drawerWidth = w.clamp(280.0, 420.0);

            // ✅ Responsive spacing
            final pad = (drawerWidth * 0.05).clamp(12.0, 20.0);
            final bottomPad = (h * 0.02).clamp(8.0, 16.0);

            return Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: drawerWidth,
                child: Column(
                  children: [
                    // ---------- Header ----------
                    SizedBox(
                      height: (h * 0.18).clamp(120.0, 170.0),
                      child: const DrawerHeader(
                          decoration: BoxDecoration(color: Color(0xFFB7DAFF)),
                          child: Align(
                            child: Text(
                              'MediBuddy',
                              style: TextStyle(
                                fontSize: 35,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1F497D),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          )),
                    ),

                    // ---------- Menu (scroll ได้) ----------
                    Expanded(
                      child: ListView(
                        padding: EdgeInsets.zero,
                        children: [
                          ListTile(
                            leading: Image.asset(
                              'assets/cat_home_drawer.png',
                              width: 30,
                              height: 30,
                              // color: Color.fromARGB(255, 69, 68, 87), // Optional: tint if needed, but usually images are full color
                            ),
                            title: const Text('หน้าหลัก'),
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
                          ListTile(
                            leading: const Icon(
                              IcoFontIcons.pills,
                              color: Color.fromARGB(255, 69, 68, 87),
                              size: 30,
                            ),
                            title: const Text('รายการยาของฉัน'),
                            onTap: () => _go(context, '/list_medicine',
                                arguments:
                                    pid == null ? null : {'profileId': pid}),
                          ),
                          ListTile(
                              leading: const Icon(
                                Icons.find_in_page_rounded,
                                size: 30,
                                color: Color.fromARGB(255, 69, 68, 87),
                              ),
                              title: const Text('ค้นหายา'),
                              onTap: () => _go(context, '/search_medicine',
                                  arguments:
                                      pid == null ? null : {'profileId': pid})),
                          ListTile(
                            leading: const Icon(Icons.history,
                                size: 30,
                                color: Color.fromARGB(255, 69, 68, 87)),
                            title: const Text('ประวัติการทานยา'),
                            onTap: () => _go(context, '/history'),
                          ),
                          ListTile(
                            leading: const Icon(Icons.favorite,
                                size: 30,
                                color: Color.fromARGB(255, 69, 68, 87)),
                            title: const Text('กำลังติดตาม'),
                            onTap: () => _go(context, '/following'),
                          ),
                          ListTile(
                            leading: const Icon(Icons.people,
                                size: 30,
                                color: Color.fromARGB(255, 69, 68, 87)),
                            title: const Text('ผู้ติดตาม'),
                            onTap: () => _go(context, '/follower'),
                          ),
                          ListTile(
                            leading: const Icon(Icons.person_add_alt_rounded,
                                size: 30,
                                color: Color.fromARGB(255, 69, 68, 87)),
                            title: const Text('ผู้ใช้โปรไฟล์'),
                            onTap: () => _go(context, '/library_profile'),
                          ),
                          ListTile(
                            leading: const Icon(Icons.account_circle,
                                size: 30,
                                color: Color.fromARGB(255, 69, 68, 87)),
                            title: const Text('เลือกผู้ใช้โปรไฟล์'),
                            onTap: () => _go(context, '/select_profile'),
                          ),
                          ListTile(
                            leading: const Icon(Icons.feedback,
                                size: 30,
                                color: Color.fromARGB(255, 69, 68, 87)),
                            title: const Text('ข้อเสนอแนะ'),
                            onTap: () => _go(context, '/user_request'),
                          ),
                        ],
                      ),
                    ),

                    // ---------- Logout (ติดล่างสุด) ----------
                    Padding(
                      padding: EdgeInsets.fromLTRB(pad, 0, pad, bottomPad),
                      child: Align(
                        alignment: Alignment.bottomRight,
                        child: ElevatedButton(
                          onPressed: () => logout(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                const Color.fromARGB(255, 171, 56, 56),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'ออกจากระบบ',
                            style: TextStyle(color: Colors.white),
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
