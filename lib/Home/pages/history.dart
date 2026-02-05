// history.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:medibuddy/services/app_state.dart';
import 'package:medibuddy/services/log_api.dart';

/// ===============================
/// Models
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
class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  // UI state
  final TextEditingController _searchCtrl = TextEditingController();

  static const _filterAll = 'ทั้งหมด';
  static const _filterTaken = 'ทานแล้ว';
  static const _filterSkip = 'ข้าม';
  static const _filterSnooze = 'เลื่อนเตือน';
  static const _filterPending = 'ยังไม่ตอบ';

  static const _searchTrade = 'ชื่อการค้า';
  static const _searchTh = 'ชื่อสามัญไทย';
  static const _searchEn = 'ชื่อสามัญอังกฤษ';
  static const _searchNickname = 'ชื่อเล่นยา';

  String _filterValue = _filterAll;
  String _searchMode = _searchTrade;

  DateTime _startDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime _endDate = DateTime.now();
  bool _isDateFilterUserSet = false;

  bool _loading = false;
  String _errorMessage = '';

  List<MedicineHistoryItem> _allItems = [];
  List<MedicineHistoryItem> _filteredItems = [];

  @override
  void initState() {
    super.initState();
    _setDefaultDateRange();
    _loadHistory();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  /// ===============================
  /// Data + Mapping
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

    final medicineList = log['medicineList'] is Map
        ? Map<String, dynamic>.from(log['medicineList'] as Map)
        : <String, dynamic>{};
    final medicine = medicineList['medicine'] is Map
        ? Map<String, dynamic>.from(medicineList['medicine'] as Map)
        : <String, dynamic>{};

    final nickname = _readString(medicineList['mediNickname']);
    final trade = _readString(medicine['mediTradeName']);
    final th = _readString(medicine['mediThName']);
    final en = _readString(medicine['mediEnName']);

    final safeNickname = nickname.isNotEmpty ? nickname : '';
    final safeTrade = trade.isNotEmpty ? trade : '';
    final safeTh = th.isNotEmpty ? th : '';
    final safeEn = en.isNotEmpty ? en : '';

    final mainTitle = safeNickname.isNotEmpty
        ? safeNickname
        : (safeTrade.isNotEmpty
            ? safeTrade
            : (safeTh.isNotEmpty
                ? safeTh
                : (safeEn.isNotEmpty ? safeEn : '-')));

    final subtitle = safeTrade;

    final detailParts = <String>[];
    if (safeTh.isNotEmpty) detailParts.add(safeTh);
    if (safeEn.isNotEmpty) detailParts.add(safeEn);
    final detail = detailParts.isEmpty ? '' : detailParts.join('\n');

    final status = _statusFromResponse(_readString(log['responseStatus']));
    final amount = _resolveAmount(log);
    final dose = _resolveDose(log);
    final unit = _resolveUnit(log);
    final note = _readString(log['note']);

    return MedicineHistoryItem(
      takenAt: schedule ?? DateTime.now(),
      titleTh: mainTitle,
      titleEn: subtitle,
      detail: detail,
      amount: amount,
      dose: dose,
      unit: unit,
      status: status,
      note: note.isEmpty ? null : note,
      nickname: safeNickname,
      tradeName: safeTrade,
      thName: safeTh,
      enName: safeEn,
    );
  }

  Future<void> _loadHistory() async {
    final profileId = AppState.instance.currentProfileId;
    if (profileId == null || profileId <= 0) {
      setState(() {
        _errorMessage = 'ไม่พบข้อมูลโปรไฟล์';
        _allItems = [];
        _filteredItems = [];
      });
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = '';
    });

    try {
      final api = LogApiService();
      final logs = await api.getMedicationLogs(profileId: profileId);
      final items = logs.map(_mapLogToItem).toList();
      items.sort((a, b) => b.takenAt.compareTo(a.takenAt));

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
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  void _applyFilters() {
    if (!mounted) return;
    setState(() {
      _filteredItems = _filterItems(_allItems);
    });
  }

  /// ===============================
  /// Helpers
  /// ===============================
  void _setDefaultDateRange() {
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, now.day);
    _endDate = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
    _isDateFilterUserSet = false;
  }

  Future<void> _pickDate({required bool isStart}) async {
    final initial = isStart ? _startDate : _endDate;
    final firstDate = DateTime(2000);
    final lastDate = DateTime.now().add(const Duration(days: 365));

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: firstDate,
      lastDate: lastDate,
      locale: const Locale('th', 'TH'),
    );

    if (picked == null) return;

    setState(() {
      _isDateFilterUserSet = true;
      if (isStart) {
        _startDate = picked;
        if (_startDate.isAfter(_endDate)) {
          _endDate = _startDate;
        }
      } else {
        _endDate = picked;
        if (_endDate.isBefore(_startDate)) {
          _startDate = _endDate;
        }
      }
    });

    _applyFilters();
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

  bool _matchesStatus(MedicineTakeStatus status) {
    switch (_filterValue) {
      case _filterTaken:
        return status == MedicineTakeStatus.take;
      case _filterSkip:
        return status == MedicineTakeStatus.skip;
      case _filterSnooze:
        return status == MedicineTakeStatus.snooze;
      case _filterPending:
        return status == MedicineTakeStatus.none;
      case _filterAll:
      default:
        return true;
    }
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

  bool _isInDateRange(MedicineHistoryItem item) {
    final keyword = _searchCtrl.text.trim();
    if (keyword.isNotEmpty && !_isDateFilterUserSet) {
      return true;
    }

    final day =
        DateTime(item.takenAt.year, item.takenAt.month, item.takenAt.day);
    final start = DateTime(_startDate.year, _startDate.month, _startDate.day);
    final end = DateTime(_endDate.year, _endDate.month, _endDate.day);

    return !day.isBefore(start) && !day.isAfter(end);
  }

  List<MedicineHistoryItem> _filterItems(List<MedicineHistoryItem> items) {
    // final q = _searchCtrl.text.trim().toLowerCase();
    // final start = DateTime(_startDate.year, _startDate.month, _startDate.day);
    // final end = DateTime(_endDate.year, _endDate.month, _endDate.day);

    final filtered = items.where((item) {
      // final byFilter = _matchesStatus(item.status);
      // TODO: Status filtering disabled (search dropdown only).
      final inRange = _isInDateRange(item);
      final bySearch = _matchesKeyword(item);

      return inRange && bySearch;
    }).toList()
      ..sort((a, b) => b.takenAt.compareTo(a.takenAt));

    return filtered;
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

  Future<void> _exportPdf() async {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('TODO: Export PDF')),
    );
  }

  /// ===============================
  /// UI
  /// ===============================
  static const _primary = Color(0xFF1F497D);
  static const _lightBlue = Color(0xFFB7DAFF);
  static const _bg = Color(0xFFF3F6FB);

  @override
  Widget build(BuildContext context) {
    final pid = AppState.instance.currentProfileId;
    final items = _filteredItems;
    final grouped = _groupByDate(items);
    final dateKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      appBar: AppBar(
        backgroundColor: _primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pushReplacementNamed(
            context,
            '/home',
            arguments: {
              'profileId': pid,
              'profileName': AppState.instance.currentProfileName,
              'profileImage': AppState.instance.currentProfileImagePath,
            },
          ),
        ),
        title: const Text(
          'ประวัติ\nการรับประทานยา',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          textAlign: TextAlign.center,
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Export PDF',
            onPressed: _exportPdf,
            icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Toolbar: filter + search
            Container(
              color: _primary,
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
                  // TODO: Removed list icon per requirement (can re-enable later)
                  // const Icon(Icons.format_list_bulleted, color: Colors.white),
                  // const SizedBox(width: 8),
                  // TODO: Action/status filter dropdown disabled (will re-enable later).
                  // Container(
                  //   padding: const EdgeInsets.symmetric(horizontal: 10),
                  //   decoration: BoxDecoration(
                  //     color: Colors.white,
                  //     borderRadius: BorderRadius.circular(12),
                  //   ),
                  //   child: DropdownButtonHideUnderline(
                  //     child: DropdownButton<String>(
                  //       value: _filterValue,
                  //       items: const [
                  //         DropdownMenuItem(
                  //             value: _filterAll, child: Text(_filterAll)),
                  //         DropdownMenuItem(
                  //             value: _filterTaken, child: Text(_filterTaken)),
                  //         DropdownMenuItem(
                  //             value: _filterSkip, child: Text(_filterSkip)),
                  //         DropdownMenuItem(
                  //             value: _filterSnooze, child: Text(_filterSnooze)),
                  //         DropdownMenuItem(
                  //             value: _filterPending,
                  //             child: Text(_filterPending)),
                  //       ],
                  //       onChanged: (v) {
                  //         if (v == null) return;
                  //         _filterValue = v;
                  //         _applyFilters();
                  //       },
                  //     ),
                  //   ),
                  // ),
                  // const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _searchMode,
                        items: const [
                          DropdownMenuItem(
                              value: _searchTrade, child: Text(_searchTrade)),
                          DropdownMenuItem(
                              value: _searchTh, child: Text(_searchTh)),
                          DropdownMenuItem(
                              value: _searchEn, child: Text(_searchEn)),
                          DropdownMenuItem(
                              value: _searchNickname,
                              child: Text(_searchNickname)),
                        ],
                        onChanged: (v) {
                          if (v == null) return;
                          _searchMode = v;
                          _applyFilters();
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

            // Date range row
            Container(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
              child: Row(
                children: [
                  Expanded(
                    child: _DateField(
                      label: '',
                      value: DateFormat('d MMMM', 'th_TH').format(_startDate),
                      onTap: () => _pickDate(isStart: true),
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text('ถึง'),
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

            // List
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage.isNotEmpty
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
                                    // ...dayItems.map((it) => _HistoryRow(
                                    //       timeText: _formatTime(it.takenAt),
                                    //       item: it,
                                    //       onTapComment: () {
                                    //         ScaffoldMessenger.of(context)
                                    //             .showSnackBar(
                                    //           const SnackBar(
                                    //               content:
                                    //                   Text('TODO: เพิ่มคอมเมนต์')),
                                    //         );
                                    //       },
                                    //     )),
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
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(
                                                    const SnackBar(
                                                        content: Text(
                                                            'TODO: เพิ่มคอมเมนต์')),
                                                  );
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
    );
  }
}

/// ===============================
/// Widgets
/// ===============================
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
