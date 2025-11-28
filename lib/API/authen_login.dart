import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

class AuthenLogin {
  Future<String?> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final res = await supabase.auth.signUp(
        email: email,
        password: password,
      );

      if (res.user == null) {
        return 'สมัครสำเร็จแล้ว โปรดตรวจสอบอีเมลเพื่อยืนยันบัญชี';
      }
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return 'เกิดข้อผิดพลาด กรุณาลองใหม่อีกครั้ง';
    }
  }
}
