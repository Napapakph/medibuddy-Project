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
import 'pages/login.dart';
import 'pages/signup.dart';
import 'pages/forget_password.dart';
import 'Home/pages/profile_screen.dart';
import 'Home/pages/select_profile.dart';
import 'services/auth_gate.dart';
import 'Home/pages/home.dart';
import 'Home/pages/library_profile.dart';
import 'Home/pages/add_medicine/list_medicine.dart';
import 'Home/pages/history.dart';
import 'OCR/camera_ocr.dart';
import 'services/sync_user.dart';
import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'Home/pages/add_medicine/medicine_search_page.dart';
import 'Home/pages/user_request/user_request_screen.dart';
import 'Home/pages/alarm_screen.dart';
import 'Home/pages/set_remind/setRemind_screen.dart';
import 'Home/pages/medication-tracking/add_follower.dart';
import 'Home/pages/medication-tracking/follower.dart';
import 'Home/pages/medication-tracking/following.dart';

const bool kDisableAuthGate =
    true; // เปลี่ยนเป็น false เมื่อต้องการเปิดใช้งาน AuthGate

late final StreamSubscription<AuthState> _authSub;
final FlutterLocalNotificationsPlugin flnp = FlutterLocalNotificationsPlugin();
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

String? _pendingNotificationPayload;

const AndroidNotificationChannel channel = AndroidNotificationChannel(
  'medibuddy_high', // id ต้องคงที่
  'MediBuddy Notifications',
  description: 'Foreground notifications',
  importance: Importance.high,
);

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse response) {
  debugPrint('🔔 LOCAL NOTI TAP (bg) payload=${response.payload}');
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
  payload['time'] = data['time']?.toString() ?? '12:00';
  payload['menuIndex'] = menuIndex;

  payload['type'] = data['type']?.toString();
  payload['logId'] = data['logId']?.toString();
  payload['profileId'] = data['profileId']?.toString();
  payload['mediListId'] = data['mediListId']?.toString();
  payload['mediRegimenId'] = data['mediRegimenId']?.toString();
  payload['scheduleTime'] = data['scheduleTime']?.toString();
  payload['snoozedCount'] = data['snoozedCount']?.toString();
  payload['isSnoozeReminder'] = data['isSnoozeReminder']?.toString();

  debugPrint('🔔 onMessage payload to /alarm = $payload');
  debugPrint('🔔 onMessage raw data = ${message.data}');
  debugPrint(
      '🔔 onMessage notification title=${message.notification?.title} body=${message.notification?.body}');

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

void _navigateToAlarm(Map<String, dynamic> payload) {
  final route = payload['route']?.toString() ?? '/alarm';
  final nav = navigatorKey.currentState;
  if (nav == null) {
    _pendingNotificationPayload = jsonEncode(payload);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _flushPendingNotificationNavigation();
    });
    return;
  }
  nav.pushNamed(route, arguments: payload);
}

void _handleLocalNotificationTap(String? payload) {
  final parsed = _payloadFromString(payload);
  if (parsed == null) return;
  _navigateToAlarm(parsed);
}

void openAlarmFromNoti({String? payload, Map<String, dynamic>? data}) {
  debugPrint('?? ROUTING TO /alarm payload=$payload data=$data');
  Map<String, dynamic>? parsed;
  if (payload != null) {
    parsed = _payloadFromString(payload);
  }
  parsed ??= data;
  if (parsed == null) return;
  final nav = navigatorKey.currentState;
  if (nav == null) {
    _pendingNotificationPayload = jsonEncode(parsed);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _flushPendingNotificationNavigation();
    });
    return;
  }
  nav.pushNamed('/alarm', arguments: parsed);
}

void _flushPendingNotificationNavigation() {
  if (_pendingNotificationPayload == null) return;
  final payload = _pendingNotificationPayload;
  _pendingNotificationPayload = null;
  openAlarmFromNoti(payload: payload);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  // ✅ INIT FIREBASE แค่ครั้งเดียว
  await Firebase.initializeApp();

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
  } else {
    debugPrint('DeviceTokenService: skip init listener');
  }

  // ✅ request permission
  await FirebaseMessaging.instance.requestPermission();

  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    debugPrint('🔔 FCM TAP data=${message.data}');
    debugPrint('➡️ ROUTING TO /alarm (fcm)');
    openAlarmFromNoti(data: _payloadFromRemoteMessage(message));
  });

  final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
  debugPrint('🧪 initialMessage = ${initialMessage?.data}');
  if (initialMessage != null) {
    debugPrint('🔔 FCM INITIAL TAP data=${initialMessage.data}');
    debugPrint('➡️ ROUTING TO /alarm (initial)');
    openAlarmFromNoti(data: _payloadFromRemoteMessage(initialMessage));
  }

  // ✅ 3. LISTENER สำหรับ FOREGROUND (จุดสำคัญที่สุด)
  FirebaseMessaging.onMessage.listen((RemoteMessage msg) async {
    debugPrint('📩 FCM onMessage (foreground)');
    debugPrint('📌 title=${msg.notification?.title}');
    debugPrint('📝 body=${msg.notification?.body}');
    debugPrint('📦 data=${msg.data}');

    final notification = msg.notification;
    if (notification == null) return;

    // 🔔 สร้าง banner เอง
    final payload = jsonEncode(_payloadFromRemoteMessage(msg));
    debugPrint('🧪 showing local noti payload=$payload');
    await flnp.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channel.id,
          channel.name,
          channelDescription: channel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
      payload: payload,
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
  final deviceTokenService = DeviceTokenService(supabase: supa);
  await deviceTokenService.initializeAuthListener();

  // ⭐ โหลดข้อมูล format วันที่ของ locale ภาษาไทย
  await initializeDateFormatting('th_TH', null);

  // ⭐ ตั้ง locale default ให้เป็นไทย (จะได้ไม่ต้องใส่ใน DateFormat ทุกครั้ง)
  Intl.defaultLocale = 'th_TH';

  // ✅ auth lifecycle listener (เรียกครั้งเดียว)
  _authSub = Supabase.instance.client.auth.onAuthStateChange.listen(
    (data) async {
      if (data.event == AuthChangeEvent.signedIn) {
        await SyncUserService().syncUser(allowMerge: true);
      }
    },
  );

  runApp(const MyApp());
  _flushPendingNotificationNavigation();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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

      //  รับ deep link ที่มาเป็น "/?code=..."
      onGenerateRoute: (settings) {
        final uri = Uri.tryParse(settings.name ?? '/');

        // ถ้า parse ไม่ได้ ก็กลับไปหน้าแรก : parse = การแปลงข้อความ (String) ให้เป็น Uri object
        if (uri == null) {
          return MaterialPageRoute(builder: (_) => const AuthGate());
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
            return MaterialPageRoute(builder: (_) => const ForgetPassword());
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
          case '/camera_ocr':
            return MaterialPageRoute(builder: (_) => const CameraOcrPage());
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
    _pendingNotificationPayload = launchDetails?.notificationResponse?.payload;
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
