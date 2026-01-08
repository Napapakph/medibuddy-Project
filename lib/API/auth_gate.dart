import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../pages/login.dart';
import '../Home/pages/profile_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;

    // ✅ ถ้ามี session แปลว่ายัง login ค้างอยู่
    final session = supabase.auth.currentSession;

    if (session != null) {
      // เข้าแอปต่อได้เลย
      return const ProfileScreen();
    }

    //ไม่มี session = ต้อง login ใหม่
    return const LoginScreen();
  }
}
