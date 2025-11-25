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
      appBar: AppBar(
        title: const Text('OTP Verification'),
      ),
      body: SafeArea(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 100),
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
                const SizedBox(height: 20),
                const Row(
                  children: [
                    TextField(
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFFE9EEF3),
                        border: OutlineInputBorder(
                          // ขอบมน
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                          borderSide: BorderSide.none,
                        ),
                        hintText: '1',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
