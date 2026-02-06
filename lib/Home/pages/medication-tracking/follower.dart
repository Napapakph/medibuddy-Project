import 'package:flutter/material.dart';
import 'package:medibuddy/services/auth_session.dart';
import 'package:medibuddy/services/follow_api.dart';
import 'add_follower.dart';

// ===== หน้าจอจัดการผู้ติดตาม =====
class FollowerScreen extends StatefulWidget {
  const FollowerScreen({super.key});

  @override
  State<FollowerScreen> createState() => _FollowerScreenState();
}

// ===== หน้าจอหลักผู้ติดตาม =====
class _FollowerScreenState extends State<FollowerScreen> {
  final _followApi = FollowApi();
  bool _isLoading = false;
  String? _errorMessage;
  List<Map<String, dynamic>> _followers = [];

  @override
  void initState() {
    super.initState();
    _loadFollowers();
  }
// โหลดรายชื่อผู้ติดตามเมื่อเปิดหน้าจอ
  @override
  void dispose() {
    super.dispose();
  }
// โหลดรายชื่อผู้ติดตามจาก API
  int _readFollowerId(Map<String, dynamic> follower) {
    final raw = follower['followerId'] ??
        follower['id'] ??
        follower['followId'] ??
        follower['profileId'] ??
        follower['userId'];
    return int.tryParse(raw.toString()) ?? 0;
  }

  String _readFollowerName(Map<String, dynamic> follower) {
    final rawName = (follower['nickname'] ??
            follower['profileName'] ??
            follower['name'] ??
            follower['displayName'] ??
            '')
        .toString();
    if (rawName.trim().isNotEmpty) return rawName;
    final email = (follower['email'] ?? follower['mail'] ?? '').toString();
    if (email.isNotEmpty) return email;
    return 'ไม่มีชื่อ';
  }

  List<int> _readFollowerProfileIds(Map<String, dynamic> follower) {
    final raw = follower['profileIds'] ??
        follower['allowedProfileIds'] ??
        follower['profiles'] ??
        follower['allowedProfiles'];
    if (raw is! List) return const [];
    final ids = <int>{};
    for (final item in raw) {
      if (item is int) {
        if (item > 0) ids.add(item);
        continue;
      }
      if (item is String) {
        final id = int.tryParse(item);
        if (id != null && id > 0) ids.add(id);
        continue;
      }
      if (item is Map) {
        final rawId = item['profileId'] ?? item['id'] ?? item['profile_id'];
        final id = int.tryParse(rawId.toString()) ?? 0;
        if (id > 0) ids.add(id);
      }
    }
    return ids.toList(growable: false);
  }

  bool _isAcceptedFollower(Map<String, dynamic> follower) {
    final status =
        (follower['status'] ?? follower['state'] ?? follower['inviteStatus'])
            ?.toString()
            .toLowerCase();
    if (status != null && status.isNotEmpty) {
      if (status.contains('pending') || status.contains('wait')) return false;
      if (status.contains('accept') ||
          status.contains('active') ||
          status.contains('approve') ||
          status.contains('confirmed')) {
        return true;
      }
    }
    final accepted =
        follower['isAccepted'] ?? follower['accepted'] ?? follower['approved'];
    if (accepted is bool) return accepted;
    if (follower['acceptedAt'] != null || follower['accepted_at'] != null) {
      return true;
    }
    return true;
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

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
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
            'กดปุ่มส่งคำเชิญเพื่อเริ่มต้น',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildFollowerCard(Map<String, dynamic> follower) {
    final name = _readFollowerName(follower);
    final email = follower['email'] ?? follower['mail'] ?? '';
    final id = _readFollowerId(follower);
    final avatarUrl = (follower['profilePicture'] ??
        follower['profilePictureUrl'] ??
        follower['avatar'] ??
        '') as String;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundImage:
                  avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
              child: avatarUrl.isEmpty ? const Icon(Icons.person) : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ชื่อ : $name',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  if (email.isNotEmpty)
                    Text(
                      email,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit, color: Color(0xFF1F497D)),
              onPressed: () => _showEditNicknameDialog(follower),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _showDeleteConfirmDialog(id, name),
            ),
          ],
        ),
      ),
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

  void _showEditNicknameDialog(Map<String, dynamic> follower) {
    final controller = TextEditingController(text: _readFollowerName(follower));
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('แก้ไขชื่อเล่น'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'ชื่อเล่น',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _saveNickname(follower, controller.text);
              if (mounted) {
                Navigator.pop(ctx);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1F497D),
            ),
            child: const Text('บันทึก'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveNickname(
    Map<String, dynamic> follower,
    String nickname,
  ) async {
    final trimmed = nickname.trim();
    if (trimmed.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('กรุณากรอกชื่อเล่น')),
        );
      }
      return;
    }

    final followerId = _readFollowerId(follower);
    if (followerId == 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ไม่พบรหัสผู้ติดตาม')),
        );
      }
      return;
    }

    try {
      final accessToken = AuthSession.accessToken;
      if (accessToken == null) throw Exception('No access token');

      final profileIds = _readFollowerProfileIds(follower);
      await _followApi.updateFollowerNickname(
        accessToken: accessToken,
        followerId: followerId,
        nickname: trimmed,
        profileIds: profileIds,
      );

      if (!mounted) return;
      setState(() {
        final index =
            _followers.indexWhere((f) => _readFollowerId(f) == followerId);
        if (index >= 0) {
          final updated = Map<String, dynamic>.from(_followers[index]);
          updated['nickname'] = trimmed;
          updated['profileName'] = trimmed;
          updated['displayName'] = trimmed;
          updated['name'] = trimmed;
          _followers[index] = updated;
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('บันทึกชื่อเล่นสำเร็จ')),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('บันทึกไม่สำเร็จ: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final showFollowers = _followers.isNotEmpty;
    final listChildren = <Widget>[];

    if (showFollowers) {
      listChildren.add(_sectionTitle('ผู้ติดตาม'));
      listChildren.addAll(_followers.map(_buildFollowerCard));
    }

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
      content = ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: listChildren,
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('ผู้ติดตาม'),
        backgroundColor: const Color(0xFF1F497D),
        elevation: 0,
      ),
      body: content,
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: SizedBox(
          height: 46,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddFollowerScreen()),
              );
            },
            icon: const Icon(Icons.person_add),
            label: const Text('ส่งคำเชิญผู้ติดตาม +'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1F497D),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
        ),
      ),
    );
  }
}












