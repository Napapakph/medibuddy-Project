import 'package:flutter/material.dart';
import 'pages/login.dart';
import 'package:supabase_flutter/supabase_flutter.dart\ ';
import 'pages/signup.dart';
import 'pages/otp.dart';
import 'pages/forget_password.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://aoiurdwibgudsxhoxcni.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFvaXVyZHdpYmd1ZHN4aG94Y25pIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQxNjY3OTcsImV4cCI6MjA3OTc0Mjc5N30.3aPHErdnVMHVmjcOk55KCLhUw6rPCzu4Ke5DWqQNsyg',
  );

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/signup', // 👈 หน้าแรกที่เปิด
      routes: {
        '/login': (_) => const LoginScreen(),
        '/signup': (_) => const SignupScreen(),
        '/otp': (_) => const OTPScreen(email: ''),
        '/forget_password': (_) => const ForgetPassword(),
      },
      title: 'MediBuddy',
    );
  }
}
