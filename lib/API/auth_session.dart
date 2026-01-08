import 'package:supabase_flutter/supabase_flutter.dart';

class AuthSession {
  static String? get accessToken =>
      Supabase.instance.client.auth.currentSession?.accessToken;

  static bool get isLoggedIn =>
      Supabase.instance.client.auth.currentSession != null;
}
