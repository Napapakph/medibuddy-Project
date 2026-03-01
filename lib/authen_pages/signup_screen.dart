import 'package:flutter/material.dart';
import 'otp_verification_screen.dart';
import 'forget_password.dart';
import 'login_screen.dart';
// import '../services/authen_login.dart'; // Removed unused import
// import '../services/sync_user.dart'; // Removed unused import
import '../services/auth_manager.dart';
import '../services/authen_api_v2.dart';
import '../profile_pages/create_profile_screen.dart';
import '../profile_pages/select_profile.dart';
import '../services/profile_api.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

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
  // final _authAPI = AuthenSignUpEmail(); // DEPRECATED
  // final AuthenApi _authenApi = AuthenApi(); // DEPRECATED
  bool _obscurePassword = true; //ดู password
  bool _obscureConfirmPassword = true;
  bool _isGoogleLoading = false;

  bool _isLoading = false; // สถานะการโหลด

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  //---------------- Login with Google Sign in-------------------------------------

  bool containsUnsafeChar(String value) {
    const unsafeChars = ['<', '>', '"', "'", '/', '\\', '`'];
    for (final ch in unsafeChars) {
      if (value.contains(ch)) return true;
    }
    return false;
  }

  Future<void> _showExistingEmailDialog(String email) async {
    if (!mounted) return;
    final rootContext = context;

    await showDialog<void>(
      context: rootContext,
      barrierDismissible: true,
      builder: (dialogContext) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: Colors.white,
          child: SizedBox(
            width: 360,
            child: Stack(
              children: [
                // ❎ ปุ่มกากบาทมุมขวาบน
                Positioned(
                  top: 8,
                  right: 8,
                  child: IconButton(
                    icon: const Icon(Icons.close),
                    color: Colors.black,
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                    },
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 8),

                      const Text(
                        'อีเมลนี้ถูกลงทะเบียนแล้ว',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 12),

                      RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: const TextStyle(
                            fontSize: 15,
                            color: Colors.black87,
                          ),
                          children: [
                            const TextSpan(text: 'อีเมล '),
                            TextSpan(
                              text: email,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1F497D), // 👈 สีหลัก MediBuddy
                              ),
                            ),
                            const TextSpan(
                              text:
                                  ' นี้\nมีบัญชีผู้ใช้แล้ว\nกรุณาเข้าสู่ระบบ หรือกดลืมรหัสผ่าน',
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // 🔘 ปุ่มด้านล่าง
                      Row(
                        children: [
                          // ⬅️ ลืมรหัสผ่าน
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                Navigator.of(dialogContext).pop();
                                Navigator.push(
                                  rootContext,
                                  MaterialPageRoute(
                                    builder: (_) => const ForgetPassword(),
                                  ),
                                );
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF1F497D),
                                side: const BorderSide(
                                  color: Color(0xFF1F497D),
                                ),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text('ลืมรหัสผ่าน'),
                            ),
                          ),

                          const SizedBox(width: 12),

                          // ➡️ เข้าสู่ระบบ (ปุ่มหลัก)
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.of(dialogContext).pop();
                                Navigator.push(
                                  rootContext,
                                  MaterialPageRoute(
                                    builder: (_) => const LoginScreen(),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1F497D),
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text('เข้าสู่ระบบ'),
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
    );
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากรอกข้อมูลให้ถูกต้อง')),
      );
      return;
    }
    final email = _email.text.trim();
    final password = _password.text.trim();

    setState(() => _isLoading = true);
    try {
      final status = await AuthManager.service.checkEmailStatus(email);
      if (!mounted) return;
      if (status == 'existing') {
        setState(() => _isLoading = false);
        await _showExistingEmailDialog(email);
        return;
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Check email failed: $e')),
      );
      return;
    }

    // Use structured register to detect 409/merge
    final service = AuthManager.service;
    if (service is CustomAuthService) {
      final result =
          await service.registerWithResult(email: email, password: password);
      if (!mounted) return;
      setState(() => _isLoading = false);

      if (result.success) {
        // Normal register success → OTP verification
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('กรอกรหัสยืนยัน OTP')),
        );
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => OTPScreen(email: email)),
        );
        return;
      }

      if (result.requiresMerge) {
        // Show merge confirmation dialog
        await _showMergeConfirmDialog(
          email: email,
          password: password,
          message: result.backendMessage ?? '',
        );
        return;
      }

      // Generic error or already-registered
      if (result.errorMessage != null &&
          _isAlreadyRegisteredError(result.errorMessage!)) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => OTPScreen(email: email)),
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.errorMessage ?? 'Registration failed')),
      );
    } else {
      // Fallback for non-CustomAuthService (e.g. Supabase)
      final error =
          await AuthManager.service.register(email: email, password: password);
      if (!mounted) return;
      setState(() => _isLoading = false);

      if (error == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('กรอกรหัสยืนยัน OTP')),
        );
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => OTPScreen(email: email)),
        );
        return;
      }

      if (_isAlreadyRegisteredError(error)) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => OTPScreen(email: email)),
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
    }
  }

  bool _isAlreadyRegisteredError(String error) {
    final msg = error.toLowerCase();
    const keywords = ['already', 'exists', 'registered'];
    return keywords.any(msg.contains);
  }

  Future<void> _showMergeConfirmDialog({
    required String email,
    required String password,
    required String message,
  }) async {
    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: Colors.white,
          title: const Text(
            'เชื่อมบัญชี Google',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          content: Text(
            message,
            style: const TextStyle(fontSize: 15, color: Colors.black87),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('ไม่',
                  style: TextStyle(color: Colors.grey, fontSize: 16)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1F497D),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('ใช่', style: TextStyle(fontSize: 16)),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    // User confirmed → request OTP then navigate to merge OTP screen
    setState(() => _isLoading = true);
    try {
      final service = AuthManager.service as CustomAuthService;
      await service.requestOtp(email);
      if (!mounted) return;
      setState(() => _isLoading = false);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OTPScreen(
            email: email,
            isMergeMode: true,
            mergePassword: password,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ส่ง OTP ไม่สำเร็จ: $e')),
      );
    }
  }

//---------------- Login with Google Sign in-------------------------------------
  Future<void> _handleGoogleLogin() async {
    if (_isGoogleLoading) return;
    setState(() => _isGoogleLoading = true);

    try {
      await AuthManager.service.signInWithGoogle(); // ✅ Use AuthManager
      // ✅ เพิ่ม manual check & navigate สำหรับ custom API ที่เสร็จสมบูรณ์ทันที
      if (AuthManager.accessToken != null) {
        if (!mounted) return;
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

  Future<void> _checkAndNavigate({String? token}) async {
    try {
      token ??= await AuthManager.service.getAccessToken(); // ✅ Support both

      if (token == null) {
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
      if (mounted) {
        await AuthManager.service.logout();
        setState(() => _isLoading = false);
      }
    }
  }

  String? validatePassword(String password) {
    if (password.length < 6) {
      return 'รหัสผ่านต้องยาวอย่างน้อย 6 ตัวอักษร';
    }

    if (containsUnsafeChar(password)) {
      return 'ห้ามใช้สัญลักษณ์ < > " \' / \\ `';
    }

    bool hasUpper = RegExp(r'[A-Z]').hasMatch(password);
    bool hasLower = RegExp(r'[a-z]').hasMatch(password);
    bool hasDigitOrSymbol =
        RegExp(r'[0-9!@#\$%\^&\*\(\)_\+\-=\.]').hasMatch(password);

    if (!hasUpper) {
      return 'ต้องมีตัวอักษรพิมพ์ใหญ่ อย่างน้อย 1 ตัว';
    }
    if (!hasLower) {
      return 'ต้องมีตัวอักษรพิมพ์เล็ก อย่างน้อย 1 ตัว';
    }
    if (!hasDigitOrSymbol) {
      return 'ต้องมีตัวเลขหรือสัญลักษณ์พิเศษ อย่างน้อย 1 ตัว';
    }

    return null;
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
                                SizedBox(height: maxHeight * 0.03),

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
                                SizedBox(height: maxHeight * 0.02),

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

                                    final error = validatePassword(
                                        value); // 👈 เรียกฟังก์ชันด้านบน

                                    return error; // ถ้า null = ผ่าน, ถ้าเป็น String = โชว์ข้อความนั้น
                                  },
                                ),
                                SizedBox(height: maxHeight * 0.01),
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
                                            ? Icons.visibility_off
                                            : Icons.visibility,
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

                                // ปุ่มลงทะเบียน
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
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
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
