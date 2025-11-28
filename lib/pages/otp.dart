import 'package:flutter/material.dart';
import 'package:flutter_otp_text_field/flutter_otp_text_field.dart';

class OTPScreen extends StatefulWidget {
  const OTPScreen({super.key});

  @override
  State<OTPScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends State<OTPScreen> {
  @override
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
                  numberOfFields: 5,
                  borderColor: Color(0xFF512DA8),
                  borderRadius: BorderRadius.circular(12),
                  fieldHeight: 80,
                  fieldWidth: 50,
                  showFieldAsBox: true,
                  onCodeChanged: (String code) {
                    //handle validation or checks here
                  },

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
                ),
                TextButton(
                  onPressed: () {
                    // TODO: ไปหน้าลืมรหัสผ่าน
                  },
                  child: Align(
                    alignment: Alignment.center,
                    child: const Text('ไม่ได้รับ OTP ใช่ไหม? ส่งอีกครั้ง'),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {},
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
