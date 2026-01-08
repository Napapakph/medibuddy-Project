import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart ';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'pages/login.dart';
import 'pages/signup.dart';
import 'pages/forget_password.dart';
import 'Home/pages/profile_screen.dart';
import 'Home/pages/select_profile.dart';
import 'API/auth_gate.dart';
import 'Home/pages/home.dart';
import 'Home/pages/library_profile.dart';
import 'Home/pages/add_medicine/list_medicine.dart';

const bool kDisableAuthGate =
    true; // เปลี่ยนเป็น false เมื่อต้องการเปิดใช้งาน AuthGate
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  print('ENV = ${dotenv.env}');
  print('BASE = ${dotenv.env['API_BASE_URL']}');

  await Supabase.initialize(
    url: 'https://aoiurdwibgudsxhoxcni.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFvaXVyZHdpYmd1ZHN4aG94Y25pIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQxNjY3OTcsImV4cCI6MjA3OTc0Mjc5N30.3aPHErdnVMHVmjcOk55KCLhUw6rPCzu4Ke5DWqQNsyg',
  );
  // ⭐ โหลดข้อมูล format วันที่ของ locale ภาษาไทย
  await initializeDateFormatting('th_TH', null);

  // ⭐ ตั้ง locale default ให้เป็นไทย (จะได้ไม่ต้องใส่ใน DateFormat ทุกครั้ง)
  Intl.defaultLocale = 'th_TH';

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
            return MaterialPageRoute(
                builder: (_) => const ProfileScreen(
                      accessToken: '',
                    ));
          case '/select_profile':
            return MaterialPageRoute(
                builder: (_) => const SelectProfile(accessToken: ''));
          case '/home':
            return MaterialPageRoute(builder: (_) => const Home());
          case '/forget_password':
            return MaterialPageRoute(builder: (_) => const ForgetPassword());
          case '/library_profile':
            return MaterialPageRoute(
                builder: (_) => const LibraryProfile(
                      accessToken: '',
                    ));
          case '/list_medicine':
            return MaterialPageRoute(builder: (_) => const ListMedicinePage());

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
