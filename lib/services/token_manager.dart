import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'auth_manager.dart'; // To update AuthManager.accessToken globally if needed
import 'package:flutter/widgets.dart';

class TokenManager {
  static const _storage = FlutterSecureStorage();
  static const String _refreshTokenKey = 'refresh_token';
  static const String _expiresAtKey =
      'expires_at'; // Optional: store expiration

  static String? _accessToken;
  static String? _refreshToken;
  static DateTime? _expiresAt;

  // Single-flight refresh mutex
  static Future<void>? _refreshFuture;

  /// Global callback when session is expired (refresh token invalid).
  /// Set this in main.dart to navigate to login screen.
  static VoidCallback? onSessionExpired;

  /// Getter for access token without triggering refresh
  static String? get currentAccessToken => _accessToken;

  /// Parses JWT to find expiration time
  static DateTime? _getExpirationFromJwt(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;

      final payload = parts[1];
      final normalized = base64Url.normalize(payload);
      final resp = base64Url.decode(normalized);
      final payloadMap = jsonDecode(utf8.decode(resp)) as Map<String, dynamic>;

      final exp = payloadMap['exp'];
      if (exp is int) {
        return DateTime.fromMillisecondsSinceEpoch(exp * 1000);
      }
    } catch (e) {
      debugPrint('TokenManager: Error parsing JWT: $e');
    }
    return null;
  }

  /// Initialize TokenManager from secure storage (call on app start if needed)
  static Future<void> init() async {
    _refreshToken = await _storage.read(key: _refreshTokenKey);
    final expStr = await _storage.read(key: _expiresAtKey);
    if (expStr != null) {
      _expiresAt = DateTime.tryParse(expStr);
    }
    // We do not store accessToken in secure storage to reduce latency.
    // The user must login again or the app will refresh token on startup using refreshToken.
  }

  /// Update session securely
  static Future<void> setSession({
    required String accessToken,
    required String? refreshToken,
    DateTime? expiresAt,
  }) async {
    _accessToken = accessToken;
    AuthManager.accessToken = accessToken; // Sync with legacy global

    _expiresAt = expiresAt ?? _getExpirationFromJwt(accessToken);

    if (refreshToken != null && refreshToken.isNotEmpty) {
      _refreshToken = refreshToken;
      await _storage.write(key: _refreshTokenKey, value: refreshToken);
    }

    if (_expiresAt != null) {
      await _storage.write(
        key: _expiresAtKey,
        value: _expiresAt!.toIso8601String(),
      );
    }
  }

  /// Clear all tokens (on logout or unrecoverable 401)
  static Future<void> clear() async {
    _accessToken = null;
    _refreshToken = null;
    _expiresAt = null;
    AuthManager.accessToken = null;

    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _expiresAtKey);
  }

  /// Get valid access token. Will trigger proactive refresh if expiring soon.
  static Future<String?> getValidAccessToken() async {
    if (_accessToken == null) {
      // If we don't have an access token in memory, but we have a refresh token,
      // we must refresh immediately.
      await refreshIfNeeded(force: true);
      return _accessToken;
    }

    if (_expiresAt != null) {
      final now = DateTime.now();
      // Proactive refresh: if expiring within 60 seconds
      if (_expiresAt!.difference(now).inSeconds < 60) {
        debugPrint(
            '🔄 TokenManager: Token expiring soon. Proactive refresh...');
        await refreshIfNeeded();
      }
    }

    return _accessToken;
  }

  /// Refreshes token if not already refreshing (Single-Flight Pattern)
  static Future<void> refreshIfNeeded({bool force = false}) async {
    // If a refresh is already in progress, just await it.
    if (_refreshFuture != null) {
      debugPrint('⏳ TokenManager: Waiting for existing refresh to complete...');
      await _refreshFuture;
      return;
    }

    _refreshFuture = _performRefresh(force: force);

    try {
      await _refreshFuture;
    } finally {
      // Clean up the future when done (success or error)
      _refreshFuture = null;
    }
  }

  static Future<void> _performRefresh({bool force = false}) async {
    // Try to load refresh token from memory or storage
    _refreshToken ??= await _storage.read(key: _refreshTokenKey);

    if (_refreshToken == null || _refreshToken!.isEmpty) {
      debugPrint(
          '❌ TokenManager: No refresh token available. Clearing session.');
      await clear();
      return;
    }

    // Only skip if not forced and token is still valid
    if (!force && _accessToken != null && _expiresAt != null) {
      if (_expiresAt!.difference(DateTime.now()).inSeconds >= 60) {
        // Someone else refreshed it just before us, or it's still valid
        return;
      }
    }

    final baseUrl = dotenv.env['API_BASE_URL']?.trim() ?? '';
    final dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      headers: {
        'Content-Type': 'application/json',
        'accept': 'application/json',
      },
    ));

    try {
      debugPrint('🔄 TokenManager: Calling /api/auth/v2/refresh API');
      final res = await dio.post('/api/auth/v2/refresh', data: {
        'refreshToken': _refreshToken,
      });

      final String? newAccessToken = res.data['accessToken'];
      if (newAccessToken != null) {
        debugPrint('✅ TokenManager: Refresh successful!');
        await setSession(
          accessToken: newAccessToken,
          refreshToken:
              _refreshToken, // Backend might not issue a new refresh token
        );
      } else {
        throw Exception('No accessToken in response');
      }
    } catch (e) {
      debugPrint('❌ TokenManager: Refresh failed: $e');
      await clear(); // Clear tokens to force re-login
      _notifySessionExpired();
    }
  }

  /// Safely invoke the session-expired callback on the next frame
  static void _notifySessionExpired() {
    if (onSessionExpired != null) {
      debugPrint('🔒 TokenManager: Session expired → redirecting to login');
      // Use addPostFrameCallback to avoid calling during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        onSessionExpired?.call();
      });
    }
  }
}
