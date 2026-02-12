import 'package:flutter/material.dart';
import '../services/app_state.dart';
import 'package:icofont_flutter/icofont_flutter.dart';

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
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: Color(0xFF1F497D),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () {
              Navigator.pushNamed(
                context,
                '/following',
              );
            },
            icon: const Icon(
              Icons.favorite,
              color: Colors.white,
              size: 50,
            ),
          ),

          // HOME
          GestureDetector(
            onTap: () {
              // ✅ ไม่สร้าง Home เปล่า ๆ / ไม่พึ่ง args
              // if (currentRoute == '/home') return;

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
              width: 100,
              height: 100,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
              ),
              child: Image.asset(
                'assets/cat_home.png',
                width: 100,
                height: 100,
              ),
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
            icon: const Icon(
              IcoFontIcons.pills,
              color: Colors.white,
              size: 50,
            ),
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
