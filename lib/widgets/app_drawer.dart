import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../pages/login.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  void _go(BuildContext context, String route) {
    Navigator.pop(context);
    Navigator.pushReplacementNamed(context, route);
  }

  Future<void> logout(BuildContext context) async {
    Navigator.pop(context); // ปิด drawer ก่อน
    await Supabase.instance.client.auth.signOut();

    if (!context.mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
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
                          alignment: Alignment.bottomLeft,
                          child: Text(
                            'MediBuddy',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1F497D),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // ---------- Menu (scroll ได้) ----------
                    Expanded(
                      child: ListView(
                        padding: EdgeInsets.zero,
                        children: [
                          ListTile(
                            leading: const Icon(Icons.home),
                            title: const Text('หน้าหลัก'),
                            onTap: () => _go(context, '/home'),
                          ),
                          ListTile(
                            leading: const Icon(Icons.person_add),
                            title: const Text('เพิ่มผู้ใช้โปรไฟล์'),
                            onTap: () => _go(context, '/library_profile'),
                          ),
                          ListTile(
                            leading: const Icon(Icons.switch_account),
                            title: const Text('เลือกผู้ใช้โปรไฟล์'),
                            onTap: () => _go(context, '/select_profile'),
                          ),

                          // ถ้าเมนูเพิ่มในอนาคต ก็ใส่เพิ่มตรงนี้ได้
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
                            'Sign Out',
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
