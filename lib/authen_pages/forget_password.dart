import 'package:flutter/material.dart';
import '../widgets/login_button.dart';
import 'login.dart';
import 'package:medibuddy/services/auth_manager.dart'; // Import AuthManager
import 'package:medibuddy/services/authen_login_api_v2.dart'; // Import CustomAuthService
import 'package:supabase_flutter/supabase_flutter.dart';

class ForgetPassword extends StatefulWidget {
  final String? token; // ✅ Token จาก Deep Link
  const ForgetPassword({super.key, this.token});

  @override
  State<ForgetPassword> createState() => _ForgetPassword();
}

class _ForgetPassword extends State<ForgetPassword> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false; // สถานะการโหลด
  final _password = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  bool _obscurePassword = true; //ดู password

  @override
  void dispose() {
    _password.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleResetPassword() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากรอกข้อมูลให้ครบถ้วน')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // ✅ สลับการทำงาน: true = ใช้ Custom Backend API, false = ใช้ Supabase เดิม
      bool useBackendApi = true;

      if (useBackendApi) {
        if (widget.token == null || widget.token!.isEmpty) {
          throw Exception(
              'ลิงก์รีเซ็ตรหัสผ่านไม่ถูกต้องหรือไม่มี token กรุณากด "ลืมรหัสผ่าน" ใหม่');
        }
        final authService = CustomAuthService();
        await authService.resetPassword(widget.token!, _password.text.trim());
      } else {
        // ignore: dead_code
        final supabase = Supabase.instance.client;

        // ✅ กันเคสเข้าหน้านี้แบบไม่ได้มาจากลิงก์รีเซ็ต
        final session = supabase.auth.currentSession;
        if (session == null) {
          throw const AuthException(
              'ลิงก์รีเซ็ตรหัสผ่านไม่ถูกต้องหรือหมดอายุ กรุณากด "ลืมรหัสผ่าน" ใหม่');
        }
        // ✅ Sync with AuthManager
        AuthManager.accessToken = session.accessToken;

        // ✅ ตั้งรหัสผ่านใหม่
        await supabase.auth.updateUser(
          UserAttributes(password: _password.text.trim()),
        );

        // ✅ เพื่อความชัวร์: sign out แล้วให้ล็อกอินใหม่ด้วยรหัสใหม่
        await supabase.auth.signOut();
      }

      if (!mounted) return;
      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('รีเซ็ตรหัสผ่านสำเร็จ กรุณาเข้าสู่ระบบใหม่')),
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (pushAndRemoveUntil) => false,
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาด กรุณาลองใหม่อีกครั้ง $e')),
      );
    }
  }

  String? validatePassword(String password) {
    if (password.length < 6) {
      return 'รหัสผ่านต้องยาวอย่างน้อย 6 ตัวอักษร';
    }

    bool hasUpper = false;
    bool hasLower = false;
    bool hasDigitOrSymbol = false;

    for (int i = 0; i < password.length; i++) {
      final char = password[i];

      if (char.contains(RegExp(r'[A-Z]'))) {
        hasUpper = true;
      } else if (char.contains(RegExp(r'[a-z]'))) {
        hasLower = true;
      } else if (char.contains(RegExp(r'[0-9]')) ||
          !char.contains(RegExp(r'[A-Za-z0-9]'))) {
        // ตัวเลข หรืออย่างอื่นที่ไม่ใช่ตัวอักษร = สัญลักษณ์
        hasDigitOrSymbol = true;
      }
    }

    if (!hasUpper) {
      return 'ต้องมีตัวอักษรพิมพ์ใหญ่ อย่างน้อย 1 ตัว';
    }
    if (!hasLower) {
      return 'ต้องมีตัวอักษรพิมพ์เล็ก อย่างน้อย 1 ตัว';
    }
    if (!hasDigitOrSymbol) {
      return 'ต้องมีตัวเลขหรือสัญลักษณ์พิเศษ อย่างน้อย 1 ตัว';
    }

    return null; // ผ่านทุกเงื่อนไข
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1F497D),
        title: const Text(
          'ลืมรหัสผ่าน',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: Colors.white,
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      resizeToAvoidBottomInset: false,
      backgroundColor: const Color.fromARGB(255, 229, 242, 255),
      body: SafeArea(child: LayoutBuilder(
        builder: (context, constraints) {
          final maxWidth = constraints.maxWidth;
          final maxHeight = constraints.maxHeight;

          //ถ้าจอกว้างแบบแท็บเล็ต
          final bool isTablet = maxWidth > 600;

          //จำกัดความกว้างสูงสุดของหน้าจอ
          final double containerWidth = isTablet ? 500 : maxWidth;
          return Center(
            child: SizedBox(
              width: containerWidth,
              child: Align(
                alignment: Alignment.center,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: maxWidth * 0.06, vertical: maxHeight * 0.02),
                  child: Form(
                    key: _formKey,
                    child: Container(
                      padding: const EdgeInsets.all(20), // ⭐ ระยะห่างข้างใน
                      decoration: BoxDecoration(
                        color: Colors.white, // ⭐ พื้นหลัง
                        borderRadius: BorderRadius.circular(20), // ⭐ ขอบมน
                        border: Border.all(
                          color: const Color(0xFFD2E6FF), // ⭐ สีกรอบ
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min, // 👈 อันนี้แหละตัวช่วย
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            child: Text(
                              'ตั้งค่ารหัสผ่านใหม่',
                              style: TextStyle(
                                  fontSize: 24, fontWeight: FontWeight.bold),
                            ),
                          ),
                          SizedBox(height: maxHeight * 0.02),
                          // รหัสผ่าน
                          TextFormField(
                            controller: _password,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              labelText: 'รหัสผ่าน',
                              filled: true,
                              fillColor: const Color(0xFFE9EEF3),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: maxWidth * 0.04,
                                vertical: maxHeight * 0.01,
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'กรุณากรอกรหัสผ่าน';
                              }
                              final error = validatePassword(value);
                              return error;
                            },
                          ),
                          SizedBox(height: maxHeight * 0.02),

                          /*
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
                          */
                          SizedBox(height: maxHeight * 0.001),

                          // ยืนยันรหัสผ่าน
                          TextFormField(
                            controller: _confirmPasswordCtrl,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              labelText: 'ยืนยันรหัสผ่าน',
                              filled: true,
                              fillColor: const Color(0xFFE9EEF3),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: maxWidth * 0.04,
                                vertical: maxHeight * 0.01,
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
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
                          SizedBox(height: maxHeight * 0.02),
                          // ปุ่มตั้งรหัสผ่านใหม่
                          SizedBox(
                            width: double.infinity,
                            child: resetPassword(
                              text: 'สร้างรหัสผ่านใหม่',
                              onPressed: _handleResetPassword,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      )),
    );
  }
}
