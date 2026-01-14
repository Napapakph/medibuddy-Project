import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

class AuthenSignUpEmail {
  Future<String?> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      await supabase.auth.signUp(
        email: email,
        password: password,
      );

      // ✅ ถ้าไม่ throw ถือว่าสำเร็จ
      return null;
    } on AuthException catch (e) {
      return e.message; // เช่น email ซ้ำ ฯลฯ
    } catch (_) {
      return 'เกิดข้อผิดพลาด กรุณาลองใหม่อีกครั้ง';
    }
  }
}

class LoginWithGoogle {
  Future<void> signInWithGoogle() async {
    await supabase.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: 'com.example.medibuddy://login-callback',
      queryParams: {'prompt': 'select_account'},
      
    );
  }

  Future<void> signOut() async {
    await supabase.auth.signOut();
  }
}

class AuthenLoginEmail {
  Future<String> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final res = await supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );

    final token = res.session?.accessToken;

    if (token == null) {
      throw Exception('Login success but no session token');
    }
    return token;
  }
}

class AuthenLogout {
  Future<void> signOut() async {
    await supabase.auth.signOut();
  }
}
