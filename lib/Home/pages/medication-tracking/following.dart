import 'package:flutter/material.dart';
import 'package:medibuddy/services/follow_api.dart';
import 'package:medibuddy/services/auth_session.dart';
import 'package:medibuddy/services/medicine_api.dart';
import 'package:medibuddy/widgets/medicine_step_timeline.dart';

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
        data['followingId'] ??
        data['profileId'] ??
        data['userId'];
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

  String _readEmail(Map<String, dynamic> data) {
    return (data['email'] ?? data['mail'] ?? '').toString();
  }

  String _readAvatar(Map<String, dynamic> data) {
    return (data['profilePicture'] ??
            data['profilePictureUrl'] ??
            data['avatar'] ??
            data['picture'] ??
            '')
        .toString();
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

  void _showMonitoringDetail(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (ctx) => _MonitoringDetailView(user: user),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('กำลังติดตาม'),
        backgroundColor: const Color(0xFF1F497D),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
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
                              final name = _readName(user);
                              final avatarUrl = _readAvatar(user);

                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundImage: avatarUrl.isNotEmpty
                                      ? NetworkImage(avatarUrl)
                                      : null,
                                  child: avatarUrl.isEmpty
                                      ? const Icon(Icons.person)
                                      : null,
                                ),
                                title: Text(name),
                                onTap: () => _showMonitoringDetail(user),
                                trailing: const Icon(Icons.arrow_forward_ios),
                              );
                            },
                          ),
                  ],
                ),
    );
  }
}

// ===== DETAIL VIEW สำหรับดูตารางยา =====
class _MonitoringDetailView extends StatefulWidget {
  final Map<String, dynamic> user;

  const _MonitoringDetailView({required this.user});

  @override
  State<_MonitoringDetailView> createState() => _MonitoringDetailViewState();
}

class _MonitoringDetailViewState extends State<_MonitoringDetailView> {
  final _medicineApi = MedicineApi();

  int _currentStep = 1;
  bool _isLoading = true;
  List<Map<String, dynamic>> _medicines = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadMedicines();
  }

  Future<void> _loadMedicines() async {
    try {
      setState(() => _isLoading = true);

      final rawId = widget.user['profileId'] ??
          widget.user['id'] ??
          widget.user['followedProfileId'];
      final profileId = int.tryParse(rawId.toString()) ?? 0;
      if (profileId == 0) {
        throw Exception('Invalid profile id');
      }

      final medicines = await _medicineApi.fetchProfileMedicineList(
        profileId: profileId,
      );

      setState(() {
        _isLoading = false;
        _errorMessage = null;
        _medicines = medicines
            .map((med) => {
                  'id': med.id,
                  'nickname': med.nickname_medi,
                  'officialName': med.officialName_medi,
                })
            .toList();
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'โหลดข้อมูลยาไม่สำเร็จ: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final userName = widget.user['profileName'] ?? 'ไม่มีชื่อ';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Scaffold(
        appBar: AppBar(
          title: Text('ตารางยา - $userName'),
          backgroundColor: const Color(0xFF1F497D),
          automaticallyImplyLeading: true,
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
                          onPressed: _loadMedicines,
                          child: const Text('ลองใหม่'),
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 40,
                              backgroundImage: widget.user['profilePicture'] !=
                                          null &&
                                      (widget.user['profilePicture'] as String)
                                          .isNotEmpty
                                  ? NetworkImage(widget.user['profilePicture'])
                                  : null,
                              child: widget.user['profilePicture'] == null
                                  ? const Icon(Icons.person, size: 40)
                                  : null,
                            ),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  userName,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (widget.user['email'] != null)
                                  Text(
                                    widget.user['email'],
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Timeline
                        const Text(
                          'ขั้นตอนการใช้ยา',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        MedicineStepTimeline(currentStep: _currentStep),
                        const SizedBox(height: 24),
                        const Text(
                          'รายการยาของผู้ใช้',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (_medicines.isEmpty)
                          const Text('ไม่มีข้อมูลยา')
                        else
                          Column(
                            children: <Widget>[
                              ..._medicines.map((med) {
                                return Card(
                                  margin:
                                      const EdgeInsets.symmetric(vertical: 8),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          med['nickname'] ?? 'ไม่มีชื่อ',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                        if (med['officialName'] != null &&
                                            (med['officialName'] as String)
                                                .isNotEmpty)
                                          Text(
                                            'ชื่ออย่างเป็นทางการ: ${med['officialName']}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            ],
                          ),
                      ],
                    ),
                  ),
      ),
    );
  }
}













