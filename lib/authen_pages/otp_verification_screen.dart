import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_otp_text_field/flutter_otp_text_field.dart';
import 'login_screen.dart';
import '../services/auth_manager.dart';
import '../services/authen_api.dart';

class OTPScreen extends StatefulWidget {
  const OTPScreen({
    super.key,
    required this.email,
    this.isMergeMode = false,
    this.mergePassword,
  });

  final String email;
  final bool isMergeMode;
  final String? mergePassword;

  @override
  State<OTPScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends State<OTPScreen> {
  final _otp = TextEditingController();
  bool _isLoading = false;
  String? _errorText;

  // Countdown for resend OTP
  int _cooldownSeconds = 0;
  Timer? _cooldownTimer;

  @override
  void initState() {
    super.initState();
    // Start cooldown when screen opens (OTP was just requested)
    _startCooldown(60);
  }

  @override
  void dispose() {
    _otp.dispose();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  void _startCooldown(int seconds) {
    _cooldownTimer?.cancel();
    setState(() => _cooldownSeconds = seconds);
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _cooldownSeconds--;
        if (_cooldownSeconds <= 0) {
          _cooldownSeconds = 0;
          timer.cancel();
        }
      });
    });
  }

  Future<void> _resendOtp() async {
    if (_cooldownSeconds > 0) return;
    setState(() => _isLoading = true);
    try {
      final service = AuthManager.service;
      if (service is CustomAuthService) {
        final result = await service.requestOtp(widget.email);
        final ttl = result['ttlSeconds'];
        _startCooldown(ttl is int ? ttl : 60);
      } else {
        await service.resendOtp(widget.email);
        _startCooldown(60);
      }
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ส่ง OTP ใหม่แล้ว')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Resend OTP failed: $e')),
      );
    }
  }

  Future<void> _confirmOTP() async {
    final verificationCode = _otp.text.trim();

    if (verificationCode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากรอก OTP')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    if (widget.isMergeMode) {
      await _handleMergeVerify(verificationCode);
    } else {
      await _handleNormalVerify(verificationCode);
    }
  }

  Future<void> _handleNormalVerify(String code) async {
    try {
      final response = await AuthManager.service.verifyOtp(
        email: widget.email,
        token: code,
      );

      if (response.accessToken.isNotEmpty) {
        AuthManager.accessToken = response.accessToken;
      }

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
      );
    }
  }

  Future<void> _handleMergeVerify(String code) async {
    final service = AuthManager.service;
    if (service is! CustomAuthService) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Merge not supported')),
      );
      return;
    }

    try {
      await service.registerMerge(
        email: widget.email,
        otp: code,
        password: widget.mergePassword ?? '',
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('เชื่อมบัญชีสำเร็จ! กรุณาเข้าสู่ระบบ')),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    } on MergeException catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);

      switch (e.code) {
        case 'INVALID_OTP':
          setState(() => _errorText = 'รหัส OTP ไม่ถูกต้อง');
          break;
        case 'OTP_EXPIRED':
          setState(() => _errorText = 'รหัส OTP หมดอายุ กรุณาขอรหัสใหม่');
          break;
        case 'TOO_MANY_ATTEMPTS':
          _showTooManyAttemptsDialog();
          break;
        default:
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.message)),
          );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
      );
    }
  }

  void _showTooManyAttemptsDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('คำขอมากเกินไป'),
        content: const Text('คุณลองหลายครั้งเกินไป กรุณารอสักครู่แล้วลองใหม่'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child:
                const Text('ตกลง', style: TextStyle(color: Color(0xFF1F497D))),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(widget.isMergeMode ? 'เชื่อมบัญชี' : 'ลงทะเบียน'),
      ),
      body: SafeArea(
        child: LayoutBuilder(builder: (context, constraints) {
          final maxWidth = constraints.maxWidth;
          final maxHeight = constraints.maxHeight;
          final bool isTablet = maxWidth > 600;
          final double containerWidth = isTablet ? 500 : maxWidth;

          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: containerWidth),
              child: Padding(
                padding: EdgeInsetsGeometry.fromLTRB(
                    24, maxHeight * 0.06, 24, maxHeight * 0.04),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'รหัส OTP',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: maxHeight * 0.02),
                    Text(widget.isMergeMode
                        ? 'กรุณากรอก OTP ที่ส่งไปยัง ${widget.email} เพื่อเชื่อมบัญชี'
                        : 'โปรดกรอกรหัส OTP ที่ส่งไปยังอีเมลของคุณ'),
                    SizedBox(height: maxHeight * 0.04),
                    OtpTextField(
                      numberOfFields: 6,
                      borderColor: const Color(0xFF512DA8),
                      borderRadius: BorderRadius.circular(12),
                      fieldHeight: maxHeight * 0.08,
                      fieldWidth: maxWidth * 0.12,
                      showFieldAsBox: true,
                      onSubmit: (String verificationCode) {
                        _otp.text = verificationCode;
                      },
                    ),
                    // Error text (for merge mode errors)
                    if (_errorText != null) ...[
                      const SizedBox(height: 8),
                      Center(
                        child: Text(
                          _errorText!,
                          style:
                              const TextStyle(color: Colors.red, fontSize: 14),
                        ),
                      ),
                    ],
                    Center(
                      child: TextButton(
                        onPressed: _cooldownSeconds > 0 || _isLoading
                            ? null
                            : _resendOtp,
                        child: Text(
                          _cooldownSeconds > 0
                              ? 'ส่ง OTP อีกครั้ง ($_cooldownSeconds วินาที)'
                              : 'ส่ง OTP อีกครั้ง',
                        ),
                      ),
                    ),
                    SizedBox(height: maxHeight * 0.02),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: _isLoading ? null : _confirmOTP,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          backgroundColor: const Color(0xFF1F497D),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                widget.isMergeMode
                                    ? 'ยืนยันเชื่อมบัญชี'
                                    : 'ยืนยัน',
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 18),
                              ),
                      ),
                    ),
                    const Expanded(child: SizedBox()),
                    SizedBox(
                      height: maxHeight * 0.4,
                      child: Image.asset('assets/OTP.png'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
