import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class SyncUserService {
  SyncUserService({
    SupabaseClient? supabase,
    http.Client? httpClient,
  })  : _supabase = supabase ?? Supabase.instance.client,
        _http = httpClient ?? http.Client();

  final SupabaseClient _supabase;
  final http.Client _http;

  Future<void> syncUser({bool allowMerge = true}) async {
    final baseUrl = (dotenv.env['API_BASE_URL'] ?? '').trim();
    if (baseUrl.isEmpty) {
      debugPrint('❌ SyncUserService: API_BASE_URL missing');
      return;
    }

    final session = _supabase.auth.currentSession;
    final user = session?.user;
    final accessToken = session?.accessToken;

    if (user == null || accessToken == null || accessToken.isEmpty) {
      debugPrint('❌ SyncUserService: no session/accessToken');
      return;
    }

    final supabaseUserId = user.id;
    final email = user.email ?? '';

    final isGoogle =
        user.identities?.any((i) => i.provider == 'google') ?? false;
    final provider = isGoogle ? 'google' : 'email';

    debugPrint('🧩 appMetadata=${user.appMetadata}');
    debugPrint(
        '🧩 identities=${user.identities?.map((e) => e.provider).toList()}');
    debugPrint('✅ resolved provider=$provider');

    final uri = Uri.parse('$baseUrl/api/mobile/v1/auth/sync-user');
    final body = jsonEncode({
      'supabaseUserId': supabaseUserId,
      'email': email,
      'provider': provider, // ✅ google / email
      'allowMerge': allowMerge,
    });

    try {
      final res = await _http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
          'accept': 'application/json',
        },
        body: body,
      );

      debugPrint('📡 sync-user status=${res.statusCode}');
      debugPrint(
          '📦 sync-user body=${res.body.isEmpty ? "(empty)" : res.body}');

      if (res.statusCode < 200 || res.statusCode >= 300) {
        debugPrint('❌ SyncUserService: sync failed');
        return;
      }

      debugPrint('✅ SyncUserService: synced (provider=$provider)');
    } catch (e) {
      debugPrint('❌ SyncUserService: error $e');
    }
  }
}
