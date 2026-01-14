import 'dart:async';
import 'dart:convert';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class DeviceTokenService {
  DeviceTokenService({
    FirebaseMessaging? messaging,
    DeviceInfoPlugin? deviceInfo,
    SupabaseClient? supabase,
    http.Client? httpClient,
  })  : _messaging = messaging ?? FirebaseMessaging.instance,
        _deviceInfo = deviceInfo ?? DeviceInfoPlugin(),
        _supabase = supabase ?? Supabase.instance.client,
        _http = httpClient ?? http.Client();

  static final DeviceTokenService instance = DeviceTokenService();

  final FirebaseMessaging _messaging;
  final DeviceInfoPlugin _deviceInfo;
  final SupabaseClient _supabase;
  final http.Client _http;

  StreamSubscription<AuthState>? _authSub;
  bool _initialized = false;
  String? _lastToken;
  String? _lastDeviceId;

  Future<void> initializeAuthListener() async {
    debugPrint('DeviceTokenService: initializeAuthListener called');
    if (_initialized) return;
    if (!_isAndroidDevice()) {
      debugPrint('DeviceTokenService: skip init (non-android)');
      return;
    }
    _initialized = true;

    _authSub = _supabase.auth.onAuthStateChange.listen((data) async {
      final event = data.event;
      debugPrint('DeviceTokenService: auth event=$event');
      if (event == AuthChangeEvent.signedIn ||
          event == AuthChangeEvent.tokenRefreshed) {
        await registerDeviceToken(accessToken: data.session?.accessToken);
      }
    });
  }

  Future<void> dispose() async {
    await _authSub?.cancel();
    _authSub = null;
    _initialized = false;
  }

  bool _isAndroidDevice() {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android;
  }

  Future<String> _resolveDeviceId() async {
    try {
      if (kIsWeb) {
        final webInfo = await _deviceInfo.webBrowserInfo;
        return webInfo.userAgent ?? 'web';
      }

      switch (defaultTargetPlatform) {
        case TargetPlatform.android:
          final info = await _deviceInfo.androidInfo;
          String? androidId;
          try {
            final dynamic dynInfo = info;
            androidId = dynInfo.androidId as String?;
          } catch (_) {}
          return androidId ?? info.id ?? '';
        case TargetPlatform.iOS:
          final info = await _deviceInfo.iosInfo;
          return info.identifierForVendor ?? '';
        case TargetPlatform.macOS:
          final info = await _deviceInfo.macOsInfo;
          return info.systemGUID ?? '';
        case TargetPlatform.windows:
          final info = await _deviceInfo.windowsInfo;
          return info.deviceId;
        case TargetPlatform.linux:
          final info = await _deviceInfo.linuxInfo;
          return info.machineId ?? '';
        case TargetPlatform.fuchsia:
          return 'fuchsia';
      }
    } catch (e) {
      debugPrint('--------------------DeviceTokenService: deviceId error: $e');
    }
    return '';
  }

  Future<void> registerDeviceToken({
    String? accessToken,
    bool force = false,
  }) async {
    debugPrint('DeviceTokenService: registerDeviceToken called');
    if (!_isAndroidDevice()) {
      debugPrint('DeviceTokenService: skip register (non-android)');
      return;
    }
    final baseUrl = (dotenv.env['API_BASE_URL'] ?? '').trim();
    if (baseUrl.isEmpty) {
      debugPrint(
          '----------------DeviceTokenService: API_BASE_URL missing---------------------');
      return;
    }

    final token = (accessToken != null && accessToken.trim().isNotEmpty)
        ? accessToken.trim()
        : _supabase.auth.currentSession?.accessToken;
    if (token == null || token.isEmpty) {
      debugPrint(
          '-------------------DeviceTokenService: no access token--------------');
      return;
    }

    String? fcmToken;
    try {
      fcmToken = await _messaging.getToken();
    } catch (e) {
      debugPrint('--------------DeviceTokenService: getToken failed: $e');
      return;
    }

    if (fcmToken == null || fcmToken.trim().isEmpty) {
      debugPrint(
          '----------------------DeviceTokenService: FCM token empty ----------------------------');
      return;
    }
    debugPrint('🔑 FCM token = $fcmToken');

    final deviceId = await _resolveDeviceId();
    if (deviceId.isEmpty) {
      debugPrint('DeviceTokenService: deviceId empty');
      return;
    }
    debugPrint('📱 Device ID = $deviceId');

    if (!force && _lastToken == fcmToken && _lastDeviceId == deviceId) {
      debugPrint('DeviceTokenService: duplicate token/deviceId');
      return;
    }

    final uri = Uri.parse('$baseUrl/api/mobile/v1/auth/device-token');
    final body = jsonEncode({
      'token': fcmToken,
      'platform': 'android',
      'deviceId': deviceId,
    });

    try {
      final res = await _http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'accept': 'application',
        },
        body: body,
      );

      if (res.statusCode < 200 || res.statusCode >= 300) {
        debugPrint(
            'DeviceTokenService: register failed ${res.statusCode} ${res.body}');
        return;
      }

      _lastToken = fcmToken;
      _lastDeviceId = deviceId;
      debugPrint('DeviceTokenService: registered');
    } catch (e) {
      debugPrint('DeviceTokenService: register error: $e');
    }
  }
}
