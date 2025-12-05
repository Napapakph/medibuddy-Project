import 'package:flutter/material.dart';
import 'package:medibuddy/Model/profile_model.dart';
import 'profile_screen.dart';

List<ProfileModel> profiles = [];

class LibraryProfile extends StatefulWidget {
  const LibraryProfile({Key? key, this.initialProfile}) : super(key: key);

  final ProfileModel? initialProfile;

  @override
  State<LibraryProfile> createState() => _LibraryProfileState();
}

class _LibraryProfileState extends State<LibraryProfile> {
  final List<ProfileModel> profiles = [];

  @override
  void initState() {
    super.initState();
    if (widget.initialProfile != null) {
      profiles.add(widget.initialProfile!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          iconTheme: const IconThemeData(color: Colors.white),
          title: const Text(
            'ห้องสมุดโปรไฟล์',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: const Color(0xFF1F497D),
        ),
        backgroundColor: const Color.fromARGB(255, 235, 246, 255),
        body: SafeArea(
          child: LayoutBuilder(builder: (context, constraints) {
            final maxWidth = constraints.maxWidth;
            final maxHeight = constraints.maxHeight;

            //ถ้าจอกว้างแบบแท็บเล็ต
            final bool isTablet = maxWidth > 600;

            //จำกัดความกว้างสูงสุดของหน้าจอ
            final double containerWidth = isTablet ? 500 : maxWidth;

            return ListView.builder(
              itemCount: profiles.length,
              itemBuilder: (context, index) {
                final profile = profiles[index];
                return ListTile(
                  leading: profile.profileImageUrl.isNotEmpty
                      ? CircleAvatar(
                          backgroundImage:
                              NetworkImage(profile.profileImageUrl),
                        )
                      : const CircleAvatar(
                          child: Icon(Icons.person),
                        ),
                  title: Text(profile.username),
                );
              },
            );
          }),
        ));
  }
}
