import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:medibuddy/widgets/app_drawer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../pages/login.dart';
import 'home.dart';

//import 'package:buddhist_datetime_dateformat/buddhist_datetime_dateformat.dart';

class SelectProfile extends StatefulWidget {
  const SelectProfile({super.key});

  @override
  State<SelectProfile> createState() => _SelectProfile();
}

class _SelectProfile extends State<SelectProfile> {
  bool _isLoading = false; // สถานะการโหลด

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> logout(BuildContext context) async {
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
                  SizedBox(height: maxHeight * 0.05),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: maxWidth * 0.05),
                      child: Text(
                        'Select Profile',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const Home()),
                      );
                      // ปุ่มยืนยัน -----------------------------------------------
                    },
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                          vertical: maxHeight * 0.02,
                          horizontal: maxWidth * 0.1),
                      backgroundColor: const Color(0xFF1F497D),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: const Text(
                      'ยืนยัน',
                      style: TextStyle(
                        color: Color.fromARGB(255, 255, 255, 255),
                        fontSize: 16,
                      ),
                    ),
                  ),
                  // ปุ่มยืนยัน -----------------------------------------------
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
