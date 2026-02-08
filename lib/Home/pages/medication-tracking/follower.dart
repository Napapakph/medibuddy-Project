import 'package:flutter/material.dart';
import 'package:medibuddy/services/auth_session.dart';
import 'package:medibuddy/services/follow_api.dart';
import 'package:medibuddy/widgets/bottomBar.dart';
import 'package:medibuddy/widgets/follow_user_card.dart';
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

  Future<void> _goHome() async {
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
  }

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
    final raw = follower['relationshipId'];
    return int.tryParse(raw.toString()) ?? 0;
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

  String _readFollowerAvatar(Map<String, dynamic> follower) {
    // JSON ล่าสุดยังไม่มีฟิลด์รูปของ follower
    return '';
  }

  bool _isAcceptedFollower(Map<String, dynamic> follower) {
    final status = (follower['status'] ?? '').toString().toUpperCase();
    return status == 'APPROVED';
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
    final avatarUrl = _readFollowerAvatar(follower);

    return FollowUserCard(
      name: name,
      email: email,
      avatarUrl: avatarUrl,
      onDelete: () => _showDeleteConfirmDialog(id, name),
      onEdit: () {},
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
