import 'package:flutter/material.dart';
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
import 'API/auth_gate.dart';
import 'Home/pages/home.dart';
import 'Home/pages/library_profile.dart';
import 'Home/pages/add_medicine/list_medicine.dart';
import 'Home/pages/history.dart';
import 'OCR/camera_ocr.dart';
import 'services/sync_user.dart';
import 'dart:async';

const bool kDisableAuthGate =
    true; // เปลี่ยนเป็น false เมื่อต้องการเปิดใช้งาน AuthGate

late final StreamSubscription<AuthState> _authSub;

Future<void> main() async {
  await dotenv.load(fileName: ".env");
  debugPrint('🌿 API_BASE_URL from env = "${dotenv.env['API_BASE_URL']}"');
  print('ENV = ${dotenv.env}');
  print('BASE = ${dotenv.env['API_BASE_URL']}');
  WidgetsFlutterBinding.ensureInitialized();

  final isAndroid = !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  debugPrint('Firebase init: start (isAndroid=$isAndroid)');
  var firebaseReady = false;
  if (isAndroid) {
    try {
      await Firebase.initializeApp();
      debugPrint('Firebase init: ok (apps=${Firebase.apps.length})');
      firebaseReady = true;
    } catch (e) {
      debugPrint('Firebase init failed: $e');
    }
  } else {
    debugPrint('Firebase init: skipped (non-android)');
  }

  await Supabase.initialize(
    url: 'https://aoiurdwibgudsxhoxcni.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFvaXVyZHdpYmd1ZHN4aG94Y25pIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQxNjY3OTcsImV4cCI6MjA3OTc0Mjc5N30.3aPHErdnVMHVmjcOk55KCLhUw6rPCzu4Ke5DWqQNsyg',
    authOptions: const FlutterAuthClientOptions(
      autoRefreshToken: true,
    ),
  );
  if (isAndroid && firebaseReady) {
    debugPrint('DeviceTokenService: init listener');
    await DeviceTokenService.instance.initializeAuthListener();
  } else {
    debugPrint('DeviceTokenService: skip init listener');
  }
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

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MediBuddy',

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

          default:
            return MaterialPageRoute(builder: (_) => defaultPage());
        }
      },
    );
  }
}

Widget defaultPage() {
  return kDisableAuthGate ? const LoginScreen() : const AuthGate();
}
