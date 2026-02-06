import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthenApi {
  AuthenApi({http.Client? httpClient, SupabaseClient? supabase})
      : _http = httpClient ?? http.Client(),
        _supabase = supabase ?? Supabase.instance.client;

  final http.Client _http;
  final SupabaseClient _supabase;

  Future<String> checkEmailStatus({required String email}) async {
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
      throw Exception(
        'Check email failed: ${res.statusCode} ${res.body}',
      );
    }

    final data = jsonDecode(res.body);
    final status = data['status']?.toString().toLowerCase();
    switch (status) {
      case 'existing':
        return 'existing';
      case 'new':
        return 'new';
    }
    throw Exception('Unexpected status: ${data['status']}');
  }

  Future<void> confirmOtpAndSync({
    required String email,
    required String token,
  }) async {
    final result = await _verifyOtp(email: email, token: token);
    await _syncUser(
      accessToken: result.accessToken,
      supabaseUserId: result.supabaseUserId,
      email: email,
    );
  }

  Future<void> resendOtp({required String email}) async {
    await _supabase.auth.resend(
      type: OtpType.signup,
      email: email,
    );
  }

  Future<_OtpVerifyResult> _verifyOtp({
    required String email,
    required String token,
  }) async {
    const supabaseAnonKey =
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFvaXVyZHdpYmd1ZHN4aG94Y25pIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQxNjY3OTcsImV4cCI6MjA3OTc0Mjc5N30.3aPHErdnVMHVmjcOk55KCLhUw6rPCzu4Ke5DWqQNsy';

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
      throw Exception(
        'Verify failed: ${response.statusCode} ${response.body}',
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final accessToken = data['access_token']?.toString();
    if (accessToken == null || accessToken.isEmpty) {
      throw Exception('Verify success but no access_token');
    }

    String? supabaseUserId = data['user']?['id']?.toString();
    supabaseUserId ??= _parseJwt(accessToken)['sub']?.toString();

    if (supabaseUserId == null || supabaseUserId.isEmpty) {
      throw Exception('Verify success but no user id');
    }

    return _OtpVerifyResult(
      accessToken: accessToken,
      supabaseUserId: supabaseUserId,
    );
  }

  Future<void> _syncUser({
    required String accessToken,
    required String supabaseUserId,
    required String email,
  }) async {
    final baseUrl = (dotenv.env['API_BASE_URL'] ?? '').trim();
    if (baseUrl.isEmpty) {
      throw Exception('API_BASE_URL missing');
    }

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

  Map<String, dynamic> _parseJwt(String token) {
    final parts = token.split('.');
    if (parts.length != 3) throw Exception('invalid token');

    String normalize(String str) {
      str = str.replaceAll('-', '+').replaceAll('_', '/');
      switch (str.length % 4) {
        case 0:
          return str;
        case 2:
          return '$str==';
        case 3:
          return '$str=';
        default:
          throw Exception('invalid base64');
      }
    }

    final payload = utf8.decode(base64Url.decode(normalize(parts[1])));
    return jsonDecode(payload) as Map<String, dynamic>;
  }
}

class _OtpVerifyResult {
  final String accessToken;
  final String supabaseUserId;

  const _OtpVerifyResult({
    required this.accessToken,
    required this.supabaseUserId,
  });
}
