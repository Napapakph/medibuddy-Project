import 'package:flutter/material.dart';
import 'screens/login_screen.dart';

void main() {
  const app = MaterialApp(
    title: "My Flutter App",
    home: LoginScreen(),
  );
  runApp(app);
}
