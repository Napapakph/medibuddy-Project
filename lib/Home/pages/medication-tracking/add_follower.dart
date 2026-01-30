import 'package:flutter/material.dart';
import 'package:medibuddy/services/auth_session.dart';
import 'package:medibuddy/services/profile_api.dart';

const Color _primaryBlue = Color(0xFF1F497D);
const Color _softSurface = Color(0xFFF1F4F7);
const Color _softPill = Color(0xFFDCE2E8);
const Color _accentBlue = Color(0xFF8FB6E5);

class AddFollowerScreen extends StatefulWidget {
  const AddFollowerScreen({super.key});

  @override
  State<AddFollowerScreen> createState() => _AddFollowerScreenState();
}

class _AddFollowerScreenState extends State<AddFollowerScreen> {
  final _searchController = TextEditingController();
  final _profileApi = ProfileApi();

  Map<String, dynamic>? _foundUser;
  bool _isSearching = false;
  bool _isInviteSent = false;
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

    final accessToken = AuthSession.accessToken;
    if (accessToken == null) {
      setState(() => _searchError = 'ไม่พบข้อมูลการเข้าสู่ระบบ');
      return;
    }

    try {
      setState(() {
        _isSearching = true;
        _searchError = null;
        _foundUser = null;
        _isInviteSent = false;
      });

      final profiles = await _profileApi.fetchProfiles(
        accessToken: accessToken,
      );

      final matching = profiles.firstWhere(
        (p) =>
            (p['email'] ?? '')
                .toString()
                .toLowerCase()
                .contains(email.toLowerCase()),
        orElse: () => {},
      );

      if (matching.isEmpty) {
        setState(() => _searchError = 'ไม่พบผู้ใช้ที่ค้นหา');
      } else {
        setState(() => _foundUser = matching);
      }
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
      setState(() => _isInviteSent = true);
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
              'assets/cat_login.png',
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
    final name = user['profileName'] ?? 'ไม่ระบุชื่อ';
    final email = user['email'] ?? '';
    final avatarUrl = user['profilePicture'] as String?;

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
                  avatarUrl != null && avatarUrl.isNotEmpty
                      ? NetworkImage(avatarUrl)
                      : null,
              child: avatarUrl == null || avatarUrl.isEmpty
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
              if (_foundUser != null) _buildFoundAccount(_foundUser!),
              if (_foundUser == null && _searchError == null)
                const Text(
                  'ยังไม่มีผลการค้นหา',
                  style: TextStyle(color: Colors.black38),
                ),
              if (_isInviteSent) ...[
                const SizedBox(height: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE6F0FF),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text(
                    'ส่งคำเชิญแล้ว',
                    style: TextStyle(
                      color: _primaryBlue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class FollowerPermissionScreen extends StatefulWidget {
  final Map<String, dynamic> user;

  const FollowerPermissionScreen({super.key, required this.user});

  @override
  State<FollowerPermissionScreen> createState() =>
      _FollowerPermissionScreenState();
}

class _FollowerPermissionScreenState extends State<FollowerPermissionScreen> {
  final _profileApi = ProfileApi();
  final List<Map<String, dynamic>> _demoProfiles = const [
    {'id': 1, 'profileName': 'ฉัน'},
    {'id': 2, 'profileName': 'ยาย'},
    {'id': 3, 'profileName': 'แม่'},
  ];

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

  Future<void> _loadMyProfiles() async {
    final accessToken = AuthSession.accessToken;
    if (accessToken == null) {
      setState(() {
        _myProfiles = _demoProfiles;
        _selectedProfileIds.add(_asProfileId(_demoProfiles.first['id']));
        _isLoading = false;
        _loadError = 'ไม่พบข้อมูลการเข้าสู่ระบบ';
      });
      return;
    }

    try {
      final profiles = await _profileApi.fetchProfiles(
        accessToken: accessToken,
      );
      if (profiles.isEmpty) {
        _myProfiles = _demoProfiles;
      } else {
        _myProfiles = profiles;
      }
      if (_myProfiles.isNotEmpty) {
        _selectedProfileIds.add(_asProfileId(_myProfiles.first['id']));
      }
      _loadError = null;
    } catch (e) {
      _myProfiles = _demoProfiles;
      _selectedProfileIds.add(_asProfileId(_demoProfiles.first['id']));
      _loadError = 'โหลดโปรไฟล์ไม่สำเร็จ';
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _toggleProfile(int id, bool selected) {
    setState(() {
      if (selected) {
        _selectedProfileIds.add(id);
      } else {
        _selectedProfileIds.remove(id);
      }
    });
  }

  Future<void> _confirmInvite() async {
    if (_selectedProfileIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเลือกอย่างน้อย 1 โปรไฟล์')),
      );
      return;
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('เพิ่มผู้ติดตามแล้ว')),
    );
    Navigator.pop(context, true);
  }

  Widget _buildProfileRow(Map<String, dynamic> profile) {
    final id = _asProfileId(profile['id']);
    final name = profile['profileName'] ?? 'ไม่ระบุชื่อ';
    final avatarUrl = profile['profilePicture'] as String?;
    final isSelected = _selectedProfileIds.contains(id);

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
            onChanged: (value) => _toggleProfile(id, value ?? false),
          ),
          CircleAvatar(
            radius: 22,
            backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                ? NetworkImage(avatarUrl)
                : null,
            child: avatarUrl == null || avatarUrl.isEmpty
                ? const Icon(Icons.person, size: 20)
                : null,
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
    final name = widget.user['profileName'] ?? 'ไม่ระบุชื่อ';
    final email = widget.user['email'] ?? '';
    final avatarUrl = widget.user['profilePicture'] as String?;

    return Scaffold(
      appBar: AppBar(
        title: const Text('เพิ่มผู้ติดตาม'),
        backgroundColor: _primaryBlue,
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
                    backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                        ? NetworkImage(avatarUrl)
                        : null,
                    child: avatarUrl == null || avatarUrl.isEmpty
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
            child: const Text(
              'เพิ่มผู้ติดตาม',
              style: TextStyle(fontWeight: FontWeight.w600),
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
