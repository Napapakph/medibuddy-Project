import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:medibuddy/services/log_api.dart';

import 'package:medibuddy/services/app_state.dart';
import 'package:medibuddy/widgets/comment.dart';
import 'package:medibuddy/services/auth_manager.dart'; // Import AuthManager

class ConfirmActionScreen extends StatefulWidget {
  final List<int> logIds;
  final Map<String, dynamic>? payload;
  final String? headerTimeText;

  const ConfirmActionScreen({
    super.key,
    required this.logIds,
    this.payload,
    this.headerTimeText,
  });

  @override
  State<ConfirmActionScreen> createState() => _ConfirmActionScreenState();
}

class _ConfirmActionScreenState extends State<ConfirmActionScreen> {
  bool _loading = false;
  String _errorMessage = '';
  List<Map<String, dynamic>> _logs = [];
  final Set<int> _submittingIds = <int>{};
  final Map<int, String> _responses = <int, String>{};
  final Map<int, String> _notesByLogId = <int, String>{};
  // int? _activeCommentLogId;
  int? _expandedCommentLogId;
  Map<int, List<Map<String, dynamic>>> _groupedLogs = {};
  int? _selectedProfileId;
  List<Map<String, dynamic>> _profiles =
      []; // To store profile info for dropdown separate from logs if needed

  final pid = AppState.instance.currentProfileId;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    final ids = widget.logIds.where((id) => id > 0).toList();
    if (ids.isEmpty) {
      setState(() {
        _errorMessage = 'ไม่พบรายการยาที่ต้องยืนยัน';
        _logs = [];
        _loading = false;
      });
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = '';
    });

    try {
      final api = LogApiService();
      final token = await AuthManager.service.getAccessToken(); // Get token
      final futures = ids
          .map((id) => api.getMedicationLogDetail(
                logId: id,
                accessToken: token, // Pass token
              ))
          .toList();
      final results = await Future.wait(futures);
      if (!mounted) return;

      // Group logs by profile
      final grouped = <int, List<Map<String, dynamic>>>{};
      final profilesMap = <int, Map<String, dynamic>>{};

      for (final log in results) {
        final p = _readMap(log['profile']);
        final pId = _readInt(p['profileId']) ?? 0;
        if (pId > 0) {
          grouped.putIfAbsent(pId, () => []).add(log);
          profilesMap[pId] = p;
        }
      }

      setState(() {
        _logs = results;
        _groupedLogs = grouped;
        _profiles = profilesMap.values.toList();

        // Select first profile if not selected
        if (_selectedProfileId == null && _groupedLogs.isNotEmpty) {
          _selectedProfileId = _groupedLogs.keys.first;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'โหลดรายการยาไม่สำเร็จ: $e';
        _logs = [];
        _groupedLogs = {};
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _loading = false;
      });
    }
  }

  String _readString(dynamic value) {
    if (value == null) return '';
    final text = value.toString().trim();
    if (text.isEmpty || text.toLowerCase() == 'null') return '';
    return text;
  }

  int? _readInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  Map<String, dynamic> _readMap(dynamic value) {
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return <String, dynamic>{};
  }

  String _formatTime(dynamic value) {
    final raw = _readString(value);
    if (raw.isEmpty) return '';
    final dt = DateTime.tryParse(raw);
    if (dt == null) return '';
    final local = dt.toLocal();
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  String _headerTimeText() {
    final provided = _readString(widget.headerTimeText);
    if (provided.isNotEmpty) return provided;
    if (_logs.isEmpty) return '';
    return _formatTime(_logs.first['scheduleTime']);
  }

  String _profileName(int profileId) {
    if (_profiles.isEmpty) return '';
    final profile = _profiles.firstWhere(
        (p) => _readInt(p['profileId']) == profileId,
        orElse: () => {});
    return _readString(profile['profileName']);
  }

  String _profileImage(int profileId) {
    if (_profiles.isEmpty) return '';
    final profile = _profiles.firstWhere(
        (p) => _readInt(p['profileId']) == profileId,
        orElse: () => {});
    final img = _readString(profile['profileImage']);
    if (img.isNotEmpty) return img;
    return _readString(profile['profilePicture']);
  }

  String _mapUnitToThai(String unit) {
    final normalized = unit.trim().toLowerCase();
    switch (normalized) {
      case 'tablet':
        return 'เม็ด';
      case 'ml':
        return 'มิลลิลิตร';
      case 'mg':
        return 'มิลลิกรัม';
      case 'drop':
        return 'ยาหยอด';
      case 'injection':
        return 'เข็ม';
      default:
        return unit.trim().isEmpty ? 'เม็ด' : unit;
    }
  }

  String _doseLabel(Map<String, dynamic> log) {
    final dose = _readInt(log['dose']);
    final unit = _readString(log['unit']);
    if (dose != null && dose > 0) {
      final unitLabel = _mapUnitToThai(unit);
      return '$dose $unitLabel';
    }
    return '1 เม็ด';
  }

  String _toFullImageUrl(String raw) {
    final base = (dotenv.env['API_BASE_URL'] ?? '').trim();
    final p = raw.trim();

    if (p.isEmpty || p.toLowerCase() == 'null') return '';
    if (p.startsWith('http://') || p.startsWith('https://')) return p;
    if (base.isEmpty) return '';

    try {
      final baseUri = Uri.parse(base);
      final normalizedPath = p.startsWith('/') ? p : '/$p';
      return baseUri.resolve(normalizedPath).toString();
    } catch (_) {
      return '';
    }
  }

  ImageProvider? _buildImageProvider(String raw) {
    final url = _toFullImageUrl(raw);
    if (url.isEmpty) return null;
    return NetworkImage(url);
  }

  void _toggleCommentPanel(int logId) {
    setState(() {
      _expandedCommentLogId = _expandedCommentLogId == logId ? null : logId;
    });
  }

  /*
  Future<void> _openCommentDialog({
    required int logId,
    required String medicineNickname,
  }) async {
    setState(() {
      _activeCommentLogId = logId;
    });

    final initial = _notesByLogId[logId] ?? '';
    await showDialog<void>(
      context: context,
      builder: (_) => CommentPopup(
        title: 'คอมเมนต์',
        medicineNickname: medicineNickname.isEmpty ? '-' : medicineNickname,
        initialText: initial,
        onCancel: () {},
        onSubmit: (text) {
          final trimmed = text.trim();
          setState(() {
            if (trimmed.isEmpty) {
              _notesByLogId.remove(logId);
            } else {
              _notesByLogId[logId] = trimmed;
            }
          });
        },
      ),
    );

    if (!mounted) return;
    setState(() {
      _activeCommentLogId = null;
    });
  }
  */

  Future<void> _submitResponse({
    required int logId,
    required String responseStatus,
  }) async {
    if (_submittingIds.contains(logId)) return;
    setState(() {
      _submittingIds.add(logId);
    });

    try {
      final note = _notesByLogId[logId];
      final token = await AuthManager.service.getAccessToken(); // Get token
      final api = LogApiService();
      await api.submitMedicationLogResponse(
        logId: logId,
        responseStatus: responseStatus,
        accessToken: token, // Pass token
        note: note?.trim().isEmpty ?? true ? null : note?.trim(),
      );
      // final api = RegimenApiService();
      // await api.submitMedicationLogResponse(
      //   logId: logId,
      //   responseStatus: responseStatus,
      // );
      if (!mounted) return;
      setState(() {
        _submittingIds.remove(logId);
        _responses[logId] = responseStatus;
      });
      if (_responses.length >= _logs.length && _logs.isNotEmpty) {
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
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submittingIds.remove(logId);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ส่งผลไม่สำเร็จ: $e')),
      );
    }
  }

  Widget _buildLogCard(Map<String, dynamic> log) {
    final logId = _readInt(log['logId']) ?? 0;
    final medicineList = _readMap(log['medicineList']);
    final medicine = _readMap(medicineList['medicine']);

    final nickname = _readString(medicineList['mediNickname']);
    final tradeName = _readString(medicine['mediTradeName']);
    final thName = _readString(medicine['mediThName']);
    final enName = _readString(medicine['mediEnName']);

    final title = nickname.isNotEmpty
        ? nickname
        : (tradeName.isNotEmpty
            ? tradeName
            : (thName.isNotEmpty
                ? thName
                : (enName.isNotEmpty ? enName : '-')));

    final subtitle =
        tradeName.isNotEmpty && tradeName != title ? tradeName : '';

    final pictureOption = _readString(medicineList['pictureOption']);
    final mediPicture = _readString(medicine['mediPicture']);
    final imagePath = pictureOption.isNotEmpty ? pictureOption : mediPicture;
    final imageProvider = _buildImageProvider(imagePath);

    final isSubmitting = _submittingIds.contains(logId);
    final status = _responses[logId];
    final disabled = status != null || isSubmitting;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF3FA),
                  borderRadius: BorderRadius.circular(12),
                  image: imageProvider != null
                      ? DecorationImage(
                          image: imageProvider,
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: imageProvider == null
                    ? const Icon(Icons.medication, color: Color(0xFF1F497D))
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1F497D),
                      ),
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6E7C8B),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    const Text(
                      'ก่อนอาหาร',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6E7C8B),
                      ),
                    ),
                    // TODO: backend will provide meal relation later.
                    const SizedBox(height: 4),
                    Text(
                      'ปริมาณ: ${_doseLabel(log)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6E7C8B),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: disabled ? null : () => _toggleCommentPanel(logId),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFFB7DAFF),
                    ),
                    color: Colors.white,
                  ),
                  child: const Icon(
                    Icons.chat_bubble_outline,
                    color: Color(0xFF1F497D),
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: disabled
                      ? null
                      : () => _submitResponse(
                            logId: logId,
                            responseStatus: 'SKIP',
                          ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFE35D5D),
                    side: const BorderSide(color: Color(0xFFE35D5D)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: isSubmitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('ข้ามยา'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: disabled
                      ? null
                      : () => _submitResponse(
                            logId: logId,
                            responseStatus: 'TAKE',
                          ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1F497D),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: isSubmitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('กินยา'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: disabled
                      ? null
                      : () => _submitResponse(
                            logId: logId,
                            responseStatus: 'SNOOZE',
                          ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFF0A24F),
                    side: const BorderSide(color: Color(0xFFF0A24F)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('เลื่อน'),
                ),
              ),
            ],
          ),
          if (status != null) ...[
            const SizedBox(height: 6),
            Text(
              status == 'TAKE'
                  ? 'บันทึก: กินยา'
                  : (status == 'SKIP' ? 'บันทึก: ข้ามยา' : 'บันทึก: เลื่อน'),
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF6E7C8B),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final timeText = _headerTimeText();
    // Use selected profile or fall back
    final currentProfileId = _selectedProfileId ?? 0;
    final displayLogs = _groupedLogs[currentProfileId] ?? _logs;

    final profileName = _profileName(currentProfileId);
    final profileImg = _profileImage(currentProfileId);
    final profileImgProvider = _buildImageProvider(profileImg);

    final hasMultipleProfiles = _groupedLogs.keys.length > 1;

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 217, 235, 255),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1F497D),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back,
              color: Color.fromARGB(255, 255, 255, 255)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'รายการยาที่ต้องรับประทาน',
          style: TextStyle(
            color: Color.fromARGB(255, 255, 255, 255),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage.isNotEmpty
                ? Center(
                    child: Text(
                      _errorMessage,
                      textAlign: TextAlign.center,
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        color: const Color.fromARGB(0, 255, 255, 255),
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                        child: Column(
                          children: [
                            if (hasMultipleProfiles)
                              Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                height: 110,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: _profiles.length,
                                  itemBuilder: (context, index) {
                                    final p = _profiles[index];
                                    final pid = _readInt(p['profileId']) ?? 0;
                                    final name = _readString(p['profileName']);
                                    final img = _readString(p['profileImage'])
                                            .isNotEmpty
                                        ? _readString(p['profileImage'])
                                        : _readString(p['profilePicture']);
                                    final provider = _buildImageProvider(img);
                                    final isSelected =
                                        _selectedProfileId == pid;

                                    return GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _selectedProfileId = pid;
                                        });
                                      },
                                      child: Container(
                                        width: 100,
                                        margin:
                                            const EdgeInsets.only(right: 12),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? const Color(0xFF1F497D)
                                              : Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(16),
                                          border: Border.all(
                                            color: isSelected
                                                ? const Color(0xFF1F497D)
                                                : Colors.grey.shade300,
                                            width: 1.5,
                                          ),
                                          boxShadow: [
                                            if (isSelected)
                                              const BoxShadow(
                                                color: Color(0x33000000),
                                                blurRadius: 6,
                                                offset: Offset(0, 3),
                                              )
                                          ],
                                        ),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Container(
                                              width: 48,
                                              height: 48,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: Colors.grey.shade100,
                                                border: Border.all(
                                                    color: Colors.grey.shade300,
                                                    width: 1),
                                                image: provider != null
                                                    ? DecorationImage(
                                                        image: provider,
                                                        fit: BoxFit.cover,
                                                      )
                                                    : null,
                                              ),
                                              child: provider == null
                                                  ? const Icon(Icons.person,
                                                      color: Colors.grey,
                                                      size: 28)
                                                  : null,
                                            ),
                                            const SizedBox(height: 8),
                                            Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 4.0),
                                              child: Text(
                                                name,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                  color: isSelected
                                                      ? Colors.white
                                                      : const Color(0xFF1F497D),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),

                            // Profile Image & Name (Centered for single profile)
                            if (currentProfileId > 0 && !hasMultipleProfiles)
                              Column(
                                children: [
                                  Container(
                                    width: 80,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.grey.shade200,
                                      border: Border.all(
                                          color: Colors.grey.shade300,
                                          width: 1.5),
                                      image: profileImgProvider != null
                                          ? DecorationImage(
                                              image: profileImgProvider,
                                              fit: BoxFit.cover)
                                          : null,
                                    ),
                                    child: profileImgProvider == null
                                        ? const Icon(Icons.person,
                                            size: 40, color: Colors.grey)
                                        : null,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    profileName,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1F497D),
                                    ),
                                  ),
                                  if (timeText.isNotEmpty)
                                    Text(
                                      'เวลา $timeText น.',
                                      style: const TextStyle(
                                          fontSize: 14, color: Colors.grey),
                                    ),
                                ],
                              ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: displayLogs.isEmpty
                            ? const Center(
                                child: Text('ไม่พบรายการยาสำหรับโปรไฟล์นี้'),
                              )
                            : ListView.builder(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 16, 16, 16),
                                itemCount: displayLogs.length,
                                itemBuilder: (context, index) {
                                  final log = displayLogs[index];
                                  final logId = _readInt(log['logId']) ?? 0;
                                  final medicineList =
                                      _readMap(log['medicineList']);
                                  final medicine =
                                      _readMap(medicineList['medicine']);
                                  final nickname =
                                      _readString(medicineList['mediNickname']);
                                  final tradeName =
                                      _readString(medicine['mediTradeName']);
                                  final thName =
                                      _readString(medicine['mediThName']);
                                  final enName =
                                      _readString(medicine['mediEnName']);

                                  final displayName = nickname.isNotEmpty
                                      ? nickname
                                      : (tradeName.isNotEmpty
                                          ? tradeName
                                          : (thName.isNotEmpty
                                              ? thName
                                              : (enName.isNotEmpty
                                                  ? enName
                                                  : '-')));

                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      _buildLogCard(log),
                                      if (_expandedCommentLogId == logId)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                              top: 8, left: 12, right: 12),
                                          child: CommentInline(
                                            medicineNickname: displayName,
                                            initialText:
                                                _notesByLogId[logId] ?? '',
                                            onChanged: (text) {
                                              _notesByLogId[logId] = text;
                                            },
                                            onSubmit: () {
                                              final text =
                                                  _notesByLogId[logId] ?? '';
                                              final trimmed = text.trim();
                                              setState(() {
                                                if (trimmed.isEmpty) {
                                                  _notesByLogId.remove(logId);
                                                } else {
                                                  _notesByLogId[logId] =
                                                      trimmed;
                                                }
                                                _expandedCommentLogId = null;
                                              });
                                            },
                                          ),
                                        ),
                                    ],
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
      ),
    );
  }
}
