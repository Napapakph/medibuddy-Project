import 'package:flutter/material.dart';
import 'auth_manager.dart'; // Import AuthManager
import '../authen_pages/login_screen.dart';
import '../profile_pages/create_profile_screen.dart';
import 'notification_launch_guard.dart';
import 'app_route_observer.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    // ── Guard: if alarm flow is active, do NOT auto-redirect ──
    final currentRoute = AppRouteObserver.currentRouteName;
    if (NotificationLaunchGuard.isHandlingNotificationOpen &&
        NotificationLaunchGuard.isAlarmFlowRoute(currentRoute)) {
      debugPrint(
          '🔔 [AuthGate] Guard active on $currentRoute → skipping auto-redirect');
      // Return a safe, harmless scaffold while the alarm screen is on top.
      // This is only reached if AuthGate is rebuilt in the background.
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return FutureBuilder<String?>(
      future: AuthManager.service.getAccessToken(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final token = snapshot.data;
        if (token != null && token.isNotEmpty) {
          return const ProfileScreen();
        }

        return const LoginScreen();
      },
    );
  }
}
