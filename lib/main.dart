import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'services/device_token_service.dart';
import 'services/auth_manager.dart';
import 'authen_pages/login_screen.dart';
import 'authen_pages/signup_screen.dart';
import 'authen_pages/forget_password.dart';
import 'profile_pages/create_profile_screen.dart';
import 'profile_pages/select_profile.dart';
import 'services/auth_gate.dart';
import 'home_pages/home_screen.dart';
import 'profile_pages/library_profile.dart';
import 'add_medicine/medicine_list_screen.dart';
import 'export_pdf/history.dart';
import 'OCR/camera_ocr.dart';
import 'services/old_service/sync_user.dart';
import 'services/token_manager.dart';
import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'search_medicine/medicine_search_page.dart';
import 'user_request/user_request_screen.dart';
import 'alarm_medicine/alarm_screen.dart';
import 'set_remind/setRemind_screen.dart';
import 'medication-tracking/add_follower.dart';
import 'medication-tracking/follower.dart';
import 'medication-tracking/following.dart';
import 'package:app_links/app_links.dart';
import 'services/notification_launch_guard.dart';
import 'services/app_route_observer.dart';

const bool kDisableAuthGate =
    true; // เปลี่ยนเป็น false เมื่อต้องการเปิดใช้งาน AuthGate

late final StreamSubscription<AuthState> _authSub;
final FlutterLocalNotificationsPlugin flnp = FlutterLocalNotificationsPlugin();
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
late final DeviceTokenService
    globalDeviceTokenService; // 🔹 EXPOSED GLOBALLY FOR CUSTOM AUTH

late AppLinks _appLinks;
StreamSubscription<Uri>? _linkSubscription;

// One-shot pending alarm navigation (replaces recursive attemptNavigation)
Map<String, dynamic>? _pendingAlarmArgs;
bool _pendingAlarmScheduled = false;

// Global instance of the route observer
final appRouteObserver = AppRouteObserver();

const AndroidNotificationChannel channel = AndroidNotificationChannel(
  'medibuddy_alarm', // เปลี่ยนเป็นชื่อใหม่ เพื่อทำลายบั๊กแบนเนอร์ที่ไม่เด้งบนเครื่องที่เผลอจำค่าเก่า
  'MediBuddy Notifications',
  description: 'Foreground notifications',
  importance: Importance.high,
);

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse response) {
  debugPrint('🔔 LOCAL NOTI TAP (bg) payload=${response.payload}');
}

List<Map<String, dynamic>> _parsePayloadItems(dynamic raw) {
  if (raw == null) return [];
  try {
    final decoded = raw is String ? jsonDecode(raw) : raw;
    if (decoded is! List) return [];
    final items = <Map<String, dynamic>>[];
    for (final item in decoded) {
      if (item is Map) {
        items.add(item.map((key, value) => MapEntry(key.toString(), value)));
      }
    }
    return items;
  } catch (e) {
    debugPrint('❌ Failed to decode payload list: $e');
    return [];
  }
}

Map<String, dynamic> _payloadFromRemoteMessage(RemoteMessage message) {
  final data = Map<String, dynamic>.from(message.data);
  final notification = message.notification;
  int menuIndex = 0;
  final rawMenuIndex = data['menuIndex'];
  if (rawMenuIndex is int) {
    menuIndex = rawMenuIndex;
  } else if (rawMenuIndex != null) {
    menuIndex = int.tryParse(rawMenuIndex.toString()) ?? 0;
  }

  final payload = <String, dynamic>{}..addAll(data);
  payload['route'] = data['route']?.toString() ?? '/alarm';
  payload['title'] = data['title']?.toString() ?? (notification?.title ?? '');
  payload['body'] = data['body']?.toString() ?? (notification?.body ?? '');
  payload['time'] = data['time']?.toString();
  payload['menuIndex'] = menuIndex;

  payload['type'] = data['type']?.toString();
  payload['logId'] = data['logId']?.toString();
  payload['profileId'] = data['profileId']?.toString();
  payload['mediListId'] = data['mediListId']?.toString();
  payload['mediRegimenId'] = data['mediRegimenId']?.toString();
  payload['scheduleTime'] = data['scheduleTime']?.toString();
  payload['snoozedCount'] = data['snoozedCount']?.toString();
  payload['isSnoozeReminder'] = data['isSnoozeReminder']?.toString();

  final items = _parsePayloadItems(data['payload']);
  if (items.isNotEmpty) {
    payload['items'] = items;
  }

  // Handle SUMMARY types
  if (payload['type'] == 'MEDICATION_SUMMARY' ||
      payload['type'] == 'SNOOZE_SUMMARY') {
    final t = payload['title']?.toString().trim() ?? '';
    final b = payload['body']?.toString().trim() ?? '';
    final itemName = items.isNotEmpty
        ? (items.first['body'] ?? items.first['medicineName'] ?? '')
        : '';

    if (t.isEmpty) {
      payload['title'] = payload['type'] == 'SNOOZE_SUMMARY'
          ? 'แจ้งเตือนเลื่อนยา'
          : 'แจ้งเตือนยา';
    }
    if (b.isEmpty) {
      final count = data['count'] ?? items.length;
      if (count.toString() == '1' && itemName.toString().isNotEmpty) {
        payload['body'] = itemName.toString();
      } else {
        payload['body'] = 'ถึงเวลาทานยา $count รายการ';
      }
    }
    if (payload['scheduleTime'] == null) {
      payload['scheduleTime'] = data['timestamp']?.toString() ??
          (items.isNotEmpty ? items.first['scheduleTime']?.toString() : null);
    }
  }

  debugPrint('🔔 payload ฝั่ง  mobile = $payload');
  debugPrint('🔔 onMessage raw data = ${message.data}');
  debugPrint(
      '🔔 payload ฝั่ง OS = title:${message.notification?.title} body:${message.notification?.body}');
  debugPrint(
      '🔔 onMessage payload items=${items.isNotEmpty} count=${items.length}');
  if (items.isNotEmpty) {
    debugPrint(
        '🔔 onMessage payload first item keys=${items.first.keys.toList()}');
  }

  return payload;
}

Map<String, dynamic>? _payloadFromString(String? payload) {
  if (payload == null || payload.trim().isEmpty) return null;
  try {
    final decoded = jsonDecode(payload);
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is Map) {
      return decoded.map((key, value) => MapEntry(key.toString(), value));
    }
  } catch (_) {}
  return null;
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('📩 FCM onBackgroundMessage received!');

  // OS จะจัดการเรื่องการโชว์แจ้งเตือนเองผ่านคีย์ "notification" ไม่ต้องรัน flnp.show()
  debugPrint('📩 OS is handling background notification. Skipped flnp.show()');
}

void openAlarmFromNoti({String? payload, Map<String, dynamic>? data}) {
  debugPrint('\n================ [DEBUG NOTIFICATION CLICK] ================');
  debugPrint('RAW payload: $payload');
  debugPrint('RAW data: $data');
  Map<String, dynamic>? parsed;
  if (payload != null) {
    parsed = _payloadFromString(payload);
  }
  parsed ??= data;

  if (parsed != null) {
    debugPrint('PARSED MAP KEYS: ${parsed.keys.toList()}');
    final allLogIds = <String>[];

    // Root logId
    if (parsed['logId'] != null) allLogIds.add(parsed['logId'].toString());

    // Local debug helper function
    void extractFrom(dynamic raw) {
      if (raw == null) return;
      try {
        final decoded = raw is String ? jsonDecode(raw) : raw;
        if (decoded is List) {
          for (final item in decoded) {
            if (item is Map && item['logId'] != null) {
              allLogIds.add(item['logId'].toString());
            } else if (item != null) {
              allLogIds.add(item.toString());
            }
          }
        }
      } catch (_) {}
    }

    extractFrom(parsed['items']);
    extractFrom(parsed['payload']);
    if (parsed['data'] is Map) {
      final innerData = parsed['data'] as Map;
      if (innerData['logId'] is List) {
        extractFrom(innerData['logId']);
      } else if (innerData['logId'] != null) {
        allLogIds.add(innerData['logId'].toString());
      }
    }

    final uniqueLogIds = allLogIds.toSet().toList();
    debugPrint('➡️ EXTRACTED logIds COUNT = ${uniqueLogIds.length}');
    debugPrint('➡️ EXTRACTED logIds VALUES = $uniqueLogIds');
  } else {
    debugPrint('❌ PARSED MAP is NULL');
  }
  debugPrint('============================================================\n');

  if (parsed == null) return;

  // ── Dedupe key ──
  final dedupeKey = parsed['messageId']?.toString() ??
      '${parsed['timestamp'] ?? parsed['scheduleTime'] ?? ''}_${parsed['type'] ?? ''}';

  if (NotificationLaunchGuard.isDuplicate(dedupeKey)) {
    debugPrint(
        '🧪 openAlarmFromNoti deduplicated duplicate request for key: $dedupeKey');
    return;
  }

  // ── Resolve profile ID (int?) for guard ──
  int? profileId;
  final rawPid = parsed['profileId'];
  if (rawPid is int) {
    profileId = rawPid;
  } else if (rawPid != null) {
    profileId = int.tryParse(rawPid.toString());
  }

  // ── Activate guard ──
  NotificationLaunchGuard.activate(notiKey: dedupeKey, profileId: profileId);

  // ── One-shot deterministic navigation ──
  final nav = navigatorKey.currentState;
  if (nav != null) {
    // Navigator is ready → navigate immediately
    debugPrint('🧪 Navigator ready → pushNamedAndRemoveUntil /alarm');
    nav.pushNamedAndRemoveUntil(
      '/alarm',
      (route) => false,
      arguments: parsed,
    );
  } else {
    // Navigator not yet mounted (cold start) → store args and schedule ONE callback
    debugPrint('🧪 Navigator not ready → storing _pendingAlarmArgs');
    _pendingAlarmArgs = parsed;
    if (!_pendingAlarmScheduled) {
      _pendingAlarmScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _pendingAlarmScheduled = false;
        final pending = _pendingAlarmArgs;
        _pendingAlarmArgs = null;
        if (pending == null) return;

        final navInner = navigatorKey.currentState;
        if (navInner != null) {
          debugPrint('🧪 Post-frame callback → pushNamedAndRemoveUntil /alarm');
          navInner.pushNamedAndRemoveUntil(
            '/alarm',
            (route) => false,
            arguments: pending,
          );
        } else {
          debugPrint(
              '❌ Post-frame callback: navigator STILL null — cannot navigate to /alarm');
        }
      });
    }
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  // ✅ INIT FIREBASE แค่ครั้งเดียว
  await Firebase.initializeApp();

  // ✅ ลงทะเบียนเพื่อรับ Background Messages กรณีที่แอปถูกปิดทิ้งหรืออยู่ในพื้นหลัง
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  debugPrint('🌿 API_BASE_URL from env = "${dotenv.env['API_BASE_URL']}"');
  print('ENV = ${dotenv.env}');
  print('BASE = ${dotenv.env['API_BASE_URL']}');

  final isAndroid = !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  debugPrint('Firebase init: start (isAndroid=$isAndroid)');
  var firebaseReady = false;
  if (isAndroid) {
    try {
      debugPrint('Firebase init: ok (apps=${Firebase.apps.length})');
      firebaseReady = true;
    } catch (e) {
      debugPrint('Firebase init failed: $e');
    }
  } else {
    debugPrint('Firebase init: skipped (non-android)');
  }

  if (isAndroid && firebaseReady) {
    debugPrint('DeviceTokenService: init listener');
    // ✅ เรียกเฉพาะ Android เท่านั้น
    await _setupLocalNotifications();

    // ⚡ บังคับขอสิทธิแจ้งเตือน Android 13+ (POST_NOTIFICATIONS) ให้เด้งอัปให้ชัวร์
    await flnp
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  } else {
    debugPrint('DeviceTokenService: skip init listener');
  }

  // ✅ request permission
  await FirebaseMessaging.instance.requestPermission();

  // ✅ บังคับให้ Push Notification แสดงแบนเนอร์ได้แม้แอปอยู่เบื้องหน้า (โดยเฉพาะ iOS และช่วยในบางกรณี)
  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );

  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    debugPrint('🔔 FCM TAP data=${message.data}');
    debugPrint('➡️ ROUTING TO /alarm (fcm)');
    openAlarmFromNoti(data: _payloadFromRemoteMessage(message));
  });

  final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
  debugPrint('🧪 getInitialMessage != null: ${initialMessage != null}');
  if (initialMessage != null) {
    debugPrint(
        '🧪 initialMessage.data keys: ${initialMessage.data.keys.toList()}');
    debugPrint('🔔 FCM INITIAL TAP data=${initialMessage.data}');
    debugPrint('➡️ ROUTING TO /alarm (initial/terminated)');
    openAlarmFromNoti(data: _payloadFromRemoteMessage(initialMessage));
  }

  // ✅ 3. LISTENER สำหรับ FOREGROUND
  FirebaseMessaging.onMessage.listen((RemoteMessage msg) async {
    debugPrint('📩 FCM onMessage (foreground)');

    final formattedPayload = _payloadFromRemoteMessage(msg);
    // Parse key to HH:mm for notification ID
    String scheduleKey = formattedPayload['time'] ?? '??:??';
    final rawSchedule = formattedPayload['scheduleTime'];
    if (rawSchedule != null) {
      final dt = DateTime.tryParse(rawSchedule.toString());
      if (dt != null) {
        final local = dt.toLocal();
        final hh = local.hour.toString().padLeft(2, '0');
        final mm = local.minute.toString().padLeft(2, '0');
        scheduleKey = '$hh:$mm';
      }
    }

    // ถ้าไม่มีเวลาให้ใช้เวลาปัจจุบัน
    if (scheduleKey == '??:??') {
      scheduleKey = DateTime.now().minute.toString();
    }

    // ✅ ONLY display flnp.show() when the app is in the FOREGROUND where OS does not show banners automatically.
    final titleText = formattedPayload['title'] ?? 'MediBuddy Reminder';
    final bodyText = formattedPayload['body'] ?? 'Time to take your medication';
    final jsonString = jsonEncode(formattedPayload);

    await flnp.show(
      scheduleKey.hashCode & 0x7FFFFFFF, // Stable ID per minute
      titleText,
      bodyText,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channel.id,
          channel.name,
          channelDescription: channel.description,
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          styleInformation: BigTextStyleInformation(bodyText),
        ),
      ),
      payload: jsonString,
    );
  });

  await Supabase.initialize(
    url: 'https://aoiurdwibgudsxhoxcni.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFvaXVyZHdpYmd1ZHN4aG94Y25pIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQxNjY3OTcsImV4cCI6MjA3OTc0Mjc5N30.3aPHErdnVMHVmjcOk55KCLhUw6rPCzu4Ke5DWqQNsyg',
    authOptions: const FlutterAuthClientOptions(
      autoRefreshToken: true,
    ),
  );

  final supa = Supabase.instance.client;
  globalDeviceTokenService = DeviceTokenService(supabase: supa);
  await globalDeviceTokenService.initializeAuthListener();

  // ✅ บังคับยิง register แบบดื้อๆ ทันทีที่เปิดแอป (เพื่ออุดรอยรั่ว Custom Auth API)
  globalDeviceTokenService.registerDeviceToken(force: true);

  // ⭐ โหลดข้อมูล format วันที่ของ locale ภาษาไทย
  await initializeDateFormatting('th_TH', null);

  // ⭐ ตั้ง locale default ให้เป็นไทย (จะได้ไม่ต้องใส่ใน DateFormat ทุกครั้ง)
  Intl.defaultLocale = 'th_TH';

  // ✅ Init Auth Manager
  try {
    AuthManager.init();
  } catch (e, stack) {
    debugPrint('💥 AuthManager Init Failed: $e');
    debugPrint(stack.toString());
    // Fallback?
  }

  // ✅ auth lifecycle listener (เรียกครั้งเดียว)
  _authSub = Supabase.instance.client.auth.onAuthStateChange.listen(
    (data) async {
      if (data.event == AuthChangeEvent.signedIn) {
        await SyncUserService().syncUser(allowMerge: true);
      }
    },
  );

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initDeepLinks();

    // ✅ When refresh token expires, redirect to login
    TokenManager.onSessionExpired = _handleSessionExpired;
  }

  void _handleSessionExpired() {
    debugPrint('🔒 Session expired → navigating to login');

    // ── Guard: defer redirect if alarm flow is active ──
    final currentRoute = AppRouteObserver.currentRouteName;
    if (NotificationLaunchGuard.isHandlingNotificationOpen &&
        NotificationLaunchGuard.isAlarmFlowRoute(currentRoute)) {
      debugPrint(
          '🔒 [Guard] Session expired but alarm flow active on $currentRoute '
          '→ deferring redirect');
      NotificationLaunchGuard.pendingSessionRedirect = true;
      return;
    }

    final ctx = navigatorKey.currentContext;
    if (ctx == null) return;

    // Sign out Supabase session too (if using Supabase)
    try {
      Supabase.instance.client.auth.signOut();
    } catch (_) {}

    // Clear global token
    AuthManager.accessToken = null;

    // Navigate to login and clear the stack
    debugPrint('🔒 Pushing /login (stack trace follows)');
    debugPrint(StackTrace.current.toString());
    navigatorKey.currentState?.pushNamedAndRemoveUntil(
      '/login',
      (route) => false,
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // ✅ TokenManager handles refreshing proactively when API calls are made.
      debugPrint(
          '📱 App Resumed: Deferred proactive token refresh to TokenManager.');
    } else if (state == AppLifecycleState.paused) {
      debugPrint('💤 App Paused.');
    }
  }

  Future<void> _initDeepLinks() async {
    _appLinks = AppLinks();

    // จัดการเมื่อเปิดแอปครั้งแรกจาก Deep Link (Terminated state)
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        debugPrint('🔗 Initial Deep Link: $initialUri');
        _handleDeepLink(initialUri);
      }
    } catch (e) {
      debugPrint('🔗 Failed to receive initial uri: $e');
    }

    // จัดการเมื่อแอปเปิดอยู่แล้ว (Background/Foreground state)
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      debugPrint('🔗 Received Deep Link while running: $uri');
      _handleDeepLink(uri);
    }, onError: (err) {
      debugPrint('🔗 Deep Link stream error: $err');
    });
  }

  void _handleDeepLink(Uri uri) {
    debugPrint('====================================');
    debugPrint('📌 Deep Link FULL URI: $uri');
    debugPrint('📌 Deep Link Host: ${uri.host}, Path: ${uri.path}');
    debugPrint('📌 Deep Link Query Parameters: ${uri.queryParameters}');
    debugPrint('====================================');

    if (uri.host == 'forget-password' ||
        uri.host == 'login-callback' ||
        uri.path.endsWith('verify-redirect')) {
      final token = uri.queryParameters['token'];
      final error = uri.queryParameters['error'];
      final errorCode = uri.queryParameters['error_code'];
      final errorDescription = uri.queryParameters['error_description'];

      debugPrint('🔎 Parsed Values -> token: "$token"');
      debugPrint('🔎 Parsed Values -> error: "$error"');
      debugPrint('🔎 Parsed Values -> error_code: "$errorCode"');
      debugPrint('🔎 Parsed Values -> error_description: "$errorDescription"');

      // ตรวจจับ error ใดๆ ที่ส่งมา
      if ((error != null && error.isNotEmpty) ||
          (errorCode != null && errorCode.isNotEmpty)) {
        debugPrint('❌ Deep Link Error Detected!');
        // รอให้ UI พร้อมก่อนแสดง Dialog
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final context = navigatorKey.currentContext;
          if (context != null) {
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('ข้อผิดพลาด'),
                content: const Text(
                    'ลิงก์รีเซ็ตรหัสผ่านหมดอายุหรือไม่ถูกต้อง กรุณาทำรายการใหม่อีกครั้ง'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('ตกลง'),
                  ),
                ],
              ),
            );
          }
        });
        return;
      }

      if (token != null && token.isNotEmpty) {
        debugPrint(
            '🔑 Found Reset Token: $token, Routing to /forget_password...');
        // สั่งเปิดหน้า ForgetPassword
        // ใช้ Future.delayed เพื่อให้มั่นใจว่า Navigator ถูกสร้างเสร็จแล้ว (กรณี Cold Start)
        Future.delayed(const Duration(milliseconds: 300), () {
          navigatorKey.currentState
              ?.pushNamed('/forget_password', arguments: token);
        });
      } else {
        debugPrint('❌ Deep Link matched but NO token found!');
      }
    } else {
      debugPrint('ℹ️ Deep Link did not match any routing rules.');
    }
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Mali',
      ),
      title: 'MediBuddy',
      navigatorKey: navigatorKey,
      navigatorObservers: [appRouteObserver],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('th', 'TH'),
        Locale('en', 'US'),
      ],
      locale: const Locale('th', 'TH'),

      // จัดการเมื่อแอปถูกเปิดครั้งแรกจาก Deep Link (Cold Start)
      onGenerateInitialRoutes: (initialRouteName) {
        final routes = <Route>[];
        // 1. ใส่หน้า Base เสมอ (LoginScreen หรือ AuthGate)
        routes.add(MaterialPageRoute(builder: (_) => defaultPage()));

        // 2. ถ้ามีลิงก์แนบมาด้วย ให้พิจารณาซ้อนหน้า ForgetPassword ทับไปอีกชั้น
        final uri = Uri.tryParse(initialRouteName);
        if (uri != null &&
            (uri.host == 'forget-password' ||
                uri.path.endsWith('verify-redirect'))) {
          final token = uri.queryParameters['token'];
          if (token != null && token.isNotEmpty) {
            debugPrint('🚀 Initial Route Routing to /forget_password');
            routes.add(MaterialPageRoute(
                builder: (_) => ForgetPassword(token: token)));
          }
        }
        return routes;
      },

      //  รับ deep link ที่มาเป็น "/?code=..."
      onGenerateRoute: (settings) {
        final uri = Uri.tryParse(settings.name ?? '/');

        // ถ้า parse ไม่ได้ ก็กลับไปหน้าแรก : parse = การแปลงข้อความ (String) ให้เป็น Uri object
        if (uri == null) {
          return MaterialPageRoute(builder: (_) => const AuthGate());
        }

        // จัดการ Deep Link เมื่อแอปถูกปลุกขึ้นมาจากพื้นหลัง (Hot Start)
        if (uri.host == 'forget-password' ||
            uri.host == 'login-callback' ||
            uri.path.endsWith('verify-redirect')) {
          final token = uri.queryParameters['token'];
          if (token != null && token.isNotEmpty) {
            debugPrint('🚀 Hot Start Routing to /forget_password');
            return MaterialPageRoute(
                builder: (_) => ForgetPassword(token: token));
          }
          // ถ้าไม่มี token (เช่น error) ก็กระเด็นไปหน้า Login
          // ซึ่งตัว app_links จะแสดง Error Dialog ให้เราอยู่แล้ว
          return MaterialPageRoute(builder: (_) => defaultPage());
        }

        //  สำคัญ: "/?code=..." จะมี uri.path = "/"
        if (uri.path == '/') {
          return MaterialPageRoute(builder: (_) => defaultPage());
        }

        // (ถ้าจะมีหน้าอื่นค่อยเพิ่ม)
        switch (uri.path) {
          case '/login':
            return MaterialPageRoute(builder: (_) => const LoginScreen());
          case '/signup':
            return MaterialPageRoute(builder: (_) => const SignupScreen());
          case '/profile':
            return MaterialPageRoute(builder: (_) => const ProfileScreen());
          case '/select_profile':
            return MaterialPageRoute(builder: (_) => const SelectProfile());
          case '/home':
            return MaterialPageRoute(
              settings: settings, // 🔥 FIX: keep arguments
              builder: (_) => const Home(),
            );
          case '/forget_password':
            final token = settings.arguments as String?;
            debugPrint('🚀 Routing to /forget_password, token: $token');
            return MaterialPageRoute(
                builder: (_) => ForgetPassword(token: token));
          case '/library_profile':
            return MaterialPageRoute(builder: (_) => const LibraryProfile());
          case '/list_medicine':
            final args = settings.arguments; // ✅ PROFILE_ID: accept Map or int
            int profileId = 0; // ⚠️ NOTE: default when args missing
            if (args is Map) {
              final raw = args['profileId'];
              if (raw is int) {
                profileId = raw;
              } else if (raw != null) {
                profileId = int.tryParse(raw.toString()) ?? 0;
              }
            } else if (args is int) {
              profileId = args;
            }
            return MaterialPageRoute(
              builder: (_) =>
                  ListMedicinePage(profileId: profileId), // ✅ PROFILE_ID: pass
            );

          case '/history':
            return MaterialPageRoute(builder: (_) => const HistoryPage());
          case '/search_medicine':
            final args = settings.arguments; // ✅ PROFILE_ID: accept Map or int
            int profileId = 0; // ⚠️ NOTE: default when args missing
            if (args is Map) {
              final raw = args['profileId'];
              if (raw is int) {
                profileId = raw;
              } else if (raw != null) {
                profileId = int.tryParse(raw.toString()) ?? 0;
              }
            } else if (args is int) {
              profileId = args;
            }
            return MaterialPageRoute(
                builder: (_) => const MedicineSearchPage());
          case '/user_request':
            return MaterialPageRoute(builder: (_) => const UserRequestScreen());
          case '/alarm':
            final args = settings.arguments;
            Map<String, dynamic>? payload;
            if (args is Map<String, dynamic>) {
              payload = args;
            } else if (args is Map) {
              payload =
                  args.map((key, value) => MapEntry(key.toString(), value));
            } else if (args is String) {
              payload = _payloadFromString(args);
            }
            return MaterialPageRoute(
              builder: (_) => AlarmScreen(payload: payload),
            );
          case '/set_remind':
            final args = settings.arguments as Map<String, dynamic>? ?? {};
            final medicines = args['medicines']; // แคสต์ให้ถูกชนิดตามจริง
            return MaterialPageRoute(
              builder: (_) => SetRemindScreen(medicines: medicines),
            );
          case '/following':
            return MaterialPageRoute(builder: (_) => const FollowingScreen());
          case '/follower':
            return MaterialPageRoute(builder: (_) => const FollowerScreen());
          case '/add_follower':
            return MaterialPageRoute(builder: (_) => const AddFollowerScreen());
          default:
            return MaterialPageRoute(builder: (_) => defaultPage());
        }
      },
    );
  }
}

Future<void> _setupLocalNotifications() async {
  debugPrint('🧪 kIsWeb=$kIsWeb platform=$defaultTargetPlatform');

  const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');

  const initSettings = InitializationSettings(
    android: androidInit,
  );

  await flnp.initialize(
    initSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) {
      debugPrint('🔔 LOCAL NOTI TAP payload=${response.payload}');
      debugPrint('➡️ ROUTING TO /alarm (local)');
      openAlarmFromNoti(payload: response.payload);
    },
    onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
  );
  debugPrint('✅ FLNP initialized');

  final launchDetails = await flnp.getNotificationAppLaunchDetails();
  if ((launchDetails?.didNotificationLaunchApp ?? false) &&
      launchDetails?.notificationResponse?.payload != null) {
    openAlarmFromNoti(payload: launchDetails?.notificationResponse?.payload);
  }

  // ✅ Android 8+ ต้องสร้าง channel
  await flnp
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  debugPrint('✅ Android notification channel ready');
}

Widget defaultPage() {
  return kDisableAuthGate ? const LoginScreen() : const AuthGate();
}
