import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../pages/login.dart';
import '../Home/pages/profile_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;

    // ถ้ามี session => เข้า Profile เลย
    final session = supabase.auth.currentSession;
    if (session != null) {
      return const ProfileScreen(
        accessToken: '',
      );
    }

    // ไม่มี session => ไป Login
    return const LoginScreen();
  }
}
