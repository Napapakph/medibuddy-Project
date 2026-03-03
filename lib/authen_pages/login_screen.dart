import '../services/auth_manager.dart'; // import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'signup_screen.dart';

import '../services/authen_api.dart'; // ✅ import for API password reset
import 'forget_password.dart';
import '../profile_pages/create_profile_screen.dart';
import '../profile_pages/select_profile.dart';
import '../services/profile_api.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _isGoogleLoading = false;
  String? _lastEmail; // เก็บอีเมลล่าสุดที่ใช้ล็อกอินสำเร็จ
  String? _lastPassword; // เก็บรหัสผ่านล่าสุดที่ใช้ล็อกอินสำเร็จ
  bool _obscurePassword = true; //ดู password
  bool _isLoading =
      true; // ✅ Start loading to prevent "flash" of login form before check
  final supabase = Supabase.instance.client;
  bool _navigated = false;
//---------------- Login with Username/Password----------------------------------
  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final response = await AuthManager.service.login(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text.trim(),
      );
      final accessToken = response.accessToken;

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (!mounted) return;

      _navigated = true;
      await _checkAndNavigate(token: accessToken);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('อีเมลหรือรหัสผ่านไม่ถูกต้อง')),
      );
    }

    debugPrint(
        '-----Get Token ------: ${AuthManager.service.getAccessToken()}');
  }
//---------------- Login with Username/Password----------------------------------

//---------------- Login with Google Sign in-------------------------------------
  Future<void> _handleGoogleLogin() async {
    if (_isGoogleLoading) return;
    setState(() => _isGoogleLoading = true);

    try {
      await AuthManager.service.signInWithGoogle(); // ✅ Use AuthManager
      // ✅ เพิ่ม manual check & navigate สำหรับ custom API ที่เสร็จสมบูรณ์ทันที
      if (AuthManager.accessToken != null) {
        if (!mounted) return;
        _navigated = true;
        await _checkAndNavigate(token: AuthManager.accessToken);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Google Login ไม่สำเร็จ: $e')),
      );
    } finally {
      if (!mounted) return;
      setState(() => _isGoogleLoading = false);
    }
  }
//---------------- Login with Google Sign in-------------------------------------

  void _restorePreviousEmail() {
    if (_lastEmail != null && _lastPassword != null) {
      setState(() {
        _emailCtrl.text = _lastEmail!;
        _passwordCtrl.text = _lastPassword!;
      }); // สั่งให้ช่องโชว์ค่ากรอกครั้งแรก
    }
  }

  late final StreamSubscription<AuthState> _authSub;

  @override
  void initState() {
    super.initState();

    // Auto-login check (For Custom Auth & Supabase initial state)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndNavigate();
    });

    _authSub = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (_navigated) return;
      final event = data.event;
      final session = data.session;

      if (event == AuthChangeEvent.passwordRecovery) {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ForgetPassword()),
        );
        return;
      }
      if (event == AuthChangeEvent.signedIn && session != null) {
        if (!mounted) return;
        setState(() {
          _isGoogleLoading = true; // ✅ Show loading during callback processing
          _navigated = true;
        });

        // NEW LOGIC: Check profile first
        _checkAndNavigate(token: session.accessToken);
        return;
      }
    });
  }

  @override
  void dispose() {
    _authSub.cancel();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _checkAndNavigate({String? token}) async {
    try {
      token ??= await AuthManager.service.getAccessToken(); // ✅ Support both

      if (token == null) {
        // No token found, just stay on LoginScreen
        if (mounted) setState(() => _isLoading = false); // ✅ Reveal form
        return;
      }

      final api = ProfileApi();
      final profiles = await api.fetchProfiles(accessToken: token);

      if (!mounted) return;

      if (profiles.isNotEmpty) {
        // มีโปรไฟล์แล้ว -> ไปหน้า Library
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const SelectProfile()),
          (route) => false, // Clear Login screen from stack
        );
      } else {
        // ยังไม่มี -> ไปหน้าสร้าง Profile
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ProfileScreen()),
        );
      }
    } catch (e) {
      debugPrint('Check profile error: $e');
      // If error (e.g. 401 Unauthorized), we should NOT go to ProfileScreen.
      // We should stay here and let user login again.
      if (mounted) {
        // Clear invalid token just in case
        await AuthManager.service.logout();
        setState(() => _isLoading = false);
      }
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
            child: SizedBox(
              width: containerWidth,
              child: Stack(
                children: [
                  //รูปแมว ---------------------------------------------------------------------
                  Align(
                    alignment: Alignment.topRight,
                    child: SizedBox(
                      height: maxHeight * 0.33,
                      child: Image.asset(
                        'assets/cat_login.png',
                      ),
                    ),
                  ),
                  SizedBox(height: maxHeight * 0.02),
                  //รูปแมว ---------------------------------------------------------------------
                  // ฟอร์มล็อกอิน
                  Align(
                    alignment: const Alignment(0, 0.3),
                    child: Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: maxWidth * 0.08),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'เข้าสู่ระบบ',
                              style: TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1F2E45),
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'ยินดีต้อนรับกลับมา',
                              style: TextStyle(
                                fontSize: 15,
                                color: Color(0xFF8A9BB5),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: maxHeight * 0.025),
                            // ช่องอีเมล
                            TextFormField(
                              controller: _emailCtrl,
                              decoration: InputDecoration(
                                labelText: 'อีเมล',
                                hintStyle: const TextStyle(
                                  color: Color(0xFFA0B0C4),
                                  fontSize: 15,
                                ),
                                filled: true,
                                fillColor: const Color(0xFFF2F5F9),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFE4EAF0),
                                    width: 1,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  borderSide: const BorderSide(
                                    color: Color(0xFF7BAEE5),
                                    width: 1.5,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 18,
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'กรุณากรอกอีเมล';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),

                            // ช่องรหัสผ่าน
                            TextFormField(
                              controller: _passwordCtrl,
                              obscureText: _obscurePassword,
                              decoration: InputDecoration(
                                labelText: 'รหัสผ่าน',
                                hintStyle: const TextStyle(
                                  color: Color(0xFFA0B0C4),
                                  fontSize: 15,
                                ),
                                filled: true,
                                fillColor: const Color(0xFFF2F5F9),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFE4EAF0),
                                    width: 1,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  borderSide: const BorderSide(
                                    color: Color(0xFF7BAEE5),
                                    width: 1.5,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 18,
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off_rounded
                                        : Icons.visibility_rounded,
                                    color: const Color(0xFFA0B0C4),
                                    size: 22,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'กรุณากรอกรหัสผ่าน';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: maxHeight * 0.025),
                            // ปุ่ม "เข้าสู่ระบบ"
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                onPressed: _isLoading
                                    ? null
                                    : () {
                                        _restorePreviousEmail();
                                        _handleLogin();
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      const Color.fromARGB(255, 90, 129, 187),
                                  disabledBackgroundColor:
                                      const Color.fromARGB(255, 55, 90, 143)
                                          .withOpacity(0.6),
                                  foregroundColor: Colors.white,
                                  elevation: 4,
                                  shadowColor:
                                      const Color.fromARGB(255, 42, 80, 135)
                                          .withOpacity(0.4),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(28),
                                  ),
                                ),
                                child: const Text(
                                  'เข้าสู่ระบบ',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),

                            // ปุ่ม "สร้างบัญชี"
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: OutlinedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const SignupScreen(),
                                    ),
                                  );
                                },
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(
                                    color: Color(0xFF7BAEE5),
                                    width: 1.5,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(28),
                                  ),
                                ),
                                child: const Text(
                                  'สร้างบัญชี',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF3B7CC9),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: maxHeight * 0.02),

                            // เส้นคั่น "หรือ"
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    height: 1,
                                    color: const Color(0xFFDDE4ED),
                                  ),
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 16),
                                  child: Text(
                                    'หรือ',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFFA0B0C4),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Container(
                                    height: 1,
                                    color: const Color(0xFFDDE4ED),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: maxHeight * 0.02),

                            // ปุ่ม "เข้าสู่ระบบด้วย Google"
                            SizedBox(
                              width: double.infinity,
                              height: 54,
                              child: OutlinedButton(
                                onPressed: () {
                                  _handleGoogleLogin();
                                },
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(
                                    color: Color(0xFFDDE4ED),
                                    width: 1,
                                  ),
                                  backgroundColor: Colors.white,
                                  elevation: 1,
                                  shadowColor: Colors.black.withOpacity(0.06),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(28),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Image.asset(
                                      'assets/google_icon.png',
                                      width: 22,
                                      height: 22,
                                      errorBuilder: (_, __, ___) => const Icon(
                                          Icons.g_mobiledata,
                                          size: 28,
                                          color: Color(0xFF4285F4)),
                                    ),
                                    const SizedBox(width: 10),
                                    const Text(
                                      'เข้าสู่ระบบด้วย Google',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF3C4A5E),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // ลืมรหัสผ่าน ?
                  Align(
                    alignment: const Alignment(0, 0.95),
                    child: TextButton(
                      onPressed: () {
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
                          fontSize: 14,
                          color: Color(0xFF6B8DB0),
                          decoration: TextDecoration.underline,
                          decorationColor: Color(0xFF6B8DB0),
                        ),
                      ),
                    ),
                  ),
                  if (_isLoading || _isGoogleLoading)
                    Positioned.fill(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          const ModalBarrier(
                            dismissible: false,
                            color: Colors.black26,
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Lottie.asset(
                                'assets/lottie/loader_cat.json',
                                width: 180,
                                height: 180,
                                repeat: true,
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'กำลังโหลด…',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ],
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

  final _resetEmailCtrl = TextEditingController();

  forgetPassword() {
    return showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFEAF2FB), // ⭐ สีพื้นหลัง
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Stack(
                      children: [
                        Positioned(
                          right: 0,
                          child: IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(dialogContext),
                          ),
                        ),
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              'ลืมรหัสผ่าน',
                              style: TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _resetEmailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color.fromARGB(255, 255, 255, 255),
                        labelText: 'Email',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () async {
                        final email = _resetEmailCtrl.text.trim();
                        if (email.isEmpty) return;

                        // ✅ สลับการทำงาน: true = ใช้ Custom Backend API, false = ใช้ Supabase เดิม
                        bool useBackendApi = true;

                        try {
                          if (useBackendApi) {
                            final authService = CustomAuthService();
                            await authService.requestPasswordReset(
                              email,
                              'com.example.medibuddy://forget-password',
                            );
                          } else {
                            // ignore: dead_code
                            await Supabase.instance.client.auth
                                .resetPasswordForEmail(
                              email,
                              // ✅ ต้องเป็น deep link ของแอป
                              redirectTo:
                                  'com.example.medibuddy://forget-password',
                            );
                          }

                          if (!context.mounted) return;
                          Navigator.pop(dialogContext);

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text(
                                    'ส่งอีเมลสำหรับรีเซ็ตรหัสผ่านแล้ว กรุณาตรวจสอบอีเมล')),
                          );
                        } on AuthException catch (e) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(e.message)),
                          );
                        } catch (e) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(
                                    'เกิดข้อผิดพลาดในการส่งอีเมลรีเซ็ตรหัสผ่าน: $e')),
                          );
                        }
                      },
                      child: const Text('ส่งอีเมลรีเซ็ต'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1F497D),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
