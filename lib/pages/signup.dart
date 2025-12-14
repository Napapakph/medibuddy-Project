import 'package:flutter/material.dart';
//import 'package:flutter/rendering.dart';
import 'otp.dart';
import '../API/authen_login.dart';

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
  bool _obscurePassword = true; //ดู password
  bool _obscureConfirmPassword = true;

  bool _isLoading = false; // สถานะการโหลด

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากรอกข้อมูลให้ครบถ้วนก่อนลงทะเบียน')),
      );
      return;
    }

    setState(() => _isLoading = true); // 👈 เริ่มหมุนโหลด
    // 👇 เรียกไปหา Supabase ผ่าน AuthAPI
    final error = await _authAPI.signUpWithEmail(
      email: _email.text.trim(),
      password: _password.text.trim(),
    );
    if (!mounted) return;

    setState(() => _isLoading = false);
    if (!mounted) return;
    if (error == null) {
      // ✅ สมัครสำเร็จ
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กรอกรหัสยืนยัน OTP'),
        ),
      );

      // จะไปหน้า OTP ต่อก็ได้ ถ้าระบบต้องการยืนยัน
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => OTPScreen(email: _email.text.trim())),
        //หน้า OTP จะรู้แล้วว่า OTP นี้เป็นของอีเมลไหน
      );
    } else {
      // ❌ Debug มี error หรือ Supabase (เช่น email ซ้ำ)  ของ Supabase ยังไม่ได้ทำเช็ค
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error อยู่น้าเลยรับ OTP ไม่ได้")),
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
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxWidth = constraints.maxWidth;
            final maxHeight = constraints.maxHeight;

            //ถ้าจอกว้างแบบแท็บเล็ต
            final bool isTablet = maxWidth > 600;

            //จำกัดความกว้างสูงสุดของหน้าจอ
            final double containerWidth = isTablet ? 500 : maxWidth;
            return Stack(
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(
                      maxWidth: 480, maxHeight: double.infinity),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // รูปแมวด้านบน
                      Positioned(
                          child: Align(
                        alignment: Alignment.topRight,
                        child: SizedBox(
                          height: maxHeight * 0.25,
                          child: Image.asset(
                            'assets/Sign_up_cat.png',
                          ),
                        ),
                      )),

                      Center(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(
                              maxWidth * 0.05, 0, maxWidth * 0.05, 0),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'ลงทะเบียน',
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: maxHeight * 0.01),
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
                                    contentPadding: EdgeInsets.symmetric(
                                      // เพิ่มพื้นที่ภายใน
                                      horizontal: maxWidth * 0.04,
                                      vertical: maxHeight * 0.01,
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'กรุณากรอกอีเมล';
                                    }
                                    return null;
                                  },
                                ),
                                SizedBox(height: maxHeight * 0.01),

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
                                            ? Icons.visibility
                                            : Icons.visibility_off,
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

                                    final error = validatePassword(
                                        value); // 👈 เรียกฟังก์ชันด้านบน

                                    return error; // ถ้า null = ผ่าน, ถ้าเป็น String = โชว์ข้อความนั้น
                                  },
                                ),
                                SizedBox(height: maxHeight * 0.01),

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
                                SizedBox(height: maxHeight * 0.01),

                                TextFormField(
                                  controller: _confirmPasswordCtrl,
                                  obscureText: _obscureConfirmPassword,
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
                                        _obscureConfirmPassword
                                            ? Icons.visibility
                                            : Icons.visibility_off,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _obscureConfirmPassword =
                                              !_obscureConfirmPassword;
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

                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed:
                                        _isLoading ? null : _handleSignup,
                                    style: ElevatedButton.styleFrom(
                                      padding: EdgeInsets.symmetric(
                                          vertical: maxHeight * 0.02),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(24),
                                      ),
                                      backgroundColor: const Color(0xFF1F497D),
                                    ),
                                    child: const Text(
                                      'ลงทะเบียน',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(height: maxHeight * 0.02),

                                // กลับไปหน้าเข้าสู่ระบบ
                                Center(
                                  child: TextButton(
                                    onPressed: () {
                                      Navigator.pop(
                                          context); // กลับไปหน้าเข้าสู่ระบบ
                                    },
                                    child:
                                        const Text('มีบัญชีแล้ว? เข้าสู่ระบบ'),
                                  ),
                                )
                              ],
                            ),
                          ),
                        ),
                      ),
                      // ฟอร์ม
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
