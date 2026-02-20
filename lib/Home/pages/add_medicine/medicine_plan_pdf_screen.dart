import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/intl.dart';
import 'package:medibuddy/Model/medicine_regimen_model.dart';
import 'package:medibuddy/services/app_state.dart';
import 'package:medibuddy/services/regimen_api.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class MedicationPlanScreen extends StatefulWidget {
  final int profileId;

  const MedicationPlanScreen({
    super.key,
    required this.profileId,
  });

  @override
  State<MedicationPlanScreen> createState() => _MedicationPlanScreenState();
}

enum _SearchField {
  all,
  nickname,
  thName,
  enName,
}

class _MedicationPlanScreenState extends State<MedicationPlanScreen> {
  final RegimenApiService _api = RegimenApiService();
  final TextEditingController _keywordController = TextEditingController();

  late DateTime _startDate;
  late DateTime _endDate;
  bool _loading = false;
  bool _exporting = false;
  String? _error;

  _SearchField _searchField = _SearchField.all;
  List<MedicineRegimenItem> _items = [];
  List<_PlanGroup> _groups = [];
  List<_PlanGroup> _displayGroups = [];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, now.day);
    _endDate = DateTime(now.year, now.month, now.day);
    _fetchPlans();
  }

  @override
  void dispose() {
    _keywordController.dispose();
    super.dispose();
  }

  Future<void> _fetchPlans() async {
    if (widget.profileId <= 0) {
      setState(() {
        _error = 'ไม่พบโปรไฟล์ผู้ใช้';
        _items = [];
        _groups = [];
        _displayGroups = [];
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    final rangeStart =
        DateTime(_startDate.year, _startDate.month, _startDate.day);
    final rangeEnd = DateTime(
      _endDate.year,
      _endDate.month,
      _endDate.day,
      23,
      59,
      59,
      999,
    );

    try {
      final res = await _api.getAllRegimens(
        profileId: widget.profileId,
        startDate: rangeStart,
        endDate: rangeEnd,
      );
      if (!mounted) return;

      final filtered = res.items
          .where((item) => _overlapsRange(item, rangeStart, rangeEnd))
          .toList();
      final groups = _buildGroups(filtered);
      final displayGroups = _filterGroups(groups);

      setState(() {
        _items = filtered;
        _groups = groups;
        _displayGroups = displayGroups;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _items = [];
        _groups = [];
        _displayGroups = [];
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  bool _overlapsRange(
    MedicineRegimenItem item,
    DateTime rangeStart,
    DateTime rangeEnd,
  ) {
    final start = _tryParseDate(item.startDate);
    if (start == null) return true;
    final end = _tryParseDate(item.endDate) ?? start;
    return !end.isBefore(rangeStart) && !start.isAfter(rangeEnd);
  }

  DateTime? _tryParseDate(String? value) {
    if (value == null) return null;
    final raw = value.trim();
    if (raw.isEmpty) return null;
    final parsed = DateTime.tryParse(raw);
    return parsed?.toLocal();
  }

  List<_PlanGroup> _buildGroups(List<MedicineRegimenItem> items) {
    final grouped = <int, _PlanGroupAccumulator>{};

    for (final item in items) {
      final list = item.medicineList;
      final medicine = list?.medicine;
      final nickname = (list?.mediNickname ?? '').trim();
      final thName = (medicine?.mediThName ?? '').trim();
      final enName = (medicine?.mediEnName ?? '').trim();
      final displayName = _resolveDisplayName(
        nickname: nickname,
        thName: thName,
        enName: enName,
      );
      final subName = _resolveSubName(
        displayName: displayName,
        thName: thName,
        enName: enName,
      );
      final pictureOption = (list?.pictureOption ?? '').trim();
      final imagePath = pictureOption.isNotEmpty
          ? pictureOption
          : (medicine?.mediPicture ?? '');

      final acc = grouped.putIfAbsent(
        item.mediListId,
        () => _PlanGroupAccumulator(
          mediListId: item.mediListId,
          nickname: nickname,
          thName: thName,
          enName: enName,
          displayName: displayName,
          subName: subName,
          imagePath: imagePath,
        ),
      );

      acc.updateDates(
        start: _tryParseDate(item.startDate),
        end: _tryParseDate(item.endDate),
      );

      for (final time in item.times) {
        acc.times.add(
          _PlanTime(
            time: _normalizeTime(time.time),
            dose: _formatDose(time.dose),
            unit: _mapUnitToThai(time.unit),
          ),
        );
      }
    }

    final result = <_PlanGroup>[];
    for (final acc in grouped.values) {
      final times = List<_PlanTime>.from(acc.times);
      times.sort((a, b) => _compareTime(a.time, b.time));
      result.add(
        _PlanGroup(
          mediListId: acc.mediListId,
          nickname: acc.nickname,
          thName: acc.thName,
          enName: acc.enName,
          displayName: acc.displayName,
          subName: acc.subName,
          imagePath: acc.imagePath,
          startDate: acc.startDate,
          endDate: acc.endDate,
          times: times,
        ),
      );
    }

    return result;
  }

  String _resolveDisplayName({
    required String nickname,
    required String thName,
    required String enName,
  }) {
    if (nickname.isNotEmpty) return nickname;
    if (thName.isNotEmpty) return thName;
    if (enName.isNotEmpty) return enName;
    return 'ไม่ทราบชื่อยา';
  }

  String? _resolveSubName({
    required String displayName,
    required String thName,
    required String enName,
  }) {
    if (thName.isNotEmpty && thName != displayName) return thName;
    if (enName.isNotEmpty && enName != displayName) return enName;
    return null;
  }

  List<_PlanGroup> _filterGroups(List<_PlanGroup> groups) {
    final keyword = _keywordController.text.trim().toLowerCase();
    if (keyword.isEmpty) return groups;

    return groups.where((group) {
      switch (_searchField) {
        case _SearchField.nickname:
          return group.nickname.toLowerCase().contains(keyword);
        case _SearchField.thName:
          return group.thName.toLowerCase().contains(keyword);
        case _SearchField.enName:
          return group.enName.toLowerCase().contains(keyword);
        case _SearchField.all:
        default:
          return group.nickname.toLowerCase().contains(keyword) ||
              group.thName.toLowerCase().contains(keyword) ||
              group.enName.toLowerCase().contains(keyword);
      }
    }).toList();
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() {
      _startDate = DateTime(picked.year, picked.month, picked.day);
      if (_endDate.isBefore(_startDate)) {
        _endDate = _startDate;
      }
    });
  }

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() {
      _endDate = DateTime(picked.year, picked.month, picked.day);
      if (_endDate.isBefore(_startDate)) {
        _startDate = _endDate;
      }
    });
  }

  Future<void> _exportPdf() async {
    if (_exporting) return;
    if (_displayGroups.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ไม่มีข้อมูลสำหรับส่งออก')),
      );
      return;
    }

    setState(() => _exporting = true);
    try {
      final bytes = await _buildMedicationPlanPdf(_displayGroups);
      await Printing.sharePdf(
        bytes: bytes,
        filename: 'medication_plan.pdf',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ส่งออกไม่สำเร็จ: $e')),
      );
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<Uint8List> _buildMedicationPlanPdf(List<_PlanGroup> groups) async {
    final fontData =
        await rootBundle.load('assets/fonts/Kodchasan-Regular.ttf');
    final boldData = await rootBundle.load('assets/fonts/Kodchasan-Bold.ttf');
    final baseFont = pw.Font.ttf(fontData);
    final boldFont = pw.Font.ttf(boldData);

    final profileName = (AppState.instance.currentProfileName ?? '').trim();
    final displayProfile = profileName.isNotEmpty ? profileName : 'ผู้ใช้';
    final dateRangeText = _formatRangeText(_startDate, _endDate);

    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) {
          final widgets = <pw.Widget>[
            pw.Text(
              'แผนการรับประทานยา',
              style: pw.TextStyle(
                font: boldFont,
                fontSize: 20,
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Text(
              'ผู้ใช้: $displayProfile',
              style: pw.TextStyle(font: baseFont, fontSize: 12),
            ),
            pw.Text(
              'ช่วงวันที่: $dateRangeText',
              style: pw.TextStyle(font: baseFont, fontSize: 12),
            ),
            pw.SizedBox(height: 16),
          ];

          for (final group in groups) {
            final rangeText = _rangeText(group.startDate, group.endDate);
            widgets.addAll([
              pw.Text(
                'ยา: ${group.displayName}',
                style: pw.TextStyle(font: boldFont, fontSize: 14),
              ),
              if (group.subName != null && group.subName!.isNotEmpty)
                pw.Text(
                  'ชื่อสามัญ: ${group.subName}',
                  style: pw.TextStyle(font: baseFont, fontSize: 12),
                ),
              if (rangeText.isNotEmpty)
                pw.Text(
                  rangeText,
                  style: pw.TextStyle(font: baseFont, fontSize: 12),
                ),
              pw.SizedBox(height: 4),
              ...group.times.map(
                (time) => pw.Text(
                  'เวลา ${time.time} น. ปริมาณ ${time.dose} ${time.unit}',
                  style: pw.TextStyle(font: baseFont, fontSize: 12),
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Divider(),
              pw.SizedBox(height: 8),
            ]);
          }

          return widgets;
        },
      ),
    );

    return pdf.save();
  }

  String _formatRangeText(DateTime start, DateTime end) {
    final startText = _formatDate(start);
    final endText = _formatDate(end);
    if (startText == endText) return startText;
    return '$startText - $endText';
  }

  String _rangeText(DateTime? start, DateTime? end) {
    if (start == null) return '';
    final startText = _formatDate(start);
    if (end == null) return 'เริ่ม $startText';
    final endText = _formatDate(end);
    if (startText == endText) return 'เริ่ม $startText';
    return 'ช่วงวันที่ $startText - $endText';
  }

  String _formatDate(DateTime date) {
    return DateFormat('d MMM yyyy', 'th').format(date);
  }

  String _normalizeTime(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return '--:--';
    final parts = trimmed.split(':');
    if (parts.length < 2) return trimmed;
    final hour = parts[0].padLeft(2, '0');
    final minute = parts[1].padLeft(2, '0');
    return '$hour:$minute';
  }

  String _formatDose(num dose) {
    if (dose % 1 == 0) return dose.toInt().toString();
    return dose.toString();
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

  int _timeToMinutes(String value) {
    final parts = value.split(':');
    if (parts.length < 2) return 0;
    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = int.tryParse(parts[1]) ?? 0;
    return (hour.clamp(0, 23) * 60) + minute.clamp(0, 59);
  }

  int _compareTime(String a, String b) {
    final aMinutes = _timeToMinutes(a);
    final bMinutes = _timeToMinutes(b);
    final cmp = aMinutes.compareTo(bMinutes);
    if (cmp != 0) return cmp;
    return a.compareTo(b);
  }

  String _searchLabel(_SearchField field) {
    switch (field) {
      case _SearchField.nickname:
        return 'ชื่อเล่นยา';
      case _SearchField.thName:
        return 'ชื่อสามัญไทย';
      case _SearchField.enName:
        return 'ชื่อสามัญอังกฤษ';
      case _SearchField.all:
      default:
        return 'ทั้งหมด';
    }
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

  ImageProvider? _buildMedicineImage(String path) {
    final p = path.trim();
    if (p.isEmpty || p.toLowerCase() == 'null') return null;

    if (p.startsWith('http://') || p.startsWith('https://')) {
      return NetworkImage(p);
    }

    if (p.startsWith('/uploads') || p.startsWith('uploads')) {
      final url = _toFullImageUrl(p);
      if (url.isEmpty) return null;
      return NetworkImage(url);
    }

    final maybeUrl = _toFullImageUrl(p);
    if (maybeUrl.isNotEmpty) return NetworkImage(maybeUrl);

    return null;
  }

  Widget _buildDatePicker({
    required String label,
    required DateTime date,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFD6E3F3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today,
                size: 18, color: Color(0xFF1F497D)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${_formatDate(date)}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF1F497D),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupCard(_PlanGroup group) {
    final imageProvider = _buildMedicineImage(group.imagePath);
    final rangeText = _rangeText(group.startDate, group.endDate);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F4F8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD6E3F3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFFE3EAF6),
                  borderRadius: BorderRadius.circular(12),
                  image: imageProvider != null
                      ? DecorationImage(image: imageProvider, fit: BoxFit.cover)
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
                      group.displayName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (group.subName != null && group.subName!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        group.subName!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B7C93),
                        ),
                      ),
                    ],
                    if (rangeText.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        rangeText,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B7C93),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (group.times.isEmpty)
            const Text(
              'ไม่มีข้อมูลเวลา',
              style: TextStyle(color: Color(0xFF6B7C93), fontSize: 12),
            )
          else
            Column(
              children: group.times.map((time) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 80,
                        child: Text(
                          '${time.time} น.',
                          style: const TextStyle(
                            color: Color(0xFF1F497D),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'ปริมาณ ${time.dose} ${time.unit}',
                          textAlign: TextAlign.end,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFB7DAFF),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFF1F497D)),
        title: const Text(
          'แผนการรับประทานยา',
          style: TextStyle(
            color: Color(0xFF1F497D),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      backgroundColor: const Color(0xFFEFF6FF),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxWidth = constraints.maxWidth;
            final containerWidth = maxWidth > 600 ? 560.0 : maxWidth;

            return Align(
              alignment: Alignment.topCenter,
              child: SizedBox(
                width: containerWidth,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: maxWidth * 0.02,
                    vertical: maxWidth * 0.02,
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.06),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: DropdownButtonFormField<_SearchField>(
                                    value: _searchField,
                                    decoration: InputDecoration(
                                      filled: true,
                                      fillColor: const Color(0xFFF2F4F8),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                        horizontal: 2,
                                        vertical: 8,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide.none,
                                      ),
                                    ),
                                    items: _SearchField.values
                                        .map(
                                          (field) => DropdownMenuItem(
                                            value: field,
                                            child: Text(_searchLabel(field)),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (value) {
                                      if (value == null) return;
                                      setState(() => _searchField = value);
                                    },
                                  ),
                                ),
                                const SizedBox(width: 3),
                                Expanded(
                                  flex: 2,
                                  child: TextField(
                                    controller: _keywordController,
                                    decoration: InputDecoration(
                                      hintText: 'ค้นหาชื่อยา',
                                      filled: true,
                                      fillColor: const Color(0xFFF2F4F8),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide.none,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildDatePicker(
                                    label: '',
                                    date: _startDate,
                                    onTap: _pickStartDate,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'ถึง',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _buildDatePicker(
                                    label: '',
                                    date: _endDate,
                                    onTap: _pickEndDate,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _loading ? null : _fetchPlans,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1F497D),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                                child: const Text(
                                  'ค้นหา',
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 16),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: _loading
                              ? const Center(
                                  child: CircularProgressIndicator(),
                                )
                              : _error != null
                                  ? Center(
                                      child: Text(
                                        _error!,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          color: Color(0xFF8893A0),
                                        ),
                                      ),
                                    )
                                  : _displayGroups.isEmpty
                                      ? const Center(
                                          child: Text(
                                            'ไม่พบแผนการรับประทานยา',
                                            style: TextStyle(
                                              color: Color(0xFF8893A0),
                                            ),
                                          ),
                                        )
                                      : ListView.builder(
                                          itemCount: _displayGroups.length,
                                          itemBuilder: (context, index) =>
                                              _buildGroupCard(
                                                  _displayGroups[index]),
                                        ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _exporting ? null : _exportPdf,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1F497D),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                          child: _exporting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'ส่งออก',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _PlanGroupAccumulator {
  final int mediListId;
  final String nickname;
  final String thName;
  final String enName;
  final String displayName;
  final String? subName;
  final String imagePath;
  final List<_PlanTime> times = [];
  DateTime? startDate;
  DateTime? endDate;

  _PlanGroupAccumulator({
    required this.mediListId,
    required this.nickname,
    required this.thName,
    required this.enName,
    required this.displayName,
    required this.subName,
    required this.imagePath,
  });

  void updateDates({DateTime? start, DateTime? end}) {
    if (start != null) {
      if (startDate == null || start.isBefore(startDate!)) {
        startDate = start;
      }
    }
    if (end != null) {
      if (endDate == null || end.isAfter(endDate!)) {
        endDate = end;
      }
    }
  }
}

class _PlanGroup {
  final int mediListId;
  final String nickname;
  final String thName;
  final String enName;
  final String displayName;
  final String? subName;
  final String imagePath;
  final DateTime? startDate;
  final DateTime? endDate;
  final List<_PlanTime> times;

  const _PlanGroup({
    required this.mediListId,
    required this.nickname,
    required this.thName,
    required this.enName,
    required this.displayName,
    required this.subName,
    required this.imagePath,
    required this.startDate,
    required this.endDate,
    required this.times,
  });
}

class _PlanTime {
  final String time;
  final String dose;
  final String unit;

  const _PlanTime({
    required this.time,
    required this.dose,
    required this.unit,
  });
}
