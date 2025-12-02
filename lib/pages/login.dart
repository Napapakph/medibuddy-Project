import 'package:flutter/material.dart';
import '../services/mock_auth_service.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'signup.dart';
import '../widgets/login_button.dart';
import '../Home/pages/home.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<
      FormState>(); //ใช้อ้างถึง FormState เพื่อตรวจสอบ validation หรือเรียก validate()
  final _emailCtrl =
      TextEditingController(); //TextEditingController สำหรับคุมค่าช่องอีเมลและรหัสผ่าน, ใช้ดึงค่าและทำ dispose() เพื่อไม่ให้รั่วหน่วยความจำ
  final _passwordCtrl = TextEditingController();
  final _auth = MockAuthService(); //จำลองการ Login
  String? _lastEmail; // เก็บอีเมลล่าสุดที่ใช้ล็อกอินสำเร็จ
  String? _lastPassword; // เก็บรหัสผ่านล่าสุดที่ใช้ล็อกอินสำเร็จ

  bool _isLoading = false; // ติดตามสถานะกำลังล็อกอิน

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
        const SnackBar(content: Text('เข้าสู่ระบบสำเร็จ')),
      );
      // ตรงนี้อนาคตค่อยเปลี่ยนเป็น Navigator.push ไปหน้า Home
      Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const homePage(),
          ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('อีเมลหรือรหัสผ่านไม่ถูกต้อง')),
      );
    }
  }

  void _restorePreviousEmail() {
    if (_lastEmail != null && _lastPassword != null) {
      setState(() {
        _emailCtrl.text = _lastEmail!;
        _passwordCtrl.text = _lastPassword!;
      }); // สั่งให้ช่องโชว์ค่ากรอกครั้งแรก
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                children: [
                  //รูปแมว
                  Align(
                    alignment: Alignment.topRight,
                    child: SizedBox(
                      height: maxHeight * 0.3,
                      child: Image.asset(
                        'assets/cat_login.png',
                      ),
                    ),
                  ),
                  SizedBox(height: maxHeight * 0.02),

                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: maxWidth * 0.08),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'เข้าสู่ระบบ',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: maxHeight * 0.02),
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
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: maxWidth * 0.04,
                                vertical: maxHeight * 0.02,
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'กรุณากรอกอีเมล';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: maxHeight * 0.02),

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
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: maxWidth * 0.04,
                                vertical: maxHeight * 0.02,
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'กรุณากรอกรหัสผ่าน';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: maxHeight * 0.02),
                          // ปุ่ม "เข้าสู่ระบบ"
                          SizedBox(
                            width: double.infinity,
                            child: LoginButton(
                              isLoading: _isLoading,
                              text: '',
                              onPressed: () {
                                _restorePreviousEmail();
                                _handleLogin();
                              },
                              Text: null,
                            ),
                          ),
                          SizedBox(height: maxHeight * 0.02),

                          // ปุ่ม "สร้างบัญชี"
                          SizedBox(
                            width: double.infinity,
                            child: SignupButton(
                              text: 'สร้างบัญชี',
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const SignupScreen(),
                                  ),
                                );
                              },
                            ),
                          ),
                          SizedBox(height: maxHeight * 0.02),

                          // ปุ่ม "เข้าสู่ระบบด้วย Google"
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: () {
                                // TODO: future Google Sign-In
                              },
                              style: OutlinedButton.styleFrom(
                                padding: EdgeInsets.symmetric(
                                    vertical: maxHeight * 0.02),
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
                          SizedBox(height: maxHeight * 0.02),
                        ],
                      ),
                    ),
                  ),
                  // ลืมรหัสผ่าน ?
                  Align(
                    alignment: Alignment.center,
                    child: TextButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('ลืมรหัสผ่าน ?')),
                        );
                        //ไว้เพิ่มฟังก์ชันลืมรหัสผ่านในอนาคต
                        forgetPassword();
                      },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        splashFactory: NoSplash.splashFactory,
                      ),
                      child: const Text(
                        'ลืมรหัสผ่าน ?',
                        style: TextStyle(
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      )),
    );
  }

  forgetPassword() {
    //ไว้เพิ่มฟังก์ชันลืมรหัสผ่านในอนาคต
    return showDialog(
        context: context,
        builder: (context) {
          return Dialog(
            child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Stack(
                        children: [
                          // ปุ่มปิดด้านขวา
                          Positioned(
                            right: 0,
                            child: IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ),

                          // ข้อความอยู่กลางจริงๆ ตามพื้นที่ทั้งหมด
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: Text(
                                'ลืมรหัสผ่าน',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),
                      ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: 400),
                          child: Container(
                            child: TextField(
                              decoration: InputDecoration(
                                labelText: 'Email',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                              ),
                            ),
                          )),
                      SizedBox(height: 24),
                      ElevatedButton(
                          onPressed: () {}, child: const Text('ตรวจสอบ Email')),
                    ],
                  ),
                )),
          );
        });
  }
}
