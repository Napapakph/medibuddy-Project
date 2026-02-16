import 'package:flutter/material.dart';
import '../services/app_state.dart';
import 'package:icofont_flutter/icofont_flutter.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

class BottomBar extends StatelessWidget {
  const BottomBar({
    super.key,
    this.currentRoute = '/home',
  });

  final String currentRoute;

  @override
  Widget build(BuildContext context) {
    final pid = AppState.instance.currentProfileId;

    final bool isHome = currentRoute == '/home';
    final bool isFollowing = currentRoute == '/following';
    final bool isMedicine = currentRoute == '/list_medicine';

    return SizedBox(
      height: 70,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          // Background Bar
          Container(
            height: 70,

            padding: const EdgeInsets.only(
                bottom: 24, left: 24, right: 24, top: 5), // ⭐ เพิ่มตรงนี้
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
                  icon: AnimatedScale(
                    scale: isFollowing ? 1.1 : 1.0,
                    duration: const Duration(milliseconds: 200),
                    child: AnimatedOpacity(
                      opacity: isFollowing ? 1.0 : 0.6,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        MdiIcons.heartCircle,
                        color: Colors.white,
                        size: 50,
                      ),
                    ),
                  ),
                ),

                // Spacer for Home Button
                const SizedBox(width: 100),

                // LIST MEDICINE
                IconButton(
                  onPressed: () {
                    if (pid == null) {
                      debugPrint(
                          '⚠️ MainBottomBar: profileId is null → go SelectProfile');
                      Navigator.pushReplacementNamed(
                          context, '/select_profile');
                      return;
                    }

                    Navigator.pushNamed(
                      context,
                      '/list_medicine',
                      arguments: {'profileId': pid},
                    );

                    debugPrint('💊 MainBottomBar: open list_medicine pid=$pid');
                  },
                  icon: AnimatedScale(
                    scale: isMedicine ? 1.1 : 1.0,
                    duration: const Duration(milliseconds: 200),
                    child: AnimatedOpacity(
                      opacity: isMedicine ? 1.0 : 0.6,
                      duration: const Duration(milliseconds: 200),
                      child: const Icon(
                        IcoFontIcons.pills,
                        color: Colors.white,
                        size: 50,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // HOME (Floating)
          Positioned(
            bottom: 0,
            child: GestureDetector(
              onTap: () {
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
              child: AnimatedScale(
                scale: isHome ? 1.1 : 1.0,
                duration: const Duration(milliseconds: 200),
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: isHome
                        ? [
                            BoxShadow(
                              color: Colors.white.withOpacity(0.3),
                              blurRadius: 30,
                              spreadRadius: 2,
                            )
                          ]
                        : null,
                  ),
                  child: AnimatedOpacity(
                    opacity: isHome ? 1.0 : 0.6,
                    duration: const Duration(milliseconds: 200),
                    child: Image.asset(
                      'assets/cat_home.png',
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 30),
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
