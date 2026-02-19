import 'package:flutter/material.dart';
import 'auth_manager.dart'; // Import AuthManager
import '../pages/login.dart';
import '../Home/pages/profile_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    // OLD: final session = Supabase.instance.client.auth.currentSession;
    // NEW: Check AuthManager

    // Note: getAccessToken() is async, so AuthGate might need to be stateful or FutureBuilder
    // BUT for simplicity, we can check the *cached* variable if initialized,
    // or rely on the Fact that main.dart should have synced it.

    // Ideally, AuthGate should be a StreamBuilder listening to auth state changes.
    // For now, let's keep it simple: if we have a token (from main), go to Profile.
    // However, AuthManager.accessToken might be null on cold start if not persisted?
    // Supabase perists session automatically. CustomAuth service persists via SecureStorage.

    // Ideally we should use a FutureBuilder to check validity.
    return FutureBuilder<String?>(
      future: AuthManager.service.getAccessToken(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final token = snapshot.data;
        if (token != null && token.isNotEmpty) {
          return const ProfileScreen();
        }

        return const LoginScreen();
      },
    );
  }
}
