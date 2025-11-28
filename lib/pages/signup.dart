import 'package:flutter/material.dart';
import 'otp.dart';
import '../aPI/authen_login.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  final _authAPI = AuthenLogin(); // ใช้ class จากไฟล์ API

  bool _isLoading = false; // สถานะการโหลด

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    // 👇 เรียกไปหา Supabase ผ่าน AuthAPI
    final error = await _authAPI.signUpWithEmail(
      email: _email.text.trim(),
      password: _password.text.trim(),
    );
    setState(() => _isLoading = true); // 👈 เริ่มหมุนโหลด

    if (!mounted) return;
    if (error == null) {
      // ✅ สมัครสำเร็จ
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('สมัครสมาชิกสำเร็จ'),
        ),
      );
      setState(() => _isLoading = false); // 👈 เริ่มหมุนโหลด

      // จะไปหน้า OTP ต่อก็ได้ ถ้าระบบต้องการยืนยัน
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const OTPScreen()),
      );
    } else {
      // ❌ มี error จาก Supabase (เช่น email ซ้ำ)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Email มีการลงทะเบียนแล้ว")),
      );

      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // รูปแมวด้านบน
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: SizedBox(
                    height: 220,
                    child: Image.asset('assets/Sign_up_cat.png'),
                  ),
                ),
              ),
              // ฟอร์ม
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'สมัครสมาชิก',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _email,
                        decoration: InputDecoration(
                          labelText: 'อีเมล',
                          filled: true, // เติมสีพื้นหลัง
                          fillColor: const Color(0xFFE9EEF3),
                          border: OutlineInputBorder(
                            // ขอบมน
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            // เพิ่มพื้นที่ภายใน
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'กรุณากรอกอีเมล';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _password,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: 'รหัสผ่าน',
                          filled: true,
                          fillColor: const Color(0xFFE9EEF3),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'กรุณากรอกรหัสผ่าน';
                          }
                          if (value.length < 6) {
                            return 'รหัสผ่านต้องอย่างน้อย 6 ตัวอักษร';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 5),

                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          [
                            '- ความยาวอย่างน้อย 6 ตัวอักษร',
                            '- ตัวอักษรพิมพ์ใหญ่และพิมพ์เล็ก',
                            '- ตัวเลขหรือสัญลักษณ์พิเศษ',
                          ].join('\n'),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _confirmPasswordCtrl,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: 'ยืนยันรหัสผ่าน',
                          filled: true,
                          fillColor: const Color(0xFFE9EEF3),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'กรุณายืนยันรหัสผ่าน';
                          }
                          if (value != _password.text) {
                            return 'รหัสผ่านไม่ตรงกัน';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleSignup,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            backgroundColor: const Color(0xFF1F497D),
                          ),
                          child: const Text(
                            'สมัครสมาชิก',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // กลับไปหน้าเข้าสู่ระบบ
                      Center(
                        child: TextButton(
                          onPressed: () {
                            Navigator.pop(context); // กลับไปหน้าเข้าสู่ระบบ
                          },
                          child: const Text('มีบัญชีแล้ว? เข้าสู่ระบบ'),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
