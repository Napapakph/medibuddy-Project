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
    final verificationCode = _otp.text.trim();

    if (verificationCode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากรอก OTP')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      print("⏳ DEBUG: กำลังเรียก /auth/v1/verify (แบบเดียวกับ Postman)");
      print("OTP: $verificationCode");
      print("Email: ${widget.email}");

      // TODO: ใส่ anon key เดียวกับที่ใช้ใน Supabase.initialize
      const supabaseAnonKey =
          '<eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFvaXVyZHdpYmd1ZHN4aG94Y25pIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQxNjY3OTcsImV4cCI6MjA3OTc0Mjc5N30.3aPHErdnVMHVmjcOk55KCLhUw6rPCzu4Ke5DWqQNsyg>';

      final uri = Uri.parse(
        'https://aoiurdwibgudsxhoxcni.supabase.co/auth/v1/verify',
      );

      final response = await http.post(
        uri,
        headers: {
          'apikey': supabaseAnonKey,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': widget.email,
          'token': verificationCode,
          'type': 'email', // 👈 ให้ตรงกับที่เพื่อนใช้ใน Postman
        }),
      );

      print('📨 DEBUG statusCode: ${response.statusCode}');
      print('📨 DEBUG body: ${response.body}');

      if (response.statusCode != 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Verify ไม่สำเร็จ: ${response.statusCode}')),
        );
        return;
      }

      final data = jsonDecode(response.body);
      final accessToken = data['access_token'];
      // ส่งไป backend ของเพื่อน
      final syncRes = await http.post(
        Uri.parse(
            'https://sharri-unpatted-cythia.ngrok-free.dev/api/auth/sync-user'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

      print("Backend status: ${syncRes.statusCode}");
      print(syncRes.body);

      // แสดง token บนหน้าจอให้เห็นเลย
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Access Token ได้แล้ว'),
          content: SingleChildScrollView(
            child: Text(accessToken ?? 'ไม่พบ access_token ใน response'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('ปิด'),
            ),
          ],
        ),
      );
    } catch (e) {
      print('💥 DEBUG ERROR: $e');
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
                padding: EdgeInsetsGeometry.fromLTRB(24, maxHeight * 0.02, 24,
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
                    SizedBox(height: maxHeight * 0.05),
                    SizedBox(height: maxHeight * 0.01),
                    Text('โปรดกรอกรหัส OTP ที่ส่งไปยังอีเมลของคุณ'),
                    SizedBox(height: maxHeight * 0.04),
                    OtpTextField(
                      numberOfFields: 6,
                      borderColor: Color(0xFF512DA8),
                      borderRadius: BorderRadius.circular(12),
                      fieldHeight: maxHeight * 0.08,
                      fieldHeight: maxHeight * 0.09,
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
