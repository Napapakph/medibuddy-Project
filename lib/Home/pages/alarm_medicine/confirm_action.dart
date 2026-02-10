import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:medibuddy/services/log_api.dart';
import 'package:medibuddy/services/regimen_api.dart';
import 'package:medibuddy/services/app_state.dart';
import 'package:medibuddy/widgets/comment.dart';

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
      final futures =
          ids.map((id) => api.getMedicationLogDetail(logId: id)).toList();
      final results = await Future.wait(futures);
      if (!mounted) return;
      setState(() {
        _logs = results;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'โหลดรายการยาไม่สำเร็จ: $e';
        _logs = [];
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

  String _profileName() {
    if (_logs.isEmpty) return '';
    final profile = _readMap(_logs.first['profile']);
    return _readString(profile['profileName']);
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
      final api = LogApiService();
      await api.submitMedicationLogResponse(
        logId: logId,
        responseStatus: responseStatus,
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

    // final isActive = _activeCommentLogId == logId;
    // final hasNote = (_notesByLogId[logId]?.trim().isNotEmpty ?? false);
    final isSubmitting = _submittingIds.contains(logId);
    final status = _responses[logId];
    final disabled = status != null || isSubmitting;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        // border: Border.all(
        //   color: isActive ? const Color(0xFF1F497D) : Colors.transparent,
        //   width: 2,
        // ),
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
                  child: Icon(
                    Icons.chat_bubble_outline,
                    color: const Color(0xFF1F497D),
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
            ],
          ),
          if (status != null) ...[
            const SizedBox(height: 6),
            Text(
              status == 'TAKE' ? 'บันทึก: กินยา' : 'บันทึก: ข้ามยา',
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
    final profileName = _profileName();

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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (profileName.isNotEmpty)
                              Text(
                                'โปรไฟล์: $profileName',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1F497D),
                                ),
                              ),
                            if (timeText.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                'เวลา $timeText น.',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF6E7C8B),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      Expanded(
                        child: _logs.isEmpty
                            ? const Center(
                                child: Text('ไม่พบรายการยา'),
                              )
                            : ListView.builder(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 4, 16, 16),
                                itemCount: _logs.length,
                                itemBuilder: (context, index) {
                                  final log = _logs[index];
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
