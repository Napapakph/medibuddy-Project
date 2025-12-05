import 'package:flutter/material.dart';
import '../widgets/login_button.dart';
import '../pages/login.dart';

class ForgetPassword extends StatefulWidget {
  const ForgetPassword({super.key});

  @override
  State<ForgetPassword> createState() => _ForgetPassword();
}

class _ForgetPassword extends State<ForgetPassword> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false; // สถานะการโหลด
  final _password = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();

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

    // 👇 สมมติว่าเรียก API หรือทำงาน async จริง
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return; // 👈 ต้องอยู่หลัง await

    setState(() => _isLoading = false);

    // ไปหน้าถัดไป
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('รีเซ็ตรหัสผ่านสำเร็จ')),
    );
    Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const LoginScreen(),
        ));
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
      appBar: AppBar(),
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.white,
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
                          obscureText: true,
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
                        SizedBox(height: maxHeight * 0.02),

                        // ยืนยันรหัสผ่าน
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
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: maxWidth * 0.04,
                              vertical: maxHeight * 0.01,
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
                        SizedBox(height: maxHeight * 0.04),
                        // ปุ่มตั้งรหัสผ่านใหม่
                        SizedBox(
                          width: double.infinity,
                          child: resetPassword(
                              text: 'สร้างรหัสผ่านใหม่',
                              onPressed: () {
                                _isLoading ? null : _handleResetPassword();
                              }),
                        ),
                      ],
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
