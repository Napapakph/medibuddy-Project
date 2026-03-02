import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'auth_service.dart';
import 'supabase_auth_service.dart';
import 'authen_api_v2.dart';

class AuthManager {
  static late AuthService service;
  static String? accessToken; // ✅ Global Token Variable

  static void init() {
    final provider = dotenv.env['AUTH_PROVIDER'];
    print('🔌 AuthManager Init: Provider = $provider');
    if (provider == 'CUSTOM') {
      service = CustomAuthService();
    } else {
      // Default to Supabase
      print('🚀 Using Supabase Auth Service');
      service = SupabaseAuthService();
    }
  }
}
