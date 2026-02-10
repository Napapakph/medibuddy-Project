import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:medibuddy/services/auth_session.dart';
import 'package:medibuddy/services/follow_api.dart';

// ===== Models =====
enum _MedTakeStatus { take, skip, snooze, none }

class _MedHistoryItem {
  final DateTime takenAt;
  final String medicineName;
  final int dose;
  final String unit;
  final _MedTakeStatus status;

  const _MedHistoryItem({
    required this.takenAt,
    required this.medicineName,
    required this.dose,
    required this.unit,
    required this.status,
  });
}

// ===== Page =====
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
  String _imageBaseUrl = '';

  static const _searchTrade = 'ชื่อยา';
  String _searchMode = _searchTrade;

  DateTime _startDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime _endDate = DateTime.now();
  bool _isDateFilterUserSet = false;

  bool _loading = false;
  String _errorMessage = '';

  List<_MedHistoryItem> _allItems = [];
  List<_MedHistoryItem> _filteredItems = [];

  @override
  void initState() {
    super.initState();
    _imageBaseUrl = dotenv.env['API_BASE_URL'] ?? '';
    _setDefaultDateRange();
    _loadHistory();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
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

  // ===== Data =====
  _MedTakeStatus _statusFromResponse(String? status) {
    switch ((status ?? '').toUpperCase()) {
      case 'TAKE':
        return _MedTakeStatus.take;
      case 'SKIP':
        return _MedTakeStatus.skip;
      case 'SNOOZE':
        return _MedTakeStatus.snooze;
      default:
        return _MedTakeStatus.none;
    }
  }

  _MedHistoryItem _mapLogToItem(Map<String, dynamic> log) {
    final scheduleRaw = (log['scheduleTime'] ?? '').toString();
    final schedule = scheduleRaw.isEmpty
        ? DateTime.now()
        : (DateTime.tryParse(scheduleRaw)?.toLocal() ?? DateTime.now());

    final medicineName = (log['medicineName'] ?? 'ไม่ทราบชื่อยา').toString();
    final dose = (log['dose'] is int)
        ? log['dose'] as int
        : int.tryParse(log['dose'].toString()) ?? 1;
    final unit = (log['unit'] ?? 'tablet').toString();
    final status = _statusFromResponse(
      (log['responseStatus'] ?? '').toString(),
    );

    return _MedHistoryItem(
      takenAt: schedule,
      medicineName: medicineName,
      dose: dose,
      unit: unit,
      status: status,
    );
  }

  Future<void> _loadHistory() async {
    final accessToken = AuthSession.accessToken;
    if (accessToken == null) {
      setState(() => _errorMessage = 'ไม่พบข้อมูลเข้าสู่ระบบ');
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = '';
    });

    try {
      final startStr = DateFormat('yyyy-MM-dd').format(_startDate);
      final endStr = DateFormat('yyyy-MM-dd').format(_endDate);

      final logs = await _followApi.fetchFollowingLogs(
        accessToken: accessToken,
        relationshipId: widget.relationshipId,
        profileId: widget.profileId,
        startDate: startStr,
        endDate: endStr,
      );
      final items = logs.map(_mapLogToItem).toList()
        ..sort((a, b) => b.takenAt.compareTo(a.takenAt));

      if (!mounted) return;
      setState(() {
        _allItems = items;
        _filteredItems = _filterItems(items);
      });
    } catch (e) {
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

  List<_MedHistoryItem> _filterItems(List<_MedHistoryItem> items) {
    return items.where((item) {
      final inRange = _isInDateRange(item);
      final bySearch = _matchesKeyword(item);
      return inRange && bySearch;
    }).toList()
      ..sort((a, b) => b.takenAt.compareTo(a.takenAt));
  }

  bool _isInDateRange(_MedHistoryItem item) {
    final keyword = _searchCtrl.text.trim();
    if (keyword.isNotEmpty && !_isDateFilterUserSet) return true;

    final day =
        DateTime(item.takenAt.year, item.takenAt.month, item.takenAt.day);
    final start = DateTime(_startDate.year, _startDate.month, _startDate.day);
    final end = DateTime(_endDate.year, _endDate.month, _endDate.day);
    return !day.isBefore(start) && !day.isAfter(end);
  }

  bool _matchesKeyword(_MedHistoryItem item) {
    final keyword = _searchCtrl.text.trim().toLowerCase();
    if (keyword.isEmpty) return true;
    return item.medicineName.toLowerCase().contains(keyword);
  }

  Map<DateTime, List<_MedHistoryItem>> _groupByDate(
      List<_MedHistoryItem> items) {
    final map = <DateTime, List<_MedHistoryItem>>{};
    for (final it in items) {
      final key = DateTime(it.takenAt.year, it.takenAt.month, it.takenAt.day);
      map.putIfAbsent(key, () => []).add(it);
    }
    return map;
  }

  // ===== Helpers =====
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
    const days = ['จ.', 'อ.', 'พ.', 'พฤ.', 'ศ.', 'ส.', 'อา.'];
    return days[(weekday - 1) % 7];
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

  String _mapUnitToThai(String unit) {
    switch (unit.trim().toLowerCase()) {
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

  // ===== UI =====
  static const _primary = Color(0xFF1F497D);

  @override
  Widget build(BuildContext context) {
    final items = _filteredItems;
    final grouped = _groupByDate(items);
    final dateKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));
    final ownerAvatar = _buildProfileImage(widget.ownerImage);

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
                              widget.ownerName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'โปรไฟล์: ${widget.profileName}',
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

                // ===== Search bar =====
                Container(
                  color: _primary,
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  child: Row(
                    children: [
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
                              hintText: 'ค้นหาชื่อยา...',
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
                                    <String, List<_MedHistoryItem>>{};
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
                                      final tKey = entry.key;
                                      final groupItems = entry.value;
                                      return Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.only(
                                                top: 8, bottom: 4),
                                            child: Text(
                                              '$tKey น.',
                                              style: const TextStyle(
                                                fontSize: 14,
                                                color: _primary,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                          ...groupItems.map(
                                              (it) => _buildHistoryRow(it)),
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

  Widget _buildHistoryRow(_MedHistoryItem item) {
    Color statusBarColor;
    switch (item.status) {
      case _MedTakeStatus.take:
        statusBarColor = const Color.fromARGB(255, 105, 188, 143);
        break;
      case _MedTakeStatus.skip:
        statusBarColor = const Color(0xFFE35D5D);
        break;
      case _MedTakeStatus.snooze:
        statusBarColor = const Color(0xFFF0A24F);
        break;
      case _MedTakeStatus.none:
        statusBarColor = const Color(0xFFB0B6C2);
        break;
    }

    final unitLabel = _mapUnitToThai(item.unit);
    final quantityLabel = '${item.dose} $unitLabel';

    String? statusLabel;
    Color? statusLabelColor;
    Color? statusBgColor;
    switch (item.status) {
      case _MedTakeStatus.take:
        statusLabel = 'กินแล้ว';
        statusLabelColor = const Color.fromARGB(255, 55, 159, 114);
        statusBgColor = const Color.fromARGB(255, 230, 255, 245);
        break;
      case _MedTakeStatus.skip:
        statusLabel = 'ข้าม';
        statusLabelColor = const Color(0xFFC83C3C);
        statusBgColor = const Color(0xFFFFE6E6);
        break;
      case _MedTakeStatus.snooze:
        statusLabel = 'เลื่อนเตือน';
        statusLabelColor = const Color(0xFFB26A1B);
        statusBgColor = const Color(0xFFFFF3E0);
        break;
      case _MedTakeStatus.none:
        statusLabel = null;
        break;
    }

    return Row(
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
                ),
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
                      color: statusBarColor,
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
                              item.medicineName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: _primary,
                              ),
                            ),
                          ),
                          Text(
                            quantityLabel,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: _primary,
                            ),
                          ),
                        ],
                      ),
                      if (statusLabel != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusBgColor,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            statusLabel,
                            style: TextStyle(
                              color: statusLabelColor,
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
      ],
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
