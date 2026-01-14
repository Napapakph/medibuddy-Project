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
    required SupabaseClient supabase,
    FirebaseMessaging? messaging,
    DeviceInfoPlugin? deviceInfo,
    http.Client? httpClient,
  })  : _supabase = supabase,
        _messaging = messaging ?? FirebaseMessaging.instance,
        _deviceInfo = deviceInfo ?? DeviceInfoPlugin(),
        _http = httpClient ?? http.Client();

  final FirebaseMessaging _messaging;
  final DeviceInfoPlugin _deviceInfo;
  final SupabaseClient _supabase;
  final http.Client _http;

  StreamSubscription<AuthState>? _authSub;
  bool _initialized = false;

  String? _lastToken;
  String? _lastDeviceId;

  // ✅ เพิ่ม: จำ user ล่าสุดที่ “ส่งขึ้น backend” เพื่อจับการสลับบัญชี
  String? _lastUserId;

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
      final session = data.session;
      final currentUserId = session?.user.id;

      debugPrint('DeviceTokenService: auth event=$event');

      if (event == AuthChangeEvent.signedIn) {
        // ✅ login สำเร็จ: ถ้า user เปลี่ยน -> force ส่ง
        final isAccountChanged =
            currentUserId != null && currentUserId != _lastUserId;

        debugPrint(isAccountChanged
            ? '🔁 Account changed -> force register'
            : '✅ Same account -> try register (skip if duplicate)');

        await registerDeviceToken(
          accessToken: session?.accessToken,
          force: isAccountChanged, // ✅ สลับบัญชี = ส่งแน่นอน
          currentUserId: currentUserId,
        );
      }

      if (event == AuthChangeEvent.tokenRefreshed) {
        // ✅ token refresh ควรส่ง (อันนี้คือเหตุผลหลักของการ register)
        debugPrint('🔄 Token refreshed -> force register');
        await registerDeviceToken(
          accessToken: session?.accessToken,
          force: true,
          currentUserId: currentUserId,
        );
      }

      if (event == AuthChangeEvent.signedOut) {
        // ❗ ส่งหลัง logout ไม่ได้ เพราะไม่มี Bearer แล้ว
        // ✅ ทำสิ่งที่ถูกต้องแทน: reset cache เพื่อให้ login ครั้งหน้าส่งใหม่แน่นอน
        debugPrint('🚪 Signed out -> reset cached token/device/user');
        _lastToken = null;
        _lastDeviceId = null;
        _lastUserId = null;
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

    // ✅ เพิ่ม: ส่ง userId เข้ามาเพื่อ “จำว่าล่าสุดส่งให้ user ไหน”
    String? currentUserId,
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

    final token = _supabase.auth.currentSession?.accessToken;
    debugPrint('🔑 token supa = $token');
    if (token == null || token.isEmpty) {
      debugPrint(
          '-------------------DeviceTokenService: no access token--------------');
      return;
    }

    String? fcmToken;
    try {
      // ✅ getToken ทุกครั้งตาม requirement
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

    // ✅ ถ้าบัญชีเดิม + token/deviceId ไม่เปลี่ยน -> ไม่ส่ง + debug emoji
    if (!force && _lastToken == fcmToken && _lastDeviceId == deviceId) {
      debugPrint('🟡 Same account & same token/deviceId -> skip sending');
      return;
    }

    final uri = Uri.parse('$baseUrl/api/mobile/v1/auth/device-token');
    final body = jsonEncode({
      'token': fcmToken,
      'platform': 'android',
      'deviceId': deviceId,
    });

    final res = await _http.post(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'accept': 'application/json',
      },
      body: body,
    );

    final raw = res.body;
    debugPrint('📡 device-token response status=${res.statusCode}');
    debugPrint(
        '📦 device-token response body=${raw.isEmpty ? "(empty)" : raw}');

    if (res.statusCode < 200 || res.statusCode >= 300) {
      debugPrint('❌ DeviceTokenService: backend rejected request');
      return;
    }

// ✅ พยายาม parse เพื่อ “ยืนยัน” จาก response
    bool confirmed = false;
    String? confirmReason;

    if (raw.trim().isEmpty) {
      confirmed = true; // ยืนยันได้แค่ระดับ "API ตอบ 2xx"
      confirmReason = '2xx but empty body (cannot confirm DB write)';
    } else {
      try {
        final decoded = jsonDecode(raw);
        // รองรับหลายรูปแบบที่ backend มักใช้
        if (decoded is Map<String, dynamic>) {
          final success = decoded['success'];
          final id = decoded['id'] ?? decoded['data']?['id'];
          final message = decoded['message'];

          if (success == true || id != null) {
            confirmed = true; // ✅ มีหลักฐานว่า backend ทำงานสำเร็จ
            confirmReason =
                success == true ? 'success=true' : 'returned id=$id';
          } else {
            // ตอบ 2xx แต่ไม่ได้บอกว่าเขียน DB
            confirmed = true;
            confirmReason =
                '2xx but response has no success/id (check backend logs)';
            debugPrint('🟡 DeviceTokenService: response message=$message');
          }
        } else {
          confirmed = true;
          confirmReason = '2xx non-object response (cannot confirm DB write)';
        }
      } catch (e) {
        confirmed = true;
        confirmReason =
            '2xx but invalid JSON response (cannot confirm DB write)';
      }
    }

    _lastToken = fcmToken;
    _lastDeviceId = deviceId;
    _lastUserId = currentUserId ?? _supabase.auth.currentUser?.id;

    debugPrint(
      '✅ DeviceTokenService: SENT to backend. confirm=$confirmed ($confirmReason) '
      '👤 user=${_lastUserId ?? "unknown"} 📱 deviceId=$deviceId 🔑 tokenHash=${fcmToken.hashCode}',
    );
  }
}
