// history.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// ===============================
/// Models (โครงข้อมูล)
/// ===============================
enum MedicineTakeStatus { normal, missed }

class MedicineHistoryItem {
  final DateTime takenAt; // วัน-เวลา ที่บันทึก
  final String titleTh; // ชื่อยาภาษาไทย (ชื่อเล่น)
  final String titleEn; // ชื่อยาอังกฤษ/ชื่อจาก DB
  final String detail; // รายละเอียด (เช่น paracetamol 500 mg)
  final int amount; // จำนวนเม็ด
  final MedicineTakeStatus status;
  final String? note;

  const MedicineHistoryItem({
    required this.takenAt,
    required this.titleTh,
    required this.titleEn,
    required this.detail,
    required this.amount,
    this.status = MedicineTakeStatus.normal,
    this.note,
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
  String _filterValue = 'ทั้งหมด';

  DateTime _startDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime _endDate = DateTime.now();

  bool _loading = false;

  // TODO: เปลี่ยนเป็นข้อมูลจาก API ตาม profileId + date range + filter
  late List<MedicineHistoryItem> _allItems;

  @override
  void initState() {
    super.initState();
    _allItems = _mockItems();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  /// ===============================
  /// Mock data
  /// ===============================
  List<MedicineHistoryItem> _mockItems() {
    final now = DateTime.now();
    return [
      MedicineHistoryItem(
        takenAt: DateTime(now.year, now.month, now.day, 12, 23),
        titleTh: 'Tylenol 500',
        titleEn: 'TYLENOL 500 (paracetamol 500 mg)',
        detail: 'พาราเซตามอล\nParacetamol',
        amount: 1,
      ),
      MedicineHistoryItem(
        takenAt: DateTime(now.year, now.month, now.day - 1, 11, 50),
        titleTh: 'ยาแก้แพ้',
        titleEn: 'KENYAMINE (dexchlorpheniramine maleate 2 mg)',
        detail: 'เดกซ์คลอเฟนิรามีน มาเลเอต\nDexchlorpheniramine maleate',
        amount: 2,
      ),
      MedicineHistoryItem(
        takenAt: DateTime(now.year, now.month, now.day - 1, 11, 50),
        titleTh: 'ยาลดอักเสบ',
        titleEn: 'ASPIRIN CARDIO 100 (aspirin 100 mg)',
        detail: 'แอสไพริน\nAspirin',
        amount: 1,
      ),
      MedicineHistoryItem(
        takenAt: DateTime(now.year, now.month, now.day - 1, 8, 5),
        titleTh: 'ยาลดน้ำมูก',
        titleEn: 'CETTEC (cetirizine hydrochloride 1 mg/1 mL)',
        detail: 'ซิเทอริซีน\nCetirizine',
        amount: 1,
        status: MedicineTakeStatus.missed,
      ),
    ];
  }

  /// ===============================
  /// Helpers
  /// ===============================
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
      if (isStart) {
        _startDate = picked;
        // กัน start > end
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

    // TODO: เรียกโหลดข้อมูลใหม่จาก API
    // await _loadHistory();
  }

  String _formatThaiDate(DateTime d) {
    // ตัวอย่าง: "อ. 21 ม.ค. 2025"
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
    // "12 : 23 น."
    final hh = d.hour.toString().padLeft(2, '0');
    final mm = d.minute.toString().padLeft(2, '0');
    return '$hh : $mm น.';
  }

  List<MedicineHistoryItem> _filteredItems() {
    final q = _searchCtrl.text.trim().toLowerCase();

    return _allItems.where((item) {
      // date range (inclusive)
      final day =
          DateTime(item.takenAt.year, item.takenAt.month, item.takenAt.day);
      final start = DateTime(_startDate.year, _startDate.month, _startDate.day);
      final end = DateTime(_endDate.year, _endDate.month, _endDate.day);

      final inRange = !day.isBefore(start) && !day.isAfter(end);

      // filter (โครง)
      final byFilter = _filterValue == 'ทั้งหมด'
          ? true
          : (_filterValue == 'ข้าม'
              ? item.status == MedicineTakeStatus.missed
              : true);

      // search
      final bySearch = q.isEmpty
          ? true
          : (item.titleTh.toLowerCase().contains(q) ||
              item.titleEn.toLowerCase().contains(q) ||
              item.detail.toLowerCase().contains(q));

      return inRange && byFilter && bySearch;
    }).toList()
      ..sort((a, b) => b.takenAt.compareTo(a.takenAt)); // ล่าสุดบน
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
    // TODO: ทำ export PDF (เช่นใช้ pdf + printing package) หรือเรียก backend generate
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('TODO: Export PDF')),
    );
  }

  Future<void> _loadHistory() async {
    // TODO: เรียก API ด้วย profileId + date range + filter + search
    setState(() => _loading = true);
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      // setState(() => _allItems = fetchedItems);
    } finally {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  /// ===============================
  /// UI
  /// ===============================
  static const _primary = Color(0xFF1F497D);
  static const _lightBlue = Color(0xFFB7DAFF);
  static const _bg = Color(0xFFF3F6FB);

  @override
  Widget build(BuildContext context) {
    final items = _filteredItems();
    final grouped = _groupByDate(items);
    final dateKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return Scaffold(
      backgroundColor: _bg,
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
                  // icon list
                  const Icon(Icons.format_list_bulleted, color: Colors.white),
                  const SizedBox(width: 8),

                  // filter dropdown
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _filterValue,
                        items: const [
                          DropdownMenuItem(
                              value: 'ทั้งหมด', child: Text('ทั้งหมด')),
                          DropdownMenuItem(value: 'ข้าม', child: Text('ข้าม')),
                        ],
                        onChanged: (v) {
                          if (v == null) return;
                          setState(() => _filterValue = v);
                          // TODO: ถ้าอยากให้ filter เรียก API ก็เรียก _loadHistory()
                        },
                      ),
                    ),
                  ),

                  const SizedBox(width: 10),

                  // search
                  Expanded(
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextField(
                        controller: _searchCtrl,
                        onChanged: (_) => setState(() {}),
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
                      label: 'เริ่มต้น :',
                      value: DateFormat('d MMMM', 'th_TH').format(_startDate),
                      onTap: () => _pickDate(isStart: true),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _DateField(
                      label: 'สิ้นสุด :',
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
                  : items.isEmpty
                      ? const Center(
                          child: Text('ไม่มีประวัติในช่วงวันที่ที่เลือก'))
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                          itemCount: dateKeys.length,
                          itemBuilder: (context, i) {
                            final dayKey = dateKeys[i];
                            final dayItems = grouped[dayKey]!
                              ..sort((a, b) => b.takenAt.compareTo(a.takenAt));

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 8),
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 6),
                                  child: Text(
                                    _formatThaiDate(dayKey),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: _primary,
                                    ),
                                  ),
                                ),
                                ...dayItems.map((it) => _HistoryRow(
                                      timeText: _formatTime(it.takenAt),
                                      item: it,
                                      onTapComment: () {
                                        // TODO: เปิด dialog ใส่ note/comment
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                              content:
                                                  Text('TODO: เพิ่มคอมเมนต์')),
                                        );
                                      },
                                    )),
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

  const _HistoryRow({
    required this.timeText,
    required this.item,
    required this.onTapComment,
  });

  static const _primary = Color(0xFF1F497D);

  Color _statusBarColor() {
    if (item.status == MedicineTakeStatus.missed) {
      return const Color(0xFFE35D5D); // แดง
    }
    return const Color(0xFF5FB0D7); // ฟ้า
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // time
        SizedBox(
          width: 76,
          child: Text(
            timeText,
            style: const TextStyle(
              fontSize: 14,
              color: _primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 8),

        // card
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
                // status bar
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
                      // title row
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
                            '${item.amount} เม็ด',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: _primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      Text(
                        item.titleEn,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6E7C8B),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),

                      Text(
                        item.detail,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6E7C8B),
                        ),
                      ),

                      if (item.status == MedicineTakeStatus.missed) ...[
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
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(width: 8),

        // comment icon
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
  }
}
