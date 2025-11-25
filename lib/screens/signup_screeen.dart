import 'package:flutter/material.dart';

class SignupScreen extends StatelessWidget {
  const SignupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              //รูปแมว
              Align(
                alignment: Alignment.topRight,
                child: SizedBox(
                  height: 200,
                  child: Image.asset(
                    'assets/Sign_up_cat.png',
                  ),
                ),
              ),
              const SizedBox(height: 100),
              const Text(
                'สมัครสมาชิก',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
