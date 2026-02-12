import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:medibuddy/services/app_state.dart' show AppState;
import 'package:medibuddy/services/follow_api.dart';
import 'package:medibuddy/services/auth_session.dart';
import 'package:medibuddy/widgets/follow_user_card.dart';
import 'package:image_picker/image_picker.dart';
import 'following_history.dart';
import 'package:lottie/lottie.dart';

import 'package:medibuddy/widgets/app_drawer.dart';
import 'package:medibuddy/widgets/bottomBar.dart';

class FollowingScreen extends StatefulWidget {
  const FollowingScreen({super.key});

  @override
  State<FollowingScreen> createState() => _FollowingScreenState();
}

class _FollowingScreenState extends State<FollowingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _followApi = FollowApi();

  List<Map<String, dynamic>> _invitations = [];
  List<Map<String, dynamic>> _following = [];
  bool _isLoading = true;
  String? _errorMessage;

  Future<void> _goHome() async {
    if (!mounted) return;
    final pid = AppState.instance.currentProfileId;
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/home',
      (route) => false,
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
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  int _readId(Map<String, dynamic> data) {
    final raw = data['relationshipId'] ??
        data['inviteId'] ??
        data['id'] ??
        data['followId'] ??
        data['followingId'];
    return int.tryParse(raw.toString()) ?? 0;
  }

  String _readName(Map<String, dynamic> data) {
    return (data['profileName'] ??
            data['name'] ??
            data['displayName'] ??
            data['fullName'] ??
            data['email'] ??
            'ไม่มีชื่อ')
        .toString();
  }

  String _readAvatar(Map<String, dynamic> data) {
    final raw = (data['profilePicture'] ??
            data['profilePictureUrl'] ??
            data['accountPicture'] ??
            data['avatar'] ??
            data['picture'] ??
            '')
        .toString();
    return _resolveImageUrl(raw);
  }

  String _readFollowingName(Map<String, dynamic> data) {
    return (data['ownerNickname'] ?? data['name'] ?? 'ไม่มีชื่อ').toString();
  }

  String _readFollowingEmail(Map<String, dynamic> data) {
    final email = (data['ownerEmail'] ?? '').toString().trim();
    return email.contains('@') ? email : '';
  }

  String _readFollowingAvatar(Map<String, dynamic> data) {
    final raw = (data['ownerPicture'] ??
            data['accountPicture'] ??
            data['avatar'] ??
            data['picture'] ??
            '')
        .toString();
    return _resolveImageUrl(raw);
  }

  int _readProfileId(Map<String, dynamic> profile) {
    final raw = profile['profileId'] ?? profile['id'] ?? profile['profile_id'];
    return int.tryParse(raw.toString()) ?? 0;
  }

  String _readProfileName(Map<String, dynamic> profile) {
    return (profile['profileName'] ?? 'ไม่มีชื่อ').toString();
  }

  String _readProfileAvatar(Map<String, dynamic> profile) {
    final raw = (profile['profilePicture'] ??
            profile['profilePictureUrl'] ??
            profile['accountPicture'] ??
            profile['avatar'] ??
            profile['picture'] ??
            '')
        .toString();
    return _resolveImageUrl(raw);
  }

  String _resolveImageUrl(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return '';

    final uri = Uri.tryParse(value);
    if (uri != null && uri.hasScheme) return value;

    final baseUrl = (dotenv.env['API_BASE_URL'] ?? '').trim();
    if (baseUrl.isEmpty) return value;

    final baseUri = Uri.tryParse(baseUrl);
    if (baseUri == null) return value;

    final normalizedPath = value.startsWith('/') ? value : '/$value';
    return baseUri.resolve(normalizedPath).toString();
  }

  String _initials(String value) {
    final parts = value.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty);
    if (parts.isEmpty) return '?';
    final first = parts.first;
    if (parts.length == 1) {
      return first.characters.take(2).toString().toUpperCase();
    }
    return (first.characters.first + parts.elementAt(1).characters.first)
        .toUpperCase();
  }

  List<Map<String, dynamic>> _normalizeProfiles(dynamic raw) {
    if (raw is List) {
      final items = <Map<String, dynamic>>[];
      for (final item in raw) {
        if (item is Map) {
          final map = Map<String, dynamic>.from(item);
          if (map['profile'] is Map) {
            items.add(Map<String, dynamic>.from(map['profile'] as Map));
          } else {
            items.add(map);
          }
          continue;
        }
        if (item is int) {
          items.add({'id': item});
          continue;
        }
        if (item is String) {
          final id = int.tryParse(item);
          if (id != null) {
            items.add({'id': id});
          }
        }
      }
      return items;
    }
    if (raw is Map) {
      return [Map<String, dynamic>.from(raw)];
    }
    return [];
  }

  List<Map<String, dynamic>> _extractProfilesFromData(
    Map<String, dynamic> data,
  ) {
    if (data['profile'] is Map) {
      return [Map<String, dynamic>.from(data['profile'] as Map)];
    }

    const keys = [
      'sharedProfiles',
      'profiles',
    ];
    for (final key in keys) {
      final value = data[key];
      final list = _normalizeProfiles(value);
      if (list.isNotEmpty) return list;
    }
    return [];
  }

  Future<void> _loadData() async {
    try {
      setState(() => _isLoading = true);

      final accessToken = AuthSession.accessToken;
      if (accessToken == null) {
        throw Exception('No access token');
      }

      final invites = await _followApi.fetchInvites(
        accessToken: accessToken,
      );
      final following = await _followApi.fetchFollowing(
        accessToken: accessToken,
      );

      setState(() {
        _invitations = invites;
        _following = following;
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

  Future<void> _handleInvitation(
    int invitationId,
    bool accept,
  ) async {
    try {
      final accessToken = AuthSession.accessToken;
      if (accessToken == null) {
        throw Exception('No access token');
      }

      if (accept) {
        await _followApi.acceptInvite(
          accessToken: accessToken,
          relationshipId: invitationId,
        );
      } else {
        await _followApi.rejectInvite(
          accessToken: accessToken,
          relationshipId: invitationId,
        );
      }

      await _loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(accept ? 'ยอมรับเสร็จสิ้น' : 'ปฏิเสธเสร็จสิ้น'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ขณะนี้ไม่สามารถทำได้: $e')),
        );
      }
    }
  }

  Future<void> _selectProfileAndOpenDetail(
    Map<String, dynamic> user,
  ) async {
    final accessToken = AuthSession.accessToken;
    if (accessToken == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('กรุณาเข้าสู่ระบบอีกครั้ง')),
        );
      }
      return;
    }

    final relationshipId = _readId(user);
    if (relationshipId == 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ไม่พบรหัสความสัมพันธ์')),
        );
      }
      return;
    }

    List<Map<String, dynamic>> profiles = _extractProfilesFromData(user);
    String ownerName = _readFollowingName(user);
    String accountPicture = '';

    setState(() => _isLoading = true);
    try {
      final detail = await _followApi.fetchFollowingDetail(
        accessToken: accessToken,
        relationshipId: relationshipId,
      );

      // Extract accountPicture from relationship object
      final relationship = detail['relationship'];
      if (relationship is Map) {
        accountPicture =
            (relationship['accountPicture'] ?? '').toString().trim();
        final detailName = (relationship['name'] ?? '').toString().trim();
        if (detailName.isNotEmpty) ownerName = detailName;
      }

      // Extract profiles
      final detailProfiles = _extractProfilesFromData(detail);
      if (detailProfiles.isNotEmpty) {
        profiles = detailProfiles;
      }
    } catch (_) {
      // ignore and fallback to profiles from list
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }

    if (profiles.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ไม่พบโปรไฟล์ที่ได้รับอนุญาต')),
        );
      }
      return;
    }

//แสดงตัวเลือกโปรไฟล์
    if (!mounted) return;
    var selectedIndex = 0;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'เลือกโปรไฟล์ที่ต้องการดู',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 219, 231, 252),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: List.generate(profiles.length, (index) {
                            final profile = profiles[index];
                            final name = _readProfileName(profile);
                            final profileId = _readProfileId(profile);
                            final avatarUrl = _readProfileAvatar(profile);
                            final displayName =
                                name.isNotEmpty ? name : 'โปรไฟล์ $profileId';
                            final isSelected = selectedIndex == index;
                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 6),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () =>
                                    setModalState(() => selectedIndex = index),
                                child: Container(
                                  width: 84,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                    horizontal: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? const Color.fromARGB(
                                            84, 154, 200, 255)
                                        : const Color.fromARGB(
                                            0, 231, 244, 255),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      ClipOval(
                                        child: Container(
                                          width: 46,
                                          height: 46,
                                          color: const Color.fromARGB(
                                              255, 134, 164, 202),
                                          child: avatarUrl.isNotEmpty
                                              ? Image.network(
                                                  avatarUrl,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (_, __, ___) =>
                                                      const Icon(
                                                    Icons.person,
                                                    color: Colors.white70,
                                                  ),
                                                )
                                              : Center(
                                                  child: Text(
                                                    _initials(displayName),
                                                    style: const TextStyle(
                                                      color: Color.fromARGB(
                                                          179, 255, 255, 255),
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                                  ),
                                                ),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        displayName,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                            color: Color.fromARGB(
                                                255, 41, 55, 124),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          // Navigate to Following History page
                          final selected = profiles[selectedIndex];
                          final selectedProfileId = _readProfileId(selected);
                          final selectedProfileName =
                              _readProfileName(selected);

                          String finalImage = _readProfileAvatar(selected);
                          if (finalImage.isEmpty) {
                            finalImage = accountPicture;
                          }

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => FollowingHistoryPage(
                                relationshipId: relationshipId,
                                profileId: selectedProfileId,
                                profileName: selectedProfileName,
                                ownerName: ownerName,
                                ownerImage: finalImage,
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1F497D),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'ดูประวัติการทานยา',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _openEditDialog(Map<String, dynamic> user) async {
    final relationshipId = _readId(user);
    if (relationshipId == 0) return;

    final initialName = _readFollowingName(user);
    final controller = TextEditingController(text: initialName);
    final picker = ImagePicker();
    XFile? picked;
    bool saving = false;
    String? nameError;

    // Validate initial name
    if (initialName.length > 100) {
      nameError = 'ชื่อเล่นห้ามเกิน 100 ตัวอักษร';
    }

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            ImageProvider? imageProvider;
            if (picked != null) {
              imageProvider = FileImage(File(picked!.path));
            } else {
              final avatarPath = _readFollowingAvatar(user);
              if (avatarPath.isNotEmpty) {
                imageProvider = NetworkImage(avatarPath);
              }
            }

            return AlertDialog(
              title: const Text('แก้ไขคนที่กำลังติดตาม'),
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

                              // Check file size (5MB limit)
                              final len = await file.length();
                              if (len > 5 * 1024 * 1024) {
                                if (!mounted) return;
                                showDialog(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('แจ้งเตือน'),
                                    content:
                                        const Text('ขนาดรูปภาพต้องไม่เกิน 5MB'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(ctx),
                                        child: const Text('ตกลง'),
                                      ),
                                    ],
                                  ),
                                );
                                return;
                              }

                              setState(() => picked = file);
                            },
                      icon: const Icon(Icons.photo_library),
                      label: const Text('เลือกรูป'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: controller,
                      onChanged: (val) {
                        setState(() {
                          if (val.length > 100) {
                            nameError = 'ชื่อเล่นห้ามเกิน 100 ตัวอักษร';
                          } else {
                            nameError = null;
                          }
                        });
                      },
                      decoration: InputDecoration(
                        labelText: 'ชื่อเล่น (Nickname)',
                        border: const OutlineInputBorder(),
                        errorText: nameError,
                        errorStyle: const TextStyle(color: Colors.red),
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
                  onPressed: (saving || nameError != null)
                      ? null
                      : () async {
                          final nickname = controller.text.trim();
                          final accessToken = AuthSession.accessToken;
                          if (accessToken == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('ไม่พบข้อมูลเข้าสู่ระบบ')),
                            );
                            return;
                          }

                          if (nickname.length > 100) {
                            setState(() =>
                                nameError = 'ชื่อเล่นห้ามเกิน 100 ตัวอักษร');
                            return;
                          }

                          setState(() => saving = true);
                          try {
                            File? imageFile;
                            if (picked != null) {
                              imageFile = File(picked!.path);
                            }

                            await _followApi.updateFollowing(
                              accessToken: accessToken,
                              relationshipId: relationshipId,
                              ownerNickname: nickname,
                              ownerPicture: imageFile,
                            );

                            if (!mounted) return;
                            Navigator.pop(context);
                            _loadData();
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
                  child: saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('บันทึก'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmRemoveFollowing(Map<String, dynamic> user) {
    final name = _readName(user);
    final relationshipId = _readId(user);
    if (relationshipId == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ไม่พบรหัสความสัมพันธ์')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ยืนยันการลบ'),
        content: Text('เลิกติดตาม $name ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _removeFollowing(relationshipId);
            },
            child: const Text('ลบ', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _removeFollowing(int relationshipId) async {
    try {
      final accessToken = AuthSession.accessToken;
      if (accessToken == null) throw Exception('No access token');

      await _followApi.removeFollowing(
        accessToken: accessToken,
        relationshipId: relationshipId,
      );

      setState(() {
        _following.removeWhere((item) => _readId(item) == relationshipId);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ลบการติดตามสำเร็จ')),
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

  @override
  Widget build(BuildContext context) {
    final pid = AppState.instance.currentProfileId;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _goHome();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        drawer: const AppDrawer(),
        bottomNavigationBar: const BottomBar(currentRoute: '/following'),
        appBar: AppBar(
          title: const Text(
            'กำลังติดตาม',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: const Color(0xFF1F497D),
          elevation: 0,
          foregroundColor: Colors.white, // To make drawer icon white
          bottom: TabBar(
            controller: _tabController,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            labelStyle: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.normal,
            ),
            tabs: const [
              Tab(text: 'กำลังติดตาม'),
              Tab(text: 'คำเชิญ'),
            ],
          ),
        ),
        body: Stack(
          children: [
            _errorMessage != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(_errorMessage!),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadData,
                          child: const Text('ลองใหม่'),
                        ),
                      ],
                    ),
                  )
                : TabBarView(
                    controller: _tabController,
                    children: [
                      // ======== TAB 1: กำลังติดตาม ========
                      _following.isEmpty
                          ? const Center(child: Text('ยังไม่ติดตามใคร'))
                          : ListView.builder(
                              itemCount: _following.length,
                              itemBuilder: (context, index) {
                                final user = _following[index];
                                final name = _readFollowingName(user);
                                final avatarUrl = _readFollowingAvatar(user);
                                final email = _readFollowingEmail(user);
                                final avatarImage = avatarUrl.isNotEmpty
                                    ? NetworkImage(avatarUrl) as ImageProvider
                                    : null;

                                return FollowUserCard(
                                  name: name,
                                  email: email,
                                  avatarUrl: avatarUrl,
                                  avatarImage: avatarImage,
                                  onDelete: () => _confirmRemoveFollowing(user),
                                  onEdit: () => _openEditDialog(user),
                                  onDetail: () =>
                                      _selectProfileAndOpenDetail(user),
                                );
                              },
                            ),

                      // ======== TAB 2: คำเชิญ ========
                      _invitations.isEmpty
                          ? const Center(child: Text('ไม่มีคำเชิญ'))
                          : ListView.builder(
                              itemCount: _invitations.length,
                              itemBuilder: (context, index) {
                                String _readEmail(Map<String, dynamic> data) {
                                  final raw = data['email'] ??
                                      data['ownerEmail'] ??
                                      data['inviterEmail'] ??
                                      data['senderEmail'] ??
                                      '';
                                  final val = raw.toString().trim();
                                  return val.contains('@') ? val : '';
                                }

                                final inv = _invitations[index];
                                final name = _readName(inv);
                                final id = _readId(inv);
                                final avatarUrl = _readAvatar(inv);
                                final email = _readEmail(inv);

                                return Card(
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 5, vertical: 5),
                                  child: Padding(
                                    padding: const EdgeInsets.all(5),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // ส่วนบน: Avatar + Email
                                        Row(
                                          children: [
                                            CircleAvatar(
                                              radius: 30,
                                              backgroundImage:
                                                  avatarUrl.isNotEmpty
                                                      ? NetworkImage(avatarUrl)
                                                      : null,
                                              child: avatarUrl.isEmpty
                                                  ? const Icon(Icons.person,
                                                      size: 20)
                                                  : null,
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                email.isNotEmpty ? email : name,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                  color: Colors.black,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),

                                        // ส่วนล่าง: ปุ่ม (Reject ซ้าย, Accept ขวา) ชิดขวา
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.end,
                                          children: [
                                            OutlinedButton(
                                              onPressed: () =>
                                                  _handleInvitation(id, false),
                                              style: OutlinedButton.styleFrom(
                                                foregroundColor: Colors.red,
                                                side: const BorderSide(
                                                    color: Colors.red),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 16),
                                              ),
                                              child: const Text('ปฏิเสธ'),
                                            ),
                                            const SizedBox(width: 12),
                                            ElevatedButton(
                                              onPressed: () =>
                                                  _handleInvitation(id, true),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    const Color(0xFF1F497D),
                                                foregroundColor: Colors.white,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 16),
                                              ),
                                              child: const Text('ยอมรับ'),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ],
                  ),
            if (_isLoading)
              Positioned.fill(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const ModalBarrier(
                      dismissible: false,
                      color: Colors.black26,
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Lottie.asset(
                          'assets/lottie/loader_cat.json',
                          width: 180,
                          height: 180,
                          repeat: true,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'กำลังโหลด…',
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
