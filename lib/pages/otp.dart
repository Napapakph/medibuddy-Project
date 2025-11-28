import 'package:flutter/material.dart';

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
                const SizedBox(height: 50),
                Row(
                  // ใช้ Row เพราะต้องการให้ TextFormField เรียงกันในแนวนอน

                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(6, (index) {
                    return SizedBox(
                      width: 45,
                      height: 60,
                      child: TextFormField(
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        maxLength: 1,
                        decoration: const InputDecoration(
                          counterText: '',
                          filled: true,
                          fillColor: Color(0xFFE9EEF3),
                          border: OutlineInputBorder(
                            // ขอบมน
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: EdgeInsets.only(top: 50),
                        ),
                      ),
                    );
                  }),
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
