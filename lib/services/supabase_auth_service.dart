import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthResponse;
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'auth_service.dart';
import 'auth_manager.dart'; // Import

class SupabaseAuthService implements AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final http.Client _http = http.Client();

  @override
  Future<String?> register(
      {required String email, required String password}) async {
    try {
      await _supabase.auth.signUp(
        email: email,
        password: password,
      );
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (_) {
      return 'เกิดข้อผิดพลาด กรุณาลองใหม่อีกครั้ง';
    }
  }

  @override
  Future<AuthResponse> login(
      {required String email, required String password}) async {
    final res = await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
    final session = res.session;
    if (session == null) {
      throw Exception('Login success but no session token');
    }
    // ✅ Sync to Global
    AuthManager.accessToken = session.accessToken;

    print(
        '✅ [Supabase] Login Success. Token: ${session.accessToken.substring(0, 10)}...');
    return AuthResponse(
      accessToken: session.accessToken,
      refreshToken: session.refreshToken,
      user: res.user,
    );
  }

  @override
  Future<void> logout() async {
    await _supabase.auth.signOut();
  }

  @override
  Future<String?> refreshToken() async {
    // Supabase handles refresh automatically, but we can force it or get current session
    final session = _supabase.auth.currentSession;
    if (session == null) return null;
    // If expired, Supabase SDK might have already refreshed it or will on next call.
    // We can just return the current (possibly refreshed) token.
    return session.accessToken;
  }

  @override
  Future<String> checkEmailStatus(String email) async {
    final baseUrl = (dotenv.env['API_BASE_URL'] ?? '').trim();
    if (baseUrl.isEmpty) {
      throw Exception('API_BASE_URL missing');
    }

    final uri = Uri.parse('$baseUrl/api/mobile/v1/auth/check-email');
    final res = await _http.post(
      uri,
      headers: const {
        'Content-Type': 'application/json',
        'accept': 'application/json',
      },
      body: jsonEncode({'email': email}),
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      // Ideally logging here
      // throw Exception('Check email failed: ${res.statusCode}');
      return 'unknown'; // Fallback
    }

    final data = jsonDecode(res.body);
    final status = data['status']?.toString().toLowerCase();
    return status ?? 'unknown';
  }

  @override
  Future<AuthResponse> verifyOtp(
      {required String email, required String token}) async {
    // Reusing logic from AuthenApi._verifyOtp but adapting to return AuthResponse
    const supabaseAnonKey =
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFvaXVyZHdpYmd1ZHN4aG94Y25pIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQxNjY3OTcsImV4cCI6MjA3OTc0Mjc5N30.3aPHErdnVMHVmjcOk55KCLhUw6rPCzu4Ke5DWqQNsyg';
    // Note: Hardcoded key from original file. Ideally should be env but keeping as is for migration safety.

    final uri = Uri.parse(
      'https://aoiurdwibgudsxhoxcni.supabase.co/auth/v1/verify',
    );

    final response = await _http.post(
      uri,
      headers: const {
        'apikey': supabaseAnonKey,
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'email': email,
        'token': token,
        'type': 'email',
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Verify failed: ${response.statusCode} ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final accessToken = data['access_token']?.toString();
    if (accessToken == null || accessToken.isEmpty) {
      throw Exception('Verify success but no access_token');
    }

    String? supabaseUserId = data['user']?['id']?.toString();

    // Logic from AuthenApi: Sync User
    await _syncUser(
        accessToken: accessToken,
        supabaseUserId: supabaseUserId ?? '',
        email: email);

    // ✅ Sync to Global
    AuthManager.accessToken = accessToken;

    return AuthResponse(
      accessToken: accessToken,
      refreshToken: data['refresh_token']
          ?.toString(), // Supabase returns refresh_token usually
      user: data['user'],
    );
  }

  Future<void> _syncUser({
    required String accessToken,
    required String supabaseUserId,
    required String email,
  }) async {
    final baseUrl = (dotenv.env['API_BASE_URL'] ?? '').trim();
    if (baseUrl.isEmpty) return;

    final syncRes = await _http.post(
      Uri.parse('$baseUrl/api/mobile/v1/auth/sync-user'),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
        'accept': 'application/json',
      },
      body: jsonEncode({
        'supabaseUserId': supabaseUserId,
        'email': email,
        'provider': 'email',
        'allowMerge': true,
      }),
    );
    if (syncRes.statusCode < 200 || syncRes.statusCode >= 300) {
      throw Exception(
        'Sync user failed: ${syncRes.statusCode} ${syncRes.body}',
      );
    }
  }

  @override
  Future<void> resendOtp(String email) async {
    await _supabase.auth.resend(
      type: OtpType.signup,
      email: email,
    );
  }

  @override
  Future<String?> getAccessToken() async {
    // Check global first? Or trust Supabase client?
    // Supabase client is already in-memory.
    final token = _supabase.auth.currentSession?.accessToken;

    // Sync to global
    if (token != null) AuthManager.accessToken = token;

    if (token != null) {
      print(
          '🔑 [Supabase] getAccessToken: Found (${token.substring(0, 5)}...)');
    } else {
      print('⚠️ [Supabase] getAccessToken: Not found');
    }
    return token;
  }
}
