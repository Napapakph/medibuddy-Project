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

Map<String, dynamic> _parseJwt(String token) {
  final parts = token.split('.');
  if (parts.length != 3) throw Exception('invalid token');

  String normalize(String str) {
    str = str.replaceAll('-', '+').replaceAll('_', '/');
    switch (str.length % 4) {
      case 0:
        return str;
      case 2:
        return '$str==';
      case 3:
        return '$str=';
      default:
        throw Exception('invalid base64');
    }
  }

  final payload = utf8.decode(base64Url.decode(normalize(parts[1])));
  return jsonDecode(payload) as Map<String, dynamic>;
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
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      print("⏳ DEBUG: กำลังเรียก /auth/v1/verify (แบบเดียวกับ Postman)");
      print("OTP: $verificationCode");
      print("Email: ${widget.email}");

      // TODO: ใส่ anon key เดียวกับที่ใช้ใน Supabase.initialize
      const supabaseAnonKey =
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFvaXVyZHdpYmd1ZHN4aG94Y25pIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQxNjY3OTcsImV4cCI6MjA3OTc0Mjc5N30.3aPHErdnVMHVmjcOk55KCLhUw6rPCzu4Ke5DWqQNsy';

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
          'type': 'email', // ให้ตรงกับที่เพื่อนใช้ใน Postman
        }),
      );
      if (!mounted) return;
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

      if (accessToken == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Verify สำเร็จแต่ไม่พบ access_token')),
        );
        return;
      }

      final supabaseUserIdFromUser = data['user']?['id'] as String?;
      final supabaseUserId =
          supabaseUserIdFromUser ?? (_parseJwt(accessToken)['sub'] as String);

      // ส่งไป backend ของเพื่อน
      final syncRes = await http.post(
        Uri.parse('http://82.26.104.199:3000/api/mobile/v1/auth/sync-user'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "supabaseUserId": supabaseUserId,
          "email": widget.email,
          "provider": "email",
          "allowMerge": true,
        }),
      );
      if (!mounted) return;

      print("Backend status: ${syncRes.statusCode}");
      print(syncRes.body);

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
