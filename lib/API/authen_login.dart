import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';

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

class LoginWithGoogle {
  Future<void> nativeGoogleSignIn() async {
    //  Android: ใช้ Web Client ID ของ Google (ไม่ใช่ SUPABASE_URL)
    const String webClientId =
        '186965022134-bobe7qaltrlu2g18u12pbb9aonikkeog.apps.googleusercontent.com';

    /// ใช้ GoogleSignIn instance แบบ native
    final googleSignIn = GoogleSignIn.instance;

    /// เริ่มต้นการตั้งค่า Google Sign-In
    /// - serverClientId: ใช้สำหรับ backend / Supabase
    await googleSignIn.initialize(
      serverClientId: webClientId,
    );

    /// ล็อกอิน Google (ต้องเด้งเลือกบัญชี)

    final googleUser = await googleSignIn.authenticate();
    if (googleUser == null) {
      throw const AuthException('ผู้ใช้ยกเลิกการเข้าสู่ระบบด้วย Google');
    }

    /// ขอ authorization เพื่อให้ได้ access token ตาม scope ที่กำหนด
    /// ใช้สำหรับยืนยันตัวตนกับ Supabase
    final authorization = await googleUser.authorizationClient.authorizeScopes(
      const ['email', 'profile'],
    );

    /// ดึง ID Token จาก Google
    /// ใช้เป็นตัวหลักในการยืนยันกับ Supabase
    final googleAuth = await googleUser.authentication;
    final idToken = googleAuth.idToken;

    /// ถ้าไม่พบ ID Token ให้ถือว่าล้มเหลว
    if (idToken == null) {
      throw AuthException('ไม่พบ ID Token จาก Google');
    }

    /// ส่ง ID Token และ Access Token ไปให้ Supabase
    /// เพื่อทำการเข้าสู่ระบบด้วย Google OAuth
    //  ส่งเข้า Supabase เพื่อ login
    final res = await supabase.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: authorization.accessToken,
    );
    if (res.session == null) {
      throw const AuthException('Supabase login ไม่สำเร็จ');
    }
  }
}
