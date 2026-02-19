import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:lottie/lottie.dart';
import 'package:intl/intl.dart';
import 'package:medibuddy/services/auth_manager.dart'; // import 'package:medibuddy/services/auth_session.dart';
import 'package:medibuddy/services/follow_api.dart';
import 'package:medibuddy/services/log_api.dart';
import 'package:medibuddy/widgets/comment.dart';

/// ===============================
/// Models (Copied from HistoryPage)
/// ===============================
enum MedicineTakeStatus { take, skip, snooze, none }

class MedicineHistoryItem {
  final DateTime takenAt;
  final String titleTh;
  final String titleEn;
  final String detail;
  final int amount;
  final int? dose;
  final String? unit;
  final MedicineTakeStatus status;
  final String? note;
  final String nickname;
  final String tradeName;
  final String thName;
  final String enName;

  const MedicineHistoryItem({
    required this.takenAt,
    required this.titleTh,
    required this.titleEn,
    required this.detail,
    required this.amount,
    this.dose,
    this.unit,
    required this.status,
    this.note,
    required this.nickname,
    required this.tradeName,
    required this.thName,
    required this.enName,
  });
}

/// ===============================
/// Page
/// ===============================
class FollowingHistoryPage extends StatefulWidget {
  final int relationshipId;
  final int profileId;
  final String profileName;
  final String ownerName;
  final String? ownerImage;

  const FollowingHistoryPage({
    super.key,
    required this.relationshipId,
    required this.profileId,
    required this.profileName,
    required this.ownerName,
    this.ownerImage,
  });

  @override
  State<FollowingHistoryPage> createState() => _FollowingHistoryPageState();
}

class _FollowingHistoryPageState extends State<FollowingHistoryPage> {
  final _followApi = FollowApi();
  final _searchCtrl = TextEditingController();

  static const _searchTrade = 'ชื่อการค้า';
  static const _searchTh = 'ชื่อสามัญไทย';
  static const _searchEn = 'ชื่อสามัญอังกฤษ';
  static const _searchNickname = 'ชื่อเล่นยา';

  String _imageBaseUrl = '';
  String _searchMode = _searchTrade;

  DateTime _startDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime _endDate = DateTime.now();
  bool _isDateFilterUserSet = false;

  bool _loading = false;
  String _errorMessage = '';

  List<MedicineHistoryItem> _allItems = [];
  List<MedicineHistoryItem> _filteredItems = [];

  // State for header info
  String _ownerName = '';
  String _ownerImage = '';
  String _profileLabel = '';

  @override
  void initState() {
    super.initState();
    _imageBaseUrl = dotenv.env['API_BASE_URL'] ?? '';
    // Init from widget first
    _ownerName = widget.ownerName;
    _ownerImage = widget.ownerImage ?? '';
    _profileLabel = widget.profileName;

    _setDefaultDateRange();
    _loadHistory();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  /// ===============================
  /// Data + Mapping (Logic from HistoryPage)
  /// ===============================
  String _readString(dynamic value) {
    if (value == null) return '';
    final text = value.toString().trim();
    if (text.isEmpty) return '';
    if (text.toLowerCase() == 'null') return '';
    return text;
  }

  int? _readInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  MedicineTakeStatus _statusFromResponse(String? status) {
    switch ((status ?? '').toUpperCase()) {
      case 'TAKE':
        return MedicineTakeStatus.take;
      case 'SKIP':
        return MedicineTakeStatus.skip;
      case 'SNOOZE':
        return MedicineTakeStatus.snooze;
      default:
        return MedicineTakeStatus.none;
    }
  }

  int _resolveAmount(Map<String, dynamic> log) {
    const keys = [
      'quantityPills',
      'doseCount',
      'quantity',
      'pillsCount',
      'amount',
    ];
    for (final key in keys) {
      final value = _readInt(log[key]);
      if (value != null && value > 0) return value;
    }
    return 1;
  }

  int? _resolveDose(Map<String, dynamic> log) {
    final value = _readInt(log['dose']);
    if (value == null || value <= 0) return null;
    return value;
  }

  String? _resolveUnit(Map<String, dynamic> log) {
    final value = _readString(log['unit']);
    if (value.isEmpty) return null;
    return value;
  }

  MedicineHistoryItem _mapLogToItem(Map<String, dynamic> log) {
    final scheduleRaw = _readString(log['scheduleTime']);
    final schedule =
        scheduleRaw.isEmpty ? null : DateTime.tryParse(scheduleRaw)?.toLocal();
    final takenAt = schedule ?? DateTime.now();

    final status = _statusFromResponse(_readString(log['responseStatus']));
    final note = _readString(log['note']);
    final dose = _resolveDose(log);
    final unit = _resolveUnit(log);
    final amount = (dose != null && dose > 0) ? dose : _resolveAmount(log);

    // Schema:
    // medicineName = Display name (nickname or fallback)
    // mediThName = Thai medicine name
    // mediEnName = English medicine name
    // mediTradeName = Trade/brand medicine name

    final nickname = _readString(log['medicineName']);
    final tradeName = _readString(log['mediTradeName']);
    final thName = _readString(log['mediThName']);
    final enName = _readString(log['mediEnName']);

    final safeNickname = nickname.isNotEmpty ? nickname : '';
    final safeTrade = tradeName.isNotEmpty ? tradeName : '';
    final safeTh = thName.isNotEmpty ? thName : '';
    final safeEn = enName.isNotEmpty ? enName : '';

    // Log logic: if nickname exists, show it. Otherwise trade > th > en
    final mainTitle = safeNickname.isNotEmpty
        ? safeNickname
        : (safeTrade.isNotEmpty
            ? safeTrade
            : (safeTh.isNotEmpty
                ? safeTh
                : (safeEn.isNotEmpty ? safeEn : 'ไม่ทราบชื่อยา')));

    final subtitle = safeTrade;

    final detailParts = <String>[];
    if (safeTh.isNotEmpty) detailParts.add(safeTh);
    if (safeEn.isNotEmpty) detailParts.add(safeEn);
    final detail = detailParts.isEmpty ? '' : detailParts.join('\n');

    return MedicineHistoryItem(
      takenAt: takenAt,
      titleTh: mainTitle,
      titleEn: subtitle,
      detail: detail,
      amount: amount,
      dose: dose,
      unit: unit,
      status: status,
      note: note.isNotEmpty ? null : note,
      nickname: safeNickname,
      tradeName: safeTrade,
      thName: safeTh,
      enName: safeEn,
    );
  }

  Future<void> _loadHistory() async {
    final accessToken = AuthManager.accessToken;
    if (accessToken == null) {
      setState(() => _errorMessage = 'ไม่พบข้อมูลเข้าสู่ระบบ');
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = '';
    });

    try {
      // 1. Fetch Follow Detail to get up-to-date owner info & profile name
      try {
        final detail = await _followApi.fetchFollowingDetail(
          accessToken: accessToken,
          relationshipId: widget.relationshipId,
        );

        if (detail['relationship'] is Map) {
          final rel = detail['relationship'] as Map;
          final nick = _readString(rel['ownerNickname']);
          if (nick.isNotEmpty) _ownerName = nick;

          final pic = _readString(rel['ownerPicture']);
          if (pic.isNotEmpty) _ownerImage = pic;
        }

        if (detail['profiles'] is List) {
          final list = detail['profiles'] as List;
          final found = list.firstWhere(
            (p) => _readInt(p['profileId']) == widget.profileId,
            orElse: () => null,
          );
          if (found != null && found is Map) {
            final pName = _readString(found['profileName']);
            if (pName.isNotEmpty) _profileLabel = pName;

            final pPic = _readString(found['profilePicture']);
            if (pPic.isNotEmpty) _ownerImage = pPic;
          }
        }
      } catch (e) {
        debugPrint('Error fetching detail: $e');
        // Ignore error, use widget data
      }

      final startStr = DateFormat('yyyy-MM-dd').format(_startDate);
      final endStr = DateFormat('yyyy-MM-dd').format(_endDate);

      // 2. Fetch list of logs
      debugPrint('Fetching logs for relationshipId=${widget.relationshipId}');
      final logs = await _followApi.fetchFollowingLogs(
        accessToken: accessToken,
        relationshipId: widget.relationshipId,
        profileId: widget.profileId,
        startDate: startStr,
        endDate: endStr,
      );

      debugPrint('Logs received: ${logs.length}');

      final items = logs.map(_mapLogToItem).toList();
      items.sort((a, b) => b.takenAt.compareTo(a.takenAt));

      if (!mounted) return;
      setState(() {
        _allItems = items;
        _filteredItems = _filterItems(items);
      });
    } catch (e) {
      debugPrint('Error loading history: $e');
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _allItems = [];
        _filteredItems = [];
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ===== Image =====
  ImageProvider? _buildProfileImage(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) return null;
    if (imagePath.startsWith('/uploads')) {
      return NetworkImage('$_imageBaseUrl$imagePath');
    }
    if (imagePath.startsWith('http')) {
      return NetworkImage(imagePath);
    }
    return FileImage(File(imagePath));
  }

  // ===== Filter =====
  void _setDefaultDateRange() {
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, now.day);
    _endDate = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
    _isDateFilterUserSet = false;
  }

  void _applyFilters() {
    if (!mounted) return;
    setState(() => _filteredItems = _filterItems(_allItems));
  }

  List<MedicineHistoryItem> _filterItems(List<MedicineHistoryItem> items) {
    return items.where((item) {
      final inRange = _isInDateRange(item);
      final bySearch = _matchesKeyword(item);
      return inRange && bySearch;
    }).toList()
      ..sort((a, b) => b.takenAt.compareTo(a.takenAt));
  }

  bool _isInDateRange(MedicineHistoryItem item) {
    final keyword = _searchCtrl.text.trim();
    if (keyword.isNotEmpty && !_isDateFilterUserSet) return true;

    final day =
        DateTime(item.takenAt.year, item.takenAt.month, item.takenAt.day);
    final start = DateTime(_startDate.year, _startDate.month, _startDate.day);
    final end = DateTime(_endDate.year, _endDate.month, _endDate.day);
    return !day.isBefore(start) && !day.isAfter(end);
  }

  bool _matchesKeyword(MedicineHistoryItem item) {
    final keyword = _searchCtrl.text.trim().toLowerCase();
    if (keyword.isEmpty) return true;

    switch (_searchMode) {
      case _searchTrade:
        if (item.tradeName.isEmpty) return false;
        return item.tradeName.toLowerCase().contains(keyword);
      case _searchTh:
        if (item.thName.isEmpty) return false;
        return item.thName.toLowerCase().contains(keyword);
      case _searchEn:
        if (item.enName.isEmpty) return false;
        return item.enName.toLowerCase().contains(keyword);
      case _searchNickname:
        if (item.nickname.isEmpty) return false;
        return item.nickname.toLowerCase().contains(keyword);
      default:
        return false;
    }
  }

  Map<DateTime, List<MedicineHistoryItem>> _groupByDate(
      List<MedicineHistoryItem> items) {
    final map = <DateTime, List<MedicineHistoryItem>>{};
    for (final it in items) {
      final key = DateTime(it.takenAt.year, it.takenAt.month, it.takenAt.day);
      map.putIfAbsent(key, () => []).add(it);
    }
    return map;
  }

  Future<void> _pickDate({required bool isStart}) async {
    final initial = isStart ? _startDate : _endDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('th', 'TH'),
    );
    if (picked == null) return;
    setState(() {
      _isDateFilterUserSet = true;
      if (isStart) {
        _startDate = picked;
        if (_startDate.isAfter(_endDate)) _endDate = _startDate;
      } else {
        _endDate = picked;
        if (_endDate.isBefore(_startDate)) _startDate = _endDate;
      }
    });
    _loadHistory();
  }

  String _formatThaiDate(DateTime d) {
    final weekDayTh = _weekdayTh(d.weekday);
    final monthTh = _monthTh(d.month);
    return '$weekDayTh ${d.day} $monthTh ${d.year}';
  }

  String _weekdayTh(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'จ.';
      case DateTime.tuesday:
        return 'อ.';
      case DateTime.wednesday:
        return 'พ.';
      case DateTime.thursday:
        return 'พฤ.';
      case DateTime.friday:
        return 'ศ.';
      case DateTime.saturday:
        return 'ส.';
      case DateTime.sunday:
        return 'อา.';
      default:
        return '';
    }
  }

  String _monthTh(int month) {
    const months = [
      'ม.ค.',
      'ก.พ.',
      'มี.ค.',
      'เม.ย.',
      'พ.ค.',
      'มิ.ย.',
      'ก.ค.',
      'ส.ค.',
      'ก.ย.',
      'ต.ค.',
      'พ.ย.',
      'ธ.ค.',
    ];
    return months[month - 1];
  }

  String _formatTime(DateTime d) {
    final hh = d.hour.toString().padLeft(2, '0');
    final mm = d.minute.toString().padLeft(2, '0');
    return '$hh:$mm น.';
  }

  String _timeKey(DateTime d) {
    final hh = d.hour.toString().padLeft(2, '0');
    final mm = d.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  void _showNoteViewer(MedicineHistoryItem item) {
    final note = item.note?.trim() ?? '';
    if (note.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ไม่มีคอมเมนต์')),
      );
      return;
    }
    final nickname = item.nickname.isNotEmpty ? item.nickname : item.titleTh;
    showDialog<void>(
      context: context,
      builder: (_) => CommentViewer(
        title: 'comment',
        medicineNickname: nickname.isNotEmpty ? nickname : '-',
        note: note,
      ),
    );
  }

  // ===== UI =====
  static const _primary = Color(0xFF1F497D);

  @override
  Widget build(BuildContext context) {
    final items = _filteredItems;
    final grouped = _groupByDate(items);
    final dateKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));
    final ownerAvatar = _buildProfileImage(_ownerImage);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: _primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'ประวัติ\nการรับประทานยา',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          textAlign: TextAlign.center,
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                // ===== Owner profile header =====
                Container(
                  width: double.infinity,
                  color: _primary,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: const Color(0xFF2C3137),
                        backgroundImage: ownerAvatar,
                        child: ownerAvatar == null
                            ? const Icon(Icons.person,
                                color: Colors.white70, size: 28)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _ownerName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'โปรไฟล์: $_profileLabel',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // ===== Search & Filter Toolbar =====
                Container(
                  color: _primary,
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _searchMode,
                            borderRadius: BorderRadius.circular(12),
                            items: const [
                              DropdownMenuItem(
                                  value: _searchTrade,
                                  child: Text(_searchTrade)),
                              DropdownMenuItem(
                                  value: _searchTh, child: Text(_searchTh)),
                              DropdownMenuItem(
                                  value: _searchEn, child: Text(_searchEn)),
                              DropdownMenuItem(
                                  value: _searchNickname,
                                  child: Text(_searchNickname)),
                            ],
                            dropdownColor: Colors.white,
                            onChanged: (v) {
                              if (v == null) return;
                              setState(() {
                                _searchMode = v;
                                _applyFilters();
                              });
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Container(
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: TextField(
                            controller: _searchCtrl,
                            onChanged: (_) => _applyFilters(),
                            decoration: const InputDecoration(
                              hintText: 'ค้นหา...',
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ===== Date range =====
                Container(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: _DateField(
                          label: '',
                          value:
                              DateFormat('d MMMM', 'th_TH').format(_startDate),
                          onTap: () => _pickDate(isStart: true),
                        ),
                      ),
                      const SizedBox(width: 5),
                      const Text('ถึง'),
                      const SizedBox(width: 5),
                      Expanded(
                        child: _DateField(
                          label: '',
                          value: DateFormat('d MMMM', 'th_TH').format(_endDate),
                          onTap: () => _pickDate(isStart: false),
                        ),
                      ),
                    ],
                  ),
                ),

                // ===== List =====
                Expanded(
                  child: _errorMessage.isNotEmpty
                      ? Center(
                          child: Text(
                            _errorMessage,
                            textAlign: TextAlign.center,
                          ),
                        )
                      : items.isEmpty
                          ? const Center(
                              child: Text('ไม่มีประวัติในช่วงวันที่ที่เลือก'))
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                              itemCount: dateKeys.length,
                              itemBuilder: (context, i) {
                                final dayKey = dateKeys[i];
                                final dayItems = grouped[dayKey]!
                                  ..sort(
                                      (a, b) => b.takenAt.compareTo(a.takenAt));
                                final timeGroups =
                                    <String, List<MedicineHistoryItem>>{};
                                for (final it in dayItems) {
                                  final key = _timeKey(it.takenAt);
                                  timeGroups.putIfAbsent(key, () => []).add(it);
                                }

                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 8),
                                    Center(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 100, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: const Color.fromARGB(
                                              255, 236, 238, 243),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          _formatThaiDate(dayKey),
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            color: _primary,
                                          ),
                                        ),
                                      ),
                                    ),
                                    ...timeGroups.entries.map((entry) {
                                      final timeKey = entry.key;
                                      final groupItems = entry.value;
                                      return Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.only(
                                                top: 8, bottom: 4),
                                            child: Text(
                                              '$timeKey น.',
                                              style: const TextStyle(
                                                fontSize: 14,
                                                color: _primary,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                          ...groupItems.map((it) => _HistoryRow(
                                                timeText:
                                                    _formatTime(it.takenAt),
                                                item: it,
                                                onTapComment: () {
                                                  _showNoteViewer(it);
                                                },
                                                showTime: false,
                                              )),
                                        ],
                                      );
                                    }),
                                  ],
                                );
                              },
                            ),
                ),
              ],
            ),
          ),
          if (_loading)
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
    );
  }
}

// ===== Date Field Widget =====
class _DateField extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;

  const _DateField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  static const _primary = Color(0xFF1F497D);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E6EF)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: _primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  value,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Icon(Icons.calendar_month, color: _primary),
            ],
          ),
        ),
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  final String timeText;
  final MedicineHistoryItem item;
  final VoidCallback onTapComment;
  final bool showTime;

  const _HistoryRow({
    required this.timeText,
    required this.item,
    required this.onTapComment,
    this.showTime = true,
  });

  static const _primary = Color(0xFF1F497D);

  Color _statusBarColor() {
    switch (item.status) {
      case MedicineTakeStatus.take:
        return const Color.fromARGB(255, 105, 188, 143);
      case MedicineTakeStatus.skip:
        return const Color(0xFFE35D5D);
      case MedicineTakeStatus.snooze:
        return const Color(0xFFF0A24F);
      case MedicineTakeStatus.none:
        return const Color(0xFFB0B6C2);
    }
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

  String _quantityLabel() {
    final dose = item.dose;
    final unit = item.unit;
    if (dose != null && dose > 0) {
      final unitLabel = _mapUnitToThai(unit ?? '');
      return '$dose $unitLabel';
    }
    return '${item.amount} เม็ด';
  }

  @override
  Widget build(BuildContext context) {
    final row = Row(
      children: [
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x11000000),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                )
              ],
            ),
            child: Stack(
              children: [
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: 6,
                    decoration: BoxDecoration(
                      color: _statusBarColor(),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(14),
                        bottomLeft: Radius.circular(14),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.titleTh,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: _primary,
                              ),
                            ),
                          ),
                          Text(
                            _quantityLabel(),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: _primary,
                            ),
                          ),
                        ],
                      ),
                      if (item.titleEn.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          item.titleEn,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF6E7C8B),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      if (item.detail.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          item.detail,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF6E7C8B),
                          ),
                        ),
                      ],
                      if (item.status == MedicineTakeStatus.take) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(255, 230, 255, 245),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'กินแล้ว',
                            style: TextStyle(
                              color: Color.fromARGB(255, 55, 159, 114),
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                      if (item.status == MedicineTakeStatus.skip) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFE6E6),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'ข้าม',
                            style: TextStyle(
                              color: Color(0xFFC83C3C),
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                      if (item.status == MedicineTakeStatus.snooze) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF3E0),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'เลื่อนเตือน',
                            style: TextStyle(
                              color: Color(0xFFB26A1B),
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        InkWell(
          onTap: onTapComment,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFB7DAFF)),
              color: Colors.white,
            ),
            child: const Icon(Icons.chat_bubble_outline,
                color: _primary, size: 18),
          ),
        ),
      ],
    );

    if (!showTime) {
      return row;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            timeText,
            style: const TextStyle(
              fontSize: 14,
              color: _primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 4),
        row,
      ],
    );
  }
}
