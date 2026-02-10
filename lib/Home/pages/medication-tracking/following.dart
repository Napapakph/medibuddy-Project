import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:medibuddy/services/app_state.dart' show AppState;
import 'package:medibuddy/services/follow_api.dart';
import 'package:medibuddy/services/auth_session.dart';
import 'package:medibuddy/widgets/follow_user_card.dart';
import 'following_history.dart';

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
    return (data['name'] ?? 'ไม่มีชื่อ').toString();
  }

  String _readFollowingEmail(Map<String, dynamic> data) {
    final email = (data['ownerEmail'] ?? '').toString().trim();
    return email.contains('@') ? email : '';
  }

  String _readFollowingAvatar(Map<String, dynamic> data) {
    final raw =
        (data['accountPicture'] ?? data['avatar'] ?? data['picture'] ?? '')
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
                        fontSize: 16,
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
                        color: const Color(0xFF101215),
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
                                        ? const Color(0xFF1F497D)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      ClipOval(
                                        child: Container(
                                          width: 46,
                                          height: 46,
                                          color: const Color(0xFF2C3137),
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
                                                      color: Colors.white70,
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
                                          color: Colors.white,
                                          fontSize: 11,
                                        ),
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
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => FollowingHistoryPage(
                                relationshipId: relationshipId,
                                profileId: selectedProfileId,
                                profileName: selectedProfileName,
                                ownerName: ownerName,
                                ownerImage: accountPicture,
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
                        child: const Text('ดูประวัติการทานยา'),
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
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: _goHome,
          ),
          title: const Text(
            'กำลังติดตาม',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: const Color(0xFF1F497D),
          elevation: 0,
          bottom: TabBar(
            controller: _tabController,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white,
            indicatorColor: Colors.white,
            tabs: const [
              Tab(text: 'คำเชิญ'),
              Tab(text: 'กำลังติดตาม'),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
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
                      // ======== TAB 1: ไม่มีคำเชิญ ========
                      _invitations.isEmpty
                          ? const Center(child: Text('ไม่มีคำเชิญ'))
                          : ListView.builder(
                              itemCount: _invitations.length,
                              itemBuilder: (context, index) {
                                final inv = _invitations[index];
                                final name = _readName(inv);
                                final id = _readId(inv);
                                final avatarUrl = _readAvatar(inv);

                                return Card(
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 30,
                                          backgroundImage: avatarUrl.isNotEmpty
                                              ? NetworkImage(avatarUrl)
                                              : null,
                                          child: avatarUrl.isEmpty
                                              ? const Icon(Icons.person)
                                              : null,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            name,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        ElevatedButton(
                                          onPressed: () =>
                                              _handleInvitation(id, true),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                const Color(0xFF1F497D),
                                          ),
                                          child: const Text('ยอมรับ'),
                                        ),
                                        const SizedBox(width: 8),
                                        OutlinedButton(
                                          onPressed: () =>
                                              _handleInvitation(id, false),
                                          child: const Text('ปฏิเสธ'),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),

                      // ======== TAB 2: กำลังติดตาม ========
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
                                  onEdit: () {},
                                  onDetail: () =>
                                      _selectProfileAndOpenDetail(user),
                                );
                              },
                            ),
                    ],
                  ),
      ),
    );
  }
}
