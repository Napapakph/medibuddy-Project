import 'package:flutter/material.dart';
import 'pages/login.dart';
import 'package:supabase_flutter/supabase_flutter.dart\ ';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://aoiurdwibgudsxhoxcni.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFvaXVyZHdpYmd1ZHN4aG94Y25pIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQxNjY3OTcsImV4cCI6MjA3OTc0Mjc5N30.3aPHErdnVMHVmjcOk55KCLhUw6rPCzu4Ke5DWqQNsyg',
  );

  const app = MaterialApp(
    title: "MediBuddy",
    home: LoginScreen(),
  );
  runApp(app);
}
