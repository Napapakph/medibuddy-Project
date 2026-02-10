import 'package:flutter/material.dart';
import 'package:medibuddy/services/auth_session.dart';
import 'package:medibuddy/services/follow_api.dart';
import 'package:medibuddy/widgets/bottomBar.dart';
import 'package:medibuddy/widgets/follow_user_card.dart';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:image_picker/image_picker.dart';
import 'add_follower.dart';
import 'package:medibuddy/services/app_state.dart';

// ===== หน้าจอจัดการผู้ติดตาม =====
class FollowerScreen extends StatefulWidget {
  const FollowerScreen({super.key});

  @override
  State<FollowerScreen> createState() => _FollowerScreenState();
}

// ===== หน้าจอหลักผู้ติดตาม =====
class _FollowerScreenState extends State<FollowerScreen> {
  final _followApi = FollowApi();
  String _imageBaseUrl = '';
  bool _isLoading = false;
  String? _errorMessage;
  List<Map<String, dynamic>> _followers = [];

  Future<void> _goHome() async {
    if (!mounted) return;
    final pid = AppState.instance.currentProfileId;
    Navigator.pushReplacementNamed(
      context,
      '/home',
      arguments: {
        'profileId': pid,
        'profileName': AppState.instance.currentProfileName,
        'profileImage': AppState.instance.currentProfileImagePath,
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _imageBaseUrl = dotenv.env['API_BASE_URL'] ?? '';
    _loadFollowers();
  }

// โหลดรายชื่อผู้ติดตามเมื่อเปิดหน้าจอ
  @override
  void dispose() {
    super.dispose();
  }

// โหลดรายชื่อผู้ติดตามจาก API
  int _readFollowerId(Map<String, dynamic> follower) {
    final raw = follower['relationshipId'];
    return _asInt(raw);
  }

  String _readFollowerName(Map<String, dynamic> follower) {
    final name = (follower['name'] ??
            follower['nickname'] ??
            follower['displayName'] ??
            follower['profileName'] ??
            '')
        .toString()
        .trim();
    return name.isEmpty ? 'ไม่มีชื่อ' : name;
  }

  String _readFollowerEmail(Map<String, dynamic> follower) {
    final email = (follower['viewerEmail'] ?? '').toString().trim();
    return email.contains('@') ? email : '';
  }

  int _asInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }

  String _readFollowerAvatarPath(Map<String, dynamic> follower) {
    return (follower['accountPicture'] ?? '').toString().trim();
  }

  ImageProvider? buildProfileImage(String imagePath) {
    if (imagePath.isEmpty) return null;

    // รูปจาก server (public)
    if (imagePath.startsWith('/uploads')) {
      return NetworkImage('$_imageBaseUrl$imagePath');
    }

    // เผื่อ backend ส่ง URL เต็มมา
    if (imagePath.startsWith('http')) {
      return NetworkImage(imagePath);
    }

    // รูปจากเครื่อง (local)
    return FileImage(File(imagePath));
  }

  List<int> _readFollowerProfileIds(Map<String, dynamic> follower) {
    final candidates = [
      follower['profileIds'],
      follower['profiles'],
      follower['allowedProfiles'],
      follower['viewerProfileIds'],
    ];
    final ids = <int>{};

    for (final candidate in candidates) {
      if (candidate is List) {
        for (final item in candidate) {
          if (item is Map) {
            final raw = item['profileId'] ?? item['id'] ?? item['profile_id'];
            final id = _asInt(raw);
            if (id > 0) ids.add(id);
          } else {
            final id = _asInt(item);
            if (id > 0) ids.add(id);
          }
        }
      }
    }
    return ids.toList();
  }

  bool _isAcceptedFollower(Map<String, dynamic> follower) {
    final status = (follower['status'] ?? '').toString().toUpperCase();
    return status == 'APPROVED';
  }

  Future<void> _openPermissionEdit(Map<String, dynamic> follower) async {
    final followerId = _readFollowerId(follower);
    if (followerId <= 0) return;
    final initialProfiles = _readFollowerProfileIds(follower);
    final initialNickname = _readFollowerName(follower);
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FollowerPermissionScreen(
          user: follower,
          isEdit: true,
          followerId: followerId,
          initialNickname: initialNickname,
          initialProfileIds: initialProfiles,
        ),
      ),
    );
    if (!mounted) return;
    if (result == true) {
      _loadFollowers();
    }
  }

  Future<void> _openEditDialog(Map<String, dynamic> follower) async {
    final followerId = _readFollowerId(follower);
    if (followerId <= 0) return;

    final controller = TextEditingController(
      text: _readFollowerName(follower),
    );
    final picker = ImagePicker();
    XFile? picked;
    bool saving = false;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            ImageProvider? imageProvider;
            if (picked != null) {
              imageProvider = FileImage(File(picked!.path));
            } else {
              final avatarPath = _readFollowerAvatarPath(follower);
              imageProvider = buildProfileImage(avatarPath);
            }

            return AlertDialog(
              title: const Text('แก้ไขผู้ติดตาม'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundImage: imageProvider,
                      child: imageProvider == null
                          ? const Icon(Icons.person, size: 36)
                          : null,
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: saving
                          ? null
                          : () async {
                              final file = await picker.pickImage(
                                source: ImageSource.gallery,
                              );
                              if (file == null) return;
                              setState(() => picked = file);
                            },
                      icon: const Icon(Icons.photo_library),
                      label: const Text('เลือกรูป'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: controller,
                      decoration: const InputDecoration(
                        labelText: 'ชื่อผู้ติดตาม',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: saving ? null : () => Navigator.pop(context),
                  child: const Text('ยกเลิก'),
                ),
                ElevatedButton(
                  onPressed: saving
                      ? null
                      : () async {
                          final nickname = controller.text.trim();
                          if (nickname.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('กรุณากรอกชื่อ')),
                            );
                            return;
                          }
                          final accessToken = AuthSession.accessToken;
                          if (accessToken == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('ไม่พบข้อมูลเข้าสู่ระบบ')),
                            );
                            return;
                          }
                          setState(() => saving = true);
                          try {
                            final profileIds =
                                _readFollowerProfileIds(follower);

                            File? imageFile;
                            if (picked != null) {
                              imageFile = File(picked!.path);
                              debugPrint(
                                  'PICKED IMAGE PATH -> ${picked!.path}');
                              debugPrint(
                                  'FILE EXISTS -> ${imageFile.existsSync()}');
                              debugPrint(
                                  'FILE SIZE -> ${imageFile.lengthSync()} bytes');
                            } else {
                              debugPrint('NO IMAGE PICKED');
                            }

                            await _followApi.updateFollower(
                              accessToken: accessToken,
                              relationshipId: followerId,
                              name: nickname,
                              imageFile: imageFile,
                              profileIds: profileIds,
                            );

                            if (!mounted) return;
                            Navigator.pop(context);
                            _loadFollowers();
                          } catch (e) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('บันทึกไม่สำเร็จ: $e')),
                            );
                          } finally {
                            if (mounted) {
                              setState(() => saving = false);
                            }
                          }
                        },
                  child: const Text('บันทึก'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _loadFollowers() async {
    try {
      setState(() => _isLoading = true);
      final accessToken = AuthSession.accessToken;
      if (accessToken == null) {
        throw Exception('No access token');
      }

      final followers = await _followApi.fetchFollowers(
        accessToken: accessToken,
      );

      setState(() {
        _followers = followers.where(_isAcceptedFollower).toList();
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'เกิดข้อผิดพลาด: $e';
        _isLoading = false;
      });
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.people_outline, size: 64, color: Colors.grey),
          SizedBox(height: 12),
          Text(
            'ยังไม่มีผู้ติดตาม',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 6),
          Text(
            'กดปุ่ม "เพิ่มผู้ติดตาม" เพื่อส่งคำเชิญ',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildFollowerCard(Map<String, dynamic> follower) {
    final name = _readFollowerName(follower);
    final email = _readFollowerEmail(follower);
    final id = _readFollowerId(follower);
    final avatarPath = _readFollowerAvatarPath(follower);
    final avatarImage = buildProfileImage(avatarPath);

    return FollowUserCard(
      name: name,
      email: email,
      avatarUrl: avatarPath,
      avatarImage: avatarImage,
      onDelete: () => _showDeleteConfirmDialog(id, name),
      onEdit: () => _openEditDialog(follower),
      onDetail: () => _openPermissionEdit(follower),
    );
  }

  Future<void> _deleteFollower(int followerId) async {
    try {
      final accessToken = AuthSession.accessToken;
      if (accessToken == null) throw Exception('No access token');

      await _followApi.removeFollower(
        accessToken: accessToken,
        followerId: followerId,
      );

      setState(() {
        _followers.removeWhere((f) => _readFollowerId(f) == followerId);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ลบผู้ติดตามสำเร็จ')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ลบไม่สำเร็จ: $e')),
        );
      }
    }
  }

  void _showDeleteConfirmDialog(int followerId, String followerName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ยืนยันการลบ'),
        content: Text('ลบ $followerName ออกจากผู้ติดตาม?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _deleteFollower(followerId);
            },
            child: const Text('ลบ', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final showFollowers = _followers.isNotEmpty;

    Widget content;
    if (_isLoading) {
      content = const Center(child: CircularProgressIndicator());
    } else if (_errorMessage != null) {
      content = Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_errorMessage!),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadFollowers,
              child: const Text('ลองใหม่'),
            ),
          ],
        ),
      );
    } else if (!showFollowers) {
      content = _buildEmptyState();
    } else {
      content = ListView.builder(
        itemCount: _followers.length,
        itemBuilder: (context, index) {
          return _buildFollowerCard(_followers[index]);
        },
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _goHome();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: _goHome,
          ),
          title: const Text(
            'ผู้ติดตาม',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: const Color(0xFF1F497D),
          elevation: 0,
        ),
        body: content,
        bottomNavigationBar: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SafeArea(
              minimum: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: SizedBox(
                height: 46,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const AddFollowerScreen()),
                    );
                  },
                  icon: const Icon(Icons.person_add),
                  label: const Text('เพิ่มผู้ติดตาม'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1F497D),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                ),
              ),
            ),
            const BottomBar(currentRoute: '/follower'),
          ],
        ),
      ),
    );
  }
}
