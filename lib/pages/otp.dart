import 'package:flutter/material.dart';
import 'package:flutter_otp_text_field/flutter_otp_text_field.dart';
import 'login.dart';
import 'authen_api.dart';

class OTPScreen extends StatefulWidget {
  const OTPScreen({super.key, required this.email});
  final String email;

  @override
  State<OTPScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends State<OTPScreen> {
  final _otp = TextEditingController();
  final AuthenApi _authenApi = AuthenApi();
  bool _isLoading = false;

  @override
  void dispose() {
    _otp.dispose();
    super.dispose();
  }

  Future<void> confirmOTP() async {
    final verificationCode = _otp.text.trim();

    if (verificationCode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากรอก OTP')),
      );
      return;
    }
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      await _authenApi.confirmOtpAndSync(
        email: widget.email,
        token: verificationCode,
      );

      Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const LoginScreen(),
          ));
    } catch (e) {
      print('💥 DEBUG ERROR: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
      );
    } finally {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text('ลงทะเบียน'),
      ),
      body: SafeArea(
        child: LayoutBuilder(builder: (context, constraints) {
          final maxWidth = constraints.maxWidth;
          final maxHeight = constraints.maxHeight;

          //ถ้าจอกว้างแบบแท็บเล็ต
          final bool isTablet = maxWidth > 600;

          //จำกัดความกว้างสูงสุดของหน้าจอ
          final double containerWidth = isTablet ? 500 : maxWidth;

          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: containerWidth),
              child: Padding(
                padding: EdgeInsetsGeometry.fromLTRB(24, maxHeight * 0.06, 24,
                    maxHeight * 0.04), // ระยะห่างด้านบน),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'รหัส OTP',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    SizedBox(height: maxHeight * 0.02),
                    Text('โปรดกรอกรหัส OTP ที่ส่งไปยังอีเมลของคุณ'),
                    SizedBox(height: maxHeight * 0.04),
                    OtpTextField(
                      numberOfFields: 6,
                      borderColor: Color(0xFF512DA8),
                      borderRadius: BorderRadius.circular(12),
                      fieldHeight: maxHeight * 0.08,

                      fieldWidth: maxWidth * 0.12,
                      showFieldAsBox: true,

                      onSubmit: (String verificationCode) {
                        _otp.text = verificationCode;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("OTP : $verificationCode")),
                        );
                      }, // end onSubmit
                    ),
                    Center(
                      child: TextButton(
                        onPressed: () async {
                          try {
                            await _authenApi.resendOtp(email: widget.email);
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("ส่ง OTP ใหม่แล้ว")),
                            );
                          } catch (e) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Resend OTP failed: $e'))
                            );
                          }
                        },
                        child: const Text("ส่ง OTP อีกครั้ง"),
                      ),
                    ),
                    SizedBox(height: maxHeight * 0.02),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {
                          confirmOTP();
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          backgroundColor: const Color(0xFF1F497D),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        child: Text(
                          'ยืนยัน',
                          style: TextStyle(color: Colors.white, fontSize: 18),
                        ),
                      ),
                    ),
                    // ========ดันทุกอย่างขึ้นข้างบน========
                    Expanded(child: SizedBox()),

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
