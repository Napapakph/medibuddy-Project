import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

class AuthenSignUpEmail {
  Future<String?> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final res = await supabase.auth.signUp(email: email, password: password);

      if (res.session == null) {
        return 'สมัครสำเร็จแล้ว โปรดตรวจสอบอีเมลเพื่อยืนยันบัญชี';
      }
      return null;
    } on AuthException catch (e) {
      final msg = e.message.toLowerCase();
      if (msg.contains('already') ||
          msg.contains('registered') ||
          msg.contains('exists')) {
        return 'อีเมลนี้ถูกใช้งานแล้ว กรุณาเข้าสู่ระบบ';
      }
      return e.message;
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
  Future<String?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return null; // login success
    } on AuthException catch (e) {
      return e.message;
    } catch (_) {
      return 'เกิดข้อผิดพลาด กรุณาลองใหม่อีกครั้ง';
    }
  }
}
