import 'package:flutter/material.dart';
import '../services/app_state.dart';

class BottomBar extends StatelessWidget {
  const BottomBar({
    super.key,
    this.currentRoute = '/home',
  });

  final String currentRoute;

  @override
  Widget build(BuildContext context) {
    final pid = AppState.instance.currentProfileId;

    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: Color(0xFF1F497D),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () {
              // TODO: ไปหน้าปฏิทิน (ถ้ามี route)
              // Navigator.pushNamed(context, '/calendar', arguments: {'profileId': pid});
            },
            icon: const Icon(Icons.people, color: Colors.white),
          ),

          // HOME
          GestureDetector(
            onTap: () {
              // ✅ ไม่สร้าง Home เปล่า ๆ / ไม่พึ่ง args
              if (currentRoute == '/home') return;

              Navigator.pushReplacementNamed(
                context,
                '/home',
                arguments: {
                  'profileId': pid,
                  'profileName': AppState.instance.currentProfileName,
                  'profileImage': AppState.instance.currentProfileImagePath,
                },
              );
            },
            child: Container(
              width: 52,
              height: 52,
              decoration: const BoxDecoration(
                color: Color(0xFFB7DAFF),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.home, color: Color(0xFF1F497D)),
            ),
          ),

          // LIST MEDICINE
          IconButton(
            onPressed: () {
              if (pid == null) {
                debugPrint(
                    '⚠️ MainBottomBar: profileId is null → go SelectProfile');
                Navigator.pushReplacementNamed(context, '/select_profile');
                return;
              }

              Navigator.pushNamed(
                context,
                '/list_medicine',
                arguments: {'profileId': pid},
              );

              debugPrint('💊 MainBottomBar: open list_medicine pid=$pid');
            },
            icon: const Icon(Icons.medication, color: Color(0xFFB7DAFF)),
          ),
        ],
      ),
    );
  }
}

Widget defaultPage() {
  return const Scaffold(
    body: Center(
      child: Text('หน้าไม่พบ (Default Page)'),
    ),
  );
}
