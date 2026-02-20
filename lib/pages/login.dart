import '../services/auth_manager.dart'; // import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
// import '../services/sync_user.dart'; // Removed unused import

// ... imports remain the same
import 'package:lottie/lottie.dart';
import 'signup.dart';
import '../widgets/login_button.dart';
// import '../services/authen_login.dart'; // Removed unused import if no longer needed
import 'forget_password.dart';
import '../Home/pages/profile_screen.dart';
import '../Home/pages/select_profile.dart';
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
  // final _googleAuth = LoginWithGoogle(); // Removed unused field
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

      // NEW LOGIC: Check profile first

      if (!mounted) return;
      // if (_navigated) return; // ยอมให้ทำงานทับกันได้ แต่ปกติ _handleLogin จะมี token ที่ชัวร์กว่า
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
        '-----Supabase Authenticated ------: ${supabase.auth.currentUser}');
    debugPrint(
        '-----Supabase Token ------: ${supabase.auth.currentSession?.accessToken}');
  }

//---------------- Login with Username/Password----------------------------------

//---------------- Login with Google Sign in-------------------------------------
//---------------- Login with Google Sign in-------------------------------------
  Future<void> _handleGoogleLogin() async {
    if (_isGoogleLoading) return;
    setState(() => _isGoogleLoading = true);

    try {
      await AuthManager.service.signInWithGoogle(); // ✅ Use AuthManager
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
                    alignment:
                        Alignment(0, 0.3), // 0.45 = ทศนิยมมากขึ้น = ลงล่าง
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
                                  vertical: maxHeight * 0.02,
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
                                if (value == null || value.trim().isEmpty) {
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
                                      builder: (context) =>
                                          const SignupScreen(),
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
                                  _handleGoogleLogin();
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
                          ],
                        ),
                      ),
                    ),
                  ),

                  // ลืมรหัสผ่าน ?
                  Align(
                    alignment: const Alignment(0, 0.95),
                    // 1 = ล่างสุด

                    child: TextButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('ลืมรหัสผ่าน ?')),
                        );

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
                              const SizedBox(height: 8),
                              const Text(
                                'กำลังโหลด…',
                                style: TextStyle(color: Colors.white),
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

                        try {
                          await Supabase.instance.client.auth
                              .resetPasswordForEmail(
                            email,
                            // ✅ ต้องเป็น deep link ของแอป (อันเดียวกับที่ใส่ใน Supabase Redirect URLs)
                            redirectTo:
                                'com.example.medibuddy://login-callback',
                          );

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
                            const SnackBar(
                                content: Text(
                                    'เกิดข้อผิดพลาด กรุณาลองใหม่อีกครั้ง')),
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
