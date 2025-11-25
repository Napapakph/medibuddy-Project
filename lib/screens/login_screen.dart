import 'package:flutter/material.dart';
import '../services/mock_auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _auth = MockAuthService();

  bool _isLoading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final success = await _auth.login(
      email: _emailCtrl.text.trim(),
      password: _passwordCtrl.text.trim(),
    );

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('เข้าสู่ระบบสำเร็จ (mock)')),
      );
      // ตรงนี้อนาคตค่อยเปลี่ยนเป็น Navigator.push ไปหน้า Home
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('อีเมลหรือรหัสผ่านไม่ถูกต้อง')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ส่วนรูปแมวด้านบน (ตอนนี้ใช้ Container แทนรูปจริงไปก่อนก็ได้)
                Align(
                  alignment: Alignment.topRight,
                  child: SizedBox(
                    height: 160,
                    child: Image.asset(
                      'assets/cat_top.png', // ไว้ใส่รูปทีหลัง
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                const Text(
                  'เข้าสู่ระบบ',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),

                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // ช่องอีเมล
                      TextFormField(
                        controller: _emailCtrl,
                        decoration: InputDecoration(
                          labelText: 'อีเมล',
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
                            return 'กรุณากรอกอีเมล';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      // ช่องรหัสผ่าน
                      TextFormField(
                        controller: _passwordCtrl,
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
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      // ปุ่ม "เข้าสู่ระบบ"
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleLogin,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            backgroundColor: const Color(0xFF1F497D),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text(
                                  'เข้าสู่ระบบ',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // ปุ่ม "สร้างบัญชี"
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            // TODO: ไปหน้าสมัครสมาชิก
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            backgroundColor: const Color(0xFFB7DAFF),
                            foregroundColor: Colors.black87,
                          ),
                          child: const Text(
                            'สร้างบัญชี',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // ปุ่ม "เข้าสู่ระบบด้วย Google"
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () {
                            // TODO: future Google Sign-In
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.g_mobiledata, size: 32),
                              SizedBox(width: 8),
                              Text(
                                'เข้าสู่ระบบด้วย Google',
                                style: TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ลืมรหัสผ่าน ?
                      TextButton(
                        onPressed: () {
                          // TODO: ไปหน้าลืมรหัสผ่าน
                        },
                        child: const Text('ลืมรหัสผ่าน ?'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
