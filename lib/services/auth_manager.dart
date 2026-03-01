import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'auth_service.dart';
import 'supabase_auth_service.dart';
import 'authen_api_v2.dart';
// import 'firebase_auth_service.dart'; // TODO: Uncomment when using Firebase

class AuthManager {
  static late AuthService service;
  static String? accessToken; // ✅ Global Token Variable

  static void init() {
    final provider = dotenv.env['AUTH_PROVIDER'];
    print('🔌 AuthManager Init: Provider = $provider');
    if (provider == 'CUSTOM') {
      service = CustomAuthService();
      // } else if (provider == 'FIREBASE') {
      //   // service = FirebaseAuthService(); // TODO: Uncomment when using Firebase
    } else {
      // Default to Supabase
      print('🚀 Using Supabase Auth Service');
      service = SupabaseAuthService();
    }
  }
}
