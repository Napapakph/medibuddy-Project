import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:medibuddy/services/auth_session.dart';
import 'package:medibuddy/services/follow_api.dart';
import 'package:medibuddy/services/profile_api.dart';

const Color _primaryBlue = Color(0xFF1F497D);
const Color _softSurface = Color(0xFFF1F4F7);
const Color _softPill = Color(0xFFDCE2E8);
const Color _accentBlue = Color(0xFF8FB6E5);

String _resolveImageUrl(String? raw) {
  final value = (raw ?? '').trim();
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

String _readAvatarUrl(Map<String, dynamic> data) {
  final raw = (data['profilePicture'] ??
          data['profilePictureUrl'] ??
          data['accountPicture'] ??
          data['avatar'] ??
          data['picture'] ??
          data['imageUrl'])
      ?.toString();
  return _resolveImageUrl(raw);
}

class AddFollowerScreen extends StatefulWidget {
  const AddFollowerScreen({super.key});

  @override
  State<AddFollowerScreen> createState() => _AddFollowerScreenState();
}

class _AddFollowerScreenState extends State<AddFollowerScreen> {
  final _searchController = TextEditingController();
  final _followApi = FollowApi();
  final Set<String> _sentInviteEmails = {};

  List<Map<String, dynamic>> _foundUsers = [];
  bool _isSearching = false;
  String? _searchError;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchUser() async {
    final email = _searchController.text.trim();
    FocusScope.of(context).unfocus();
    if (email.isEmpty) {
      setState(() => _searchError = 'กรุณากรอกอีเมล');
      return;
    }
    if (email.length < 3) {
      setState(() {
        _searchError = 'กรุณาพิมพ์อย่างน้อย 3 ตัวอักษร';
        _foundUsers = [];
      });
      return;
    }

    try {
      setState(() {
        _isSearching = true;
        _searchError = null;
        _foundUsers = [];
      });
// ค้นหาผู้ใช้ตามอีเมล
      final accessToken = AuthSession.accessToken;
      if (accessToken == null) {
        throw Exception('No access token');
      }
// ค้นหาผู้ใช้
      final results = await _followApi.searchUsers(
        accessToken: accessToken,
        email: email,
      );
      setState(() {
        _foundUsers = results;
        if (_foundUsers.isEmpty) {
          _searchError = 'ไม่พบผู้ใช้ที่ค้นหา';
        }
      });
    } catch (e) {
      setState(() => _searchError = 'เกิดข้อผิดพลาด: $e');
    } finally {
      if (mounted) {
        setState(() => _isSearching = false);
      }
    }
  }

  Future<void> _openPermissionScreen(Map<String, dynamic> user) async {
    final invited = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FollowerPermissionScreen(user: user),
      ),
    );
    if (!mounted) return;
    if (invited == true) {
      final invitedEmail = (user['email'] ?? '').toString().toLowerCase();
      if (invitedEmail.isNotEmpty) {
        setState(() => _sentInviteEmails.add(invitedEmail));
      }
    }
  }

  Widget _buildHero() {
    return SizedBox(
      height: 210,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Positioned(
            top: 0,
            child: _SpeechBubble(
              text: 'กรอกอีเมลของผู้ที่ต้องการให้เราติดตามได้ที่นี่',
            ),
          ),
          Positioned(
            bottom: 0,
            child: Image.asset(
              'assets/cat_add_follower.png',
              height: 120,
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 46,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: _softSurface,
              borderRadius: BorderRadius.circular(28),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x14000000),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _searchUser(),
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: 'projectcpe01@gmail.com',
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Material(
          color: _primaryBlue,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: _isSearching ? null : _searchUser,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: _isSearching
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.search, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFoundAccount(Map<String, dynamic> user) {
    final email = (user['email'] ?? user['mail'] ?? '').toString();
    final rawName =
        (user['profileName'] ?? user['name'] ?? user['displayName'] ?? '')
            .toString();
    final name = rawName.trim().isNotEmpty
        ? rawName
        : (email.isNotEmpty ? email : 'ไม่ระบุชื่อ');
    final avatarUrl = _readAvatarUrl(user);
    final normalizedEmail = email.toString().toLowerCase();
    final isInvited = (user['isInvited'] == true) ||
        _sentInviteEmails.contains(normalizedEmail);

    return InkWell(
      onTap: () => _openPermissionScreen(user),
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: _softSurface,
          borderRadius: BorderRadius.circular(22),
          boxShadow: const [
            BoxShadow(
              color: Color(0x12000000),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
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
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  if (email.isNotEmpty)
                    Text(
                      email,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                  if (isInvited)
                    const Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Text(
                        'ส่งคำเชิญแล้ว',
                        style: TextStyle(
                          fontSize: 11,
                          color: _primaryBlue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: _primaryBlue,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('เพิ่มผู้ติดตาม'),
        backgroundColor: _primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHero(),
              _buildSearchBar(),
              if (_searchError != null) ...[
                const SizedBox(height: 12),
                Text(
                  _searchError!,
                  style: const TextStyle(
                    color: Colors.redAccent,
                    fontSize: 12,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              const Text(
                'บัญชีที่พบ',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 10),
              if (_foundUsers.isNotEmpty)
                Column(
                  children: _foundUsers
                      .map(
                        (user) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildFoundAccount(user),
                        ),
                      )
                      .toList(growable: false),
                ),
              if (_foundUsers.isEmpty && _searchError == null)
                const Text(
                  'ยังไม่มีผลการค้นหา',
                  style: TextStyle(color: Colors.black38),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class FollowerPermissionScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  final bool isEdit;
  final int? followerId;
  final String? initialNickname;
  final List<int> initialProfileIds;

  const FollowerPermissionScreen({
    super.key,
    required this.user,
    this.isEdit = false,
    this.followerId,
    this.initialNickname,
    this.initialProfileIds = const [],
  });

  @override
  State<FollowerPermissionScreen> createState() =>
      _FollowerPermissionScreenState();
}

// หน้าจอการอนุญาตผู้ติดตาม
class _FollowerPermissionScreenState extends State<FollowerPermissionScreen> {
  final _profileApi = ProfileApi();
  final _followApi = FollowApi();

  List<Map<String, dynamic>> _myProfiles = [];
  final Set<int> _selectedProfileIds = {};
  bool _isLoading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadMyProfiles();
  }

  int _asProfileId(dynamic raw) {
    if (raw is int) return raw;
    return int.tryParse(raw.toString()) ?? 0;
  }

  int _readProfileId(Map<String, dynamic> profile) {
    final raw = profile['profileId'] ?? profile['id'] ?? profile['profile_id'];
    return _asProfileId(raw);
  }

// โหลดโปรไฟล์ของผู้ใช้ปัจจุบัน
  Future<void> _loadMyProfiles() async {
    final accessToken = AuthSession.accessToken;
    if (accessToken == null) {
      setState(() {
        _myProfiles = [];
        _selectedProfileIds.clear();
        _isLoading = false;
        _loadError = 'ไม่พบข้อมูลเข้าสู่ระบบ กรุณาเข้าสู่ระบบอีกครั้ง';
      });
      return;
    }
// Load profiles
    try {
      final profiles = await _profileApi.fetchProfiles(
        accessToken: accessToken,
      );
      _myProfiles = profiles;
      _selectedProfileIds.clear();
      if (widget.isEdit) {
        for (final id in widget.initialProfileIds) {
          if (id > 0) {
            _selectedProfileIds.add(id);
          }
        }
      } else if (_myProfiles.isNotEmpty) {
        for (final profile in _myProfiles) {
          final id = _readProfileId(profile);
          if (id > 0) {
            _selectedProfileIds.add(id);
          }
        }
      }
      _loadError = null;
    } catch (e) {
      _myProfiles = [];
      _selectedProfileIds.clear();
      _loadError = 'โหลดโปรไฟล์ไม่สำเร็จ: $e';
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _toggleProfile(int id, bool selected) {
    if (id <= 0) return;
    setState(() {
      if (selected) {
        _selectedProfileIds.add(id);
      } else {
        _selectedProfileIds.remove(id);
      }
    });
  }

  Future<void> _confirmInvite() async {
    final profileIds =
        _selectedProfileIds.where((id) => id > 0).toList(growable: false);
    if (profileIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเลือกอย่างน้อย 1 โปรไฟล์')),
      );
      return;
    }

    try {
      final accessToken = AuthSession.accessToken;
      if (accessToken == null) {
        throw Exception('No access token');
      }

      if (widget.isEdit) {
        final relationshipId = widget.followerId ?? 0;
        if (relationshipId <= 0) {
          throw Exception('Missing relationshipId');
        }
        await _followApi.updateFollowerProfiles(
          accessToken: accessToken,
          relationshipId: relationshipId,
          profileIds: profileIds,
        );
      } else {
        final email = widget.user['email']?.toString();
        final userId = _asProfileId(widget.user['id']);

        await _followApi.sendInvite(
          accessToken: accessToken,
          email: email,
          userId: userId > 0 ? userId : null,
          profileIds: profileIds,
        );
      }
    } catch (e) {
      if (!mounted) return;
      final raw = e.toString();
      final lower = raw.toLowerCase();
      final isPending = raw.contains('409') &&
          (lower.contains('pending') || lower.contains('already exists'));
      final message = widget.isEdit
          ? 'บันทึกไม่สำเร็จ: $e'
          : (isPending
              ? 'ส่งคำเชิญไปแล้ว กำลังรอการตอบรับ'
              : 'ส่งคำเชิญไม่สำเร็จ: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
      return;
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(widget.isEdit ? 'บันทึกสำเร็จ' : 'เพิ่มผู้ติดตามแล้ว'),
      ),
    );
    Navigator.pop(context, true);
  }

  Widget _buildProfileRow(Map<String, dynamic> profile) {
    final id = _readProfileId(profile);
    final name = profile['profileName'] ?? 'ไม่ระบุชื่อ';
    final avatarUrl = _readAvatarUrl(profile);
    final isSelectable = id > 0;
    final isSelected = isSelectable && _selectedProfileIds.contains(id);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Checkbox(
            value: isSelected,
            activeColor: _primaryBlue,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
            side: const BorderSide(color: Color(0xFF7FA6D6), width: 1.4),
            onChanged: isSelectable
                ? (value) => _toggleProfile(id, value ?? false)
                : null,
          ),
          CircleAvatar(
            radius: 22,
            backgroundImage:
                avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
            child:
                avatarUrl.isEmpty ? const Icon(Icons.person, size: 20) : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _softPill,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                name,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final email =
        (widget.user['email'] ?? widget.user['mail'] ?? '').toString();
    final rawName = (widget.initialNickname ??
            widget.user['profileName'] ??
            widget.user['name'] ??
            widget.user['displayName'] ??
            '')
        .toString();
    final name = rawName.trim().isNotEmpty
        ? rawName
        : (email.isNotEmpty ? email : 'ไม่ระบุชื่อ');
    final avatarUrl = _readAvatarUrl(widget.user);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEdit ? 'แก้ไขผู้ติดตาม' : 'เพิ่มผู้ติดตาม'),
        backgroundColor: _primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              decoration: BoxDecoration(
                color: _softSurface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 44,
                    backgroundImage:
                        avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                    child: avatarUrl.isEmpty
                        ? const Icon(Icons.person, size: 44)
                        : null,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (email.toString().isNotEmpty)
                    Text(
                      email,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'อนุญาตให้ดูประวัติการทานยา',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 6),
            const Divider(height: 1, color: Color(0xFFB7C6DD)),
            const SizedBox(height: 12),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else ...[
              if (_loadError != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    _loadError!,
                    style: const TextStyle(color: Colors.black45, fontSize: 12),
                  ),
                ),
              if (_loadError == null && _myProfiles.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Text(
                    'ไม่พบโปรไฟล์',
                    style: TextStyle(color: Colors.black45, fontSize: 12),
                  ),
                ),
              Column(
                children: _myProfiles.map(_buildProfileRow).toList(),
              ),
            ],
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(24, 8, 24, 16),
        child: SizedBox(
          height: 44,
          child: ElevatedButton(
            onPressed: _confirmInvite,
            style: ElevatedButton.styleFrom(
              backgroundColor: _accentBlue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
              elevation: 0,
            ),
            child: Text(
              widget.isEdit ? 'บันทึกการแก้ไข' : 'เพิ่มผู้ติดตาม',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ),
    );
  }
}

class _SpeechBubble extends StatelessWidget {
  final String text;

  const _SpeechBubble({required this.text});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 200,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.black54),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12),
          ),
        ),
        CustomPaint(
          size: const Size(18, 10),
          painter: _TrianglePainter(),
        ),
      ],
    );
  }
}

class _TrianglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black54
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final fill = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();

    canvas.drawPath(path, fill);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
