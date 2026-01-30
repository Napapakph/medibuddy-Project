import 'package:flutter/material.dart';
import 'package:medibuddy/services/auth_session.dart';
import 'package:medibuddy/services/profile_api.dart';
import 'add_follower.dart';

class FollowerScreen extends StatefulWidget {
  const FollowerScreen({super.key});

  @override
  State<FollowerScreen> createState() => _FollowerScreenState();
}

class _FollowerScreenState extends State<FollowerScreen> {
  final _profileApi = ProfileApi();
  final TextEditingController _inviteNameController = TextEditingController();
  final TextEditingController _inviteEmailController = TextEditingController();
  final List<Map<String, dynamic>> _followers = [];
  final List<Map<String, dynamic>> _pendingInvites = [];
  bool _isLoading = false;
  bool _canShowFollowers = false;
  String? _errorMessage;
  int _tempInviteId = 1;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _inviteNameController.dispose();
    _inviteEmailController.dispose();
    super.dispose();
  }

  Future<void> _loadFollowers() async {
    try {
      setState(() => _isLoading = true);
      final accessToken = AuthSession.accessToken;
      if (accessToken == null) {
        throw Exception('No access token');
      }

      // TODO: ต้องเรียก API ที่ดึงรายชื่อผู้ติดตาม
      // ปัจจุบัน API อาจยังไม่มี ต้องคุยกับ Backend
      // ชั่วคราวใช้ fetchProfiles แทน (ในอนาคตให้เปลี่ยนเป็น API followers ที่ถูกต้อง)

      final profiles = await _profileApi.fetchProfiles(
        accessToken: accessToken,
      );

      setState(() {
        _followers
          ..clear()
          ..addAll(profiles);
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

  void _openInviteDialog() {
    _inviteNameController.clear();
    _inviteEmailController.clear();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ส่งคำเชิญผู้ติดตาม'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _inviteNameController,
              decoration: const InputDecoration(
                labelText: 'ชื่อผู้ติดตาม',
              ),
            ),
            TextField(
              controller: _inviteEmailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'อีเมล (ไม่จำเป็น)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () => _submitInvite(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1F497D),
            ),
            child: const Text('ส่งคำเชิญ'),
          ),
        ],
      ),
    );
  }

  void _submitInvite(BuildContext dialogContext) {
    final name = _inviteNameController.text.trim();
    final email = _inviteEmailController.text.trim();

    if (name.isEmpty && email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากรอกชื่อหรืออีเมลก่อนส่งคำเชิญ')),
      );
      return;
    }

    final invite = {
      'id': _tempInviteId++,
      'profileName': name.isEmpty ? 'ผู้ติดตามใหม่' : name,
      'email': email,
      'profilePicture': null,
    };

    setState(() {
      _pendingInvites.add(invite);
      _errorMessage = null;
    });

    Navigator.pop(dialogContext);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('ส่งคำเชิญติดตามแล้ว')),
    );
  }

  void _showConfirmFollowDialog(Map<String, dynamic> invite) {
    final name = invite['profileName'] ?? 'ผู้ติดตาม';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ยืนยันการติดตาม'),
        content: Text('ยืนยันให้ $name ติดตามใช่หรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ไม่'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _acceptInvite(invite);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1F497D),
            ),
            child: const Text('ใช่'),
          ),
        ],
      ),
    );
  }

  void _acceptInvite(Map<String, dynamic> invite) {
    setState(() {
      _pendingInvites.removeWhere((i) => i['id'] == invite['id']);
      _followers.add(invite);
      _canShowFollowers = true;
    });
  }

  void _cancelInvite(Map<String, dynamic> invite) {
    setState(() {
      _pendingInvites.removeWhere((i) => i['id'] == invite['id']);
    });
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

  Widget _buildInviteCard(Map<String, dynamic> invite) {
    final name = invite['profileName'] ?? 'ผู้ติดตาม';
    final email = invite['email'] ?? '';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundImage: invite['profilePicture'] != null &&
                          (invite['profilePicture'] as String).isNotEmpty
                      ? NetworkImage(invite['profilePicture'])
                      : null,
                  child: invite['profilePicture'] == null
                      ? const Icon(Icons.person)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
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
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () => _cancelInvite(invite),
                  child: const Text('ยกเลิก'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _showConfirmFollowDialog(invite),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1F497D),
                  ),
                  child: const Text('ยืนยัน'),
                ),
              ],
            ),
          ],
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
    final name = follower['profileName'] ?? 'ไม่มีชื่อ';
    final email = follower['email'] ?? '';
    final id = follower['id'] ?? 0;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundImage: follower['profilePicture'] != null &&
                      (follower['profilePicture'] as String).isNotEmpty
                  ? NetworkImage(follower['profilePicture'])
                  : null,
              child: follower['profilePicture'] == null
                  ? const Icon(Icons.person)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
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
              onPressed: () => _showEditPermissionDialog(follower),
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

      // TODO: เรียก API ลบผู้ติดตาม
      // ปัจจุบัน Backend ยังไม่มี API ลบ ต้องเพิ่มหรือใช้ PUT/PATCH

      // ตัวอย่างเบื้องต้น - ใช้ deleteProfile
      // await _profileApi.deleteProfile(
      //   accessToken: accessToken,
      //   profileId: followerId,
      // );

      setState(() {
        _followers.removeWhere((f) => f['id'] == followerId);
        if (_followers.isEmpty) {
          _canShowFollowers = false;
        }
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

  void _showEditPermissionDialog(Map<String, dynamic> follower) {
    showDialog(
      context: context,
      builder: (ctx) => _EditPermissionDialog(
        follower: follower,
        onSave: () {
          Navigator.pop(ctx);
          _loadFollowers(); // โหลดข้อมูลใหม่
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasPendingInvites = _pendingInvites.isNotEmpty;
    final showFollowers = _canShowFollowers && _followers.isNotEmpty;
    final listChildren = <Widget>[];

    if (hasPendingInvites) {
      listChildren.add(_sectionTitle('คำเชิญที่ส่ง'));
      listChildren.addAll(_pendingInvites.map(_buildInviteCard));
      if (!showFollowers) {
        listChildren.add(
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'รอการยืนยันคำเชิญก่อนจะแสดงรายชื่อผู้ติดตาม',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        );
      }
    }

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
    } else if (!hasPendingInvites && !showFollowers) {
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

// ===== DIALOG แก้ไขสิทธิ์ =====
class _EditPermissionDialog extends StatefulWidget {
  final Map<String, dynamic> follower;
  final VoidCallback onSave;

  const _EditPermissionDialog({
    required this.follower,
    required this.onSave,
  });

  @override
  State<_EditPermissionDialog> createState() => _EditPermissionDialogState();
}

class _EditPermissionDialogState extends State<_EditPermissionDialog> {
  final _profileApi = ProfileApi();
  List<Map<String, dynamic>> _myProfiles = [];
  List<int> _selectedProfileIds = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMyProfiles();
  }

  Future<void> _loadMyProfiles() async {
    try {
      final accessToken = AuthSession.accessToken;
      if (accessToken == null) throw Exception('No access token');

      // เรียก API ดึงโปรไฟล์ของเรา
      final profiles = await _profileApi.fetchProfiles(
        accessToken: accessToken,
      );

      setState(() {
        _myProfiles = profiles;
        // ชั่วคราวเลือกโปรไฟล์แรก
        _selectedProfileIds =
            _myProfiles.isNotEmpty ? [_myProfiles[0]['id'] ?? 0] : [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('โหลดโปรไฟล์ไม่สำเร็จ: $e')),
        );
      }
    }
  }

  Future<void> _savePermissions() async {
    try {
      final accessToken = AuthSession.accessToken;
      if (accessToken == null) throw Exception('No access token');

      // TODO: เรียก API PATCH /api/mobile/v1/profile/update
      // เพื่อบันทึกสิทธิ์การเข้าถึง
      // ปัจจุบัน updateProfile ไม่รองรับการส่งสิทธิ์ ต้องปรับแต่ง Backend หรือสร้าง endpoint ใหม่

      // ตัวอย่างการใช้ (รอ Backend ปรับปรุง):
      // await _profileApi.updateProfile(
      //   accessToken: accessToken,
      //   profileId: widget.follower['id'],
      //   allowedProfiles: _selectedProfileIds,
      // );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('บันทึกสิทธิ์สำเร็จ')),
        );
        widget.onSave();
      }
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
    final followerName = widget.follower['profileName'] ?? 'ไม่มีชื่อ';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              'แก้ไขสิทธิ์: $followerName',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // รายการโปรไฟล์
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_myProfiles.isEmpty)
              const Text('ไม่มีโปรไฟล์')
            else
              Column(
                children: [
                  const Text(
                    'อนุญาตให้ผู้ติดตามดูโปรไฟล์ต่อไปนี้:',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  ..._myProfiles.map((profile) {
                    final profileId = profile['id'] ?? 0;
                    final profileName = profile['profileName'] ?? 'ไม่มีชื่อ';

                    return CheckboxListTile(
                      title: Text(profileName),
                      value: _selectedProfileIds.contains(profileId),
                      onChanged: (isChecked) {
                        setState(() {
                          if (isChecked ?? false) {
                            _selectedProfileIds.add(profileId);
                          } else {
                            _selectedProfileIds.remove(profileId);
                          }
                        });
                      },
                    );
                  }).toList(),
                ],
              ),

            const SizedBox(height: 24),

            // ปุ่ม
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('ยกเลิก'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _savePermissions,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1F497D),
                  ),
                  child: const Text('ยืนยัน'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
