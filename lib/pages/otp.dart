import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:flutter_otp_text_field/flutter_otp_text_field.dart';
import 'dart:convert'; //แปลง Object to JSON
import 'package:http/http.dart' as http; //ยิง request ไปยัง backend API
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login.dart';

class OTPScreen extends StatefulWidget {
  const OTPScreen({super.key, required this.email});
  final String email;

  @override
  State<OTPScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends State<OTPScreen> {
  final _otp = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _otp.dispose();
    super.dispose();
  }

  Future<void> confirmOTP() async {
    final otp = _otp.text.trim();
    if (otp.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากรอก OTP')),
      );
      return;
    }
    try {
      setState(() => _isLoading = true);

      final supabase = Supabase.instance.client;

      print("⏳ กำลัง verify OTP...");

      final res = await supabase.auth.verifyOTP(
        email: widget.email,
        token: otp,
        type: OtpType.signup,
      );

      if (res.session == null) {
        print("❌ verifyOTP session = NULL (OTP ผิดหรือ type ไม่ตรง)");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('OTP ไม่ถูกต้อง หรือหมดอายุ')),
        );
        return; // ❗❗ หยุดก่อน crash
      }

      final token = res.session!.accessToken;
      print("🔐 Token ได้แล้ว: $token");

      final syncRes = await http.post(
        Uri.parse(
            'https://sharri-unpatted-cythia.ngrok-free.dev/api/auth/sync-user'),
        headers: {'Authorization': 'Bearer $token'},
      );

      print("📨 sync-user status: ${syncRes.statusCode}");
      print(syncRes.body);

      if (syncRes.statusCode != 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sync user ล้มเหลว')),
        );
        return;
      }

      Navigator.pushReplacementNamed(context, '/login');
    } catch (e) {
      print("💥 ERROR: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
      );
    } finally {
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
        title: const Text('OTP Verification'),
      ),
      body: SafeArea(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.only(
                left: 24, right: 24, top: 60), // ระยะห่างด้านบน),
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
                const SizedBox(height: 10),
                Text('โปรดกรอกรหัส OTP ที่ส่งไปยังอีเมลของคุณ'),
                const SizedBox(height: 40),
                OtpTextField(
                  numberOfFields: 6,
                  borderColor: Color(0xFF512DA8),
                  borderRadius: BorderRadius.circular(12),
                  fieldHeight: 80,
                  fieldWidth: 43,
                  showFieldAsBox: true,
                  onCodeChanged: (String code) {
                    _otp.text = code;
                  },
                  /*
                  onSubmit: (String verificationCode) {
                    showDialog(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            title: Text("Verification Code"),
                            content: Text('Code entered is $verificationCode'),
                          );
                        });
                  }, // end onSubmit
                  */
                ),
                Center(
                  child: TextButton(
                    onPressed: () async {
                      await Supabase.instance.client.auth.resend(
                        type: OtpType.signup,
                        email: widget.email,
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("ส่ง OTP ใหม่แล้ว")),
                      );
                    },
                    child: const Text("ส่ง OTP อีกครั้ง"),
                  ),
                ),
                const SizedBox(height: 10),
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
                const SizedBox(height: 10),
                SizedBox(
                  height: 300,
                  child: Image.asset('assets/OTP.png'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
