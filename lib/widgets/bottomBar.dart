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

    return SafeArea(
      bottom: false,
      top: false,
      child: SizedBox(
        height: 90,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            // Bottom Bar Container
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 80,
                decoration: const BoxDecoration(
                  color: Color.fromARGB(255, 165, 207, 249),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      offset: Offset(0, -4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // FOLLOWING
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pushNamed(context, '/following');
                        },
                        behavior: HitTestBehavior.opaque,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AnimatedScale(
                              scale: isFollowing ? 1.1 : 1.0,
                              duration: const Duration(milliseconds: 200),
                              child: Icon(
                                MdiIcons.heartCircle,
                                color: isFollowing
                                    ? Colors.white
                                    : const Color.fromARGB(118, 255, 255, 255),
                                size: 45,
                                shadows: [
                                  BoxShadow(
                                    color:
                                        const Color.fromARGB(255, 102, 143, 194)
                                            .withOpacity(0.4),
                                    blurRadius: 10,
                                    spreadRadius: 2,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Spacer for Center Floating Button
                    const SizedBox(width: 80),

                    // LIST MEDICINE
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
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
                          debugPrint(
                              '💊 MainBottomBar: open list_medicine pid=$pid');
                        },
                        behavior: HitTestBehavior.opaque,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AnimatedScale(
                              scale: isMedicine ? 1.1 : 1.0,
                              duration: const Duration(milliseconds: 200),
                              child: Icon(
                                IcoFontIcons.pills,
                                color: isMedicine
                                    ? Colors.white
                                    : const Color.fromARGB(118, 255, 255, 255),
                                size: 45,
                                shadows: [
                                  BoxShadow(
                                    color:
                                        const Color.fromARGB(255, 102, 143, 194)
                                            .withOpacity(0.4),
                                    blurRadius: 10,
                                    spreadRadius: 2,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // HOME (Center Floating Button)
            Positioned(
              bottom: 20, // Elevated position
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
                  scale: isHome ? 1.2 : 1.0,
                  duration: const Duration(milliseconds: 200),
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [
                          Color.fromARGB(255, 177, 217, 255),
                          Color.fromARGB(255, 143, 190, 236)
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color.fromARGB(255, 81, 133, 196)
                              .withOpacity(0.4),
                          blurRadius: 10,
                          spreadRadius: 2,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(12),
                    child: AnimatedOpacity(
                      opacity: isHome ? 1.0 : 0.85,
                      duration: const Duration(milliseconds: 200),
                      child: Image.asset(
                        'assets/cat_home.png',
                        fit: BoxFit.contain,
                        color: isHome
                            ? Color.fromARGB(255, 255, 255, 255)
                            : const Color.fromARGB(118, 255, 255, 255),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
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
