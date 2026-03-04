import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:lottie/lottie.dart';
import 'package:intl/intl.dart';
import 'package:medibuddy/services/auth_manager.dart';
import 'package:medibuddy/services/follow_api.dart';

class FollowingRegimenPage extends StatefulWidget {
  final int relationshipId;
  final int profileId;
  final String profileName;
  final String ownerName;
  final String? ownerImage;

  const FollowingRegimenPage({
    super.key,
    required this.relationshipId,
    required this.profileId,
    required this.profileName,
    required this.ownerName,
    this.ownerImage,
  });

  @override
  State<FollowingRegimenPage> createState() => _FollowingRegimenPageState();
}

class _FollowingRegimenPageState extends State<FollowingRegimenPage> {
  final _followApi = FollowApi();
  final _searchCtrl = TextEditingController();

  static const _searchTrade = 'ชื่อการค้า';
  static const _searchTh = 'ชื่อสามัญไทย';
  static const _searchEn = 'ชื่อสามัญอังกฤษ';
  static const _searchNickname = 'ชื่อเล่นยา';

  String _imageBaseUrl = '';
  String _searchMode = _searchTrade;

  bool _loading = false;
  String _errorMessage = '';

  List<Map<String, dynamic>> _allRegimens = [];
  List<Map<String, dynamic>> _filteredRegimens = [];

  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 7));

  // State for header info
  String _ownerName = '';
  String _ownerImage = '';
  String _profileLabel = '';

  @override
  void initState() {
    super.initState();
    _imageBaseUrl = dotenv.env['API_BASE_URL'] ?? '';
    _ownerName = widget.ownerName;
    _ownerImage = widget.ownerImage ?? '';
    _profileLabel = widget.profileName;

    _loadData();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

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

  Future<void> _loadData() async {
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

      // 2. Fetch Regimen list
      debugPrint(
          'Fetching regimens for relationshipId=${widget.relationshipId}');
      final regimens = await _followApi.fetchFollowingRegimen(
        accessToken: accessToken,
        relationshipId: widget.relationshipId,
        profileId: widget.profileId,
      );

      debugPrint('Regimens received: ${regimens.length}');

      if (!mounted) return;
      setState(() {
        _allRegimens = regimens;
        _filteredRegimens = _filterItems(regimens);
      });
    } catch (e) {
      debugPrint('Error loading regimens: $e');
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _allRegimens = [];
        _filteredRegimens = [];
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
  void _applyFilters() {
    if (!mounted) return;
    setState(() => _filteredRegimens = _filterItems(_allRegimens));
  }

  bool _isInDateRange(Map<String, dynamic> item) {
    final itemStartStr = _readString(item['startDate']);
    final itemEndStr = _readString(item['endDate']);

    DateTime? itemStart;
    DateTime? itemEnd;

    if (itemStartStr.isNotEmpty)
      itemStart = DateTime.tryParse(itemStartStr)?.toLocal();
    if (itemEndStr.isNotEmpty)
      itemEnd = DateTime.tryParse(itemEndStr)?.toLocal();

    if (itemStart == null)
      return true; // If no start date, consider it always active

    final startRange =
        DateTime(_startDate.year, _startDate.month, _startDate.day);
    final endRange =
        DateTime(_endDate.year, _endDate.month, _endDate.day, 23, 59, 59);

    final rStart = DateTime(itemStart.year, itemStart.month, itemStart.day);
    DateTime? rEnd;
    if (itemEnd != null) {
      rEnd = DateTime(itemEnd.year, itemEnd.month, itemEnd.day, 23, 59, 59);
    }

    if (rStart.isAfter(endRange)) return false;
    if (rEnd != null && rEnd.isBefore(startRange)) return false;

    return true;
  }

  List<Map<String, dynamic>> _filterItems(List<Map<String, dynamic>> items) {
    return items.where((item) {
      if (!_matchesKeyword(item)) return false;
      if (!_isInDateRange(item)) return false;
      return true;
    }).toList();
  }

  bool _matchesKeyword(Map<String, dynamic> item) {
    final keyword = _searchCtrl.text.trim().toLowerCase();
    if (keyword.isEmpty) return true;

    final medInfo = item['medicine'] ?? {};
    final nickname = _readString(item['mediNickname']).toLowerCase();
    final tradeName = _readString(medInfo['mediTradeName']).toLowerCase();
    final thName = _readString(medInfo['mediThName']).toLowerCase();
    final enName = _readString(medInfo['mediEnName']).toLowerCase();

    switch (_searchMode) {
      case _searchTrade:
        return tradeName.isNotEmpty && tradeName.contains(keyword);
      case _searchTh:
        return thName.isNotEmpty && thName.contains(keyword);
      case _searchEn:
        return enName.isNotEmpty && enName.contains(keyword);
      case _searchNickname:
        return nickname.isNotEmpty && nickname.contains(keyword);
      default:
        return false;
    }
  }

  Future<void> _pickDate({required bool isStart}) async {
    final now = DateTime.now();
    final firstDate = DateTime(now.year, now.month, now.day);

    DateTime initial = isStart ? _startDate : _endDate;
    if (initial.isBefore(firstDate)) {
      initial = firstDate;
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: firstDate,
      lastDate: DateTime(2100),
      locale: const Locale('th', 'TH'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF5A81BB),
              onPrimary: Colors.white,
              onSurface: Color(0xFF2B4C7E),
            ),
            dialogBackgroundColor: Colors.white,
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF5A81BB),
                textStyle: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked == null) return;

    setState(() {
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
      _applyFilters();
    });

    // เรียกดึงข้อมูลจาก API ทันทีหลังเลือกปฏิทิน
    _loadData();
  }

  // ===== Grouping by schedule time =====
  Map<String, List<Map<String, dynamic>>> _groupByTimeList(
      List<Map<String, dynamic>> regimens) {
    final map = <String, List<Map<String, dynamic>>>{};
    for (final reg in regimens) {
      final times = reg['times'];
      if (times is List) {
        for (final t in times) {
          if (t is Map) {
            final rawTime = _readString(t['timeOfDay']);
            final timeKey = rawTime.isNotEmpty ? rawTime : 'ไม่มีการระบุเวลา';

            final medMap = {
              'regimen': reg,
              'timeData': t,
            };
            map.putIfAbsent(timeKey, () => []).add(medMap);
          }
        }
      }
    }
    return map;
  }

  // ===== UI Constants =====
  static const _primary = Color(0xFF2B4C7E);

  String _formatMealRelation(String? relation) {
    if (relation == null) return '';
    switch (relation.toUpperCase()) {
      case 'BEFORE_MEAL':
        return 'ก่อนอาหาร';
      case 'AFTER_MEAL':
        return 'หลังอาหาร';
      case 'NONE':
        return '';
      default:
        return relation;
    }
  }

  Widget _buildRegimenCard(Map<String, dynamic> itemData) {
    final Map<String, dynamic> reg = itemData['regimen'] ?? {};
    final Map<String, dynamic> time = itemData['timeData'] ?? {};
    final med = reg['medicine'] ?? {};

    final nickname = _readString(reg['mediNickname']);
    final tradeName = _readString(med['mediTradeName']);
    final thName = _readString(med['mediThName']);
    final enName = _readString(med['mediEnName']);

    final safeNickname = nickname.isNotEmpty ? nickname : '';
    final safeTrade = tradeName.isNotEmpty ? tradeName : '';
    final safeTh = thName.isNotEmpty ? thName : '';
    final safeEn = enName.isNotEmpty ? enName : '';

    final mainTitle = safeNickname.isNotEmpty
        ? safeNickname
        : (safeTrade.isNotEmpty
            ? safeTrade
            : (safeTh.isNotEmpty
                ? safeTh
                : (safeEn.isNotEmpty ? safeEn : 'ไม่ทราบชื่อยา')));

    final dose = _readInt(time['dose']) ?? 1;
    final unit = _readString(time['unit']);
    final doseText = unit.isEmpty ? '$dose' : '$dose $unit';

    final mealText = _formatMealRelation(_readString(time['mealRelation']));

    final scheduleType = _readString(reg['scheduleType']);
    String freq = 'ทานยาแบบ: $scheduleType';
    if (scheduleType.toUpperCase() == 'DAILY') {
      freq = 'ทานทุกวัน';
    } else if (scheduleType.toUpperCase() == 'WEEKLY') {
      freq = 'ทานทุกสัปดาห์ (วัน: ${reg['daysOfWeek']})';
    } else if (scheduleType.toUpperCase() == 'INTERVAL') {
      freq = 'ทานทุก ${reg['intervalDays']} วัน';
    } else if (scheduleType.toUpperCase() == 'CYCLE') {
      freq = 'ทาน ${reg['cycleOnDays']} วัน เว้น ${reg['cycleBreakDays']} วัน';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFD6E3F3), width: 1.5),
      ),
      elevation: 0,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 4, right: 12),
              width: 3,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF6FA8DC),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mainTitle,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF333333),
                    ),
                  ),
                  if (safeTrade.isNotEmpty || safeTh.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        (safeTrade.isNotEmpty ? safeTrade : '') +
                            (safeTh.isNotEmpty
                                ? (safeTrade.isNotEmpty ? ' ($safeTh)' : safeTh)
                                : ''),
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                  if (mealText.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Row(
                        children: [
                          const Icon(Icons.restaurant_rounded,
                              size: 14, color: Color(0xFF6FA8DC)),
                          const SizedBox(width: 4),
                          Text(
                            mealText,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF6FA8DC),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_month_rounded,
                            size: 14, color: Colors.black45),
                        const SizedBox(width: 4),
                        Text(
                          freq,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F6FF),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                doseText,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2B4C7E),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final grouped = _groupByTimeList(_filteredRegimens);
    final timeKeys = grouped.keys.toList()..sort();
    final ownerAvatar = _buildProfileImage(_ownerImage);

    String formatThaiDateBE(DateTime date) {
      final dayMonth = DateFormat('d MMMM', 'th_TH').format(date);
      final buddhistYear = date.year + 543;
      return '$dayMonth $buddhistYear';
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF0F6FF),
      appBar: AppBar(
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color.fromARGB(255, 234, 244, 255),
                Color.fromARGB(255, 193, 222, 255),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF5A81BB)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded,
              color: Color(0xFF5A81BB)),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text(
          'แผนการทานยา',
          style: TextStyle(
            color: Color(0xFF2B4C7E),
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
          textAlign: TextAlign.center,
        ),
      ),
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                // ===== Owner profile header =====
                Container(
                  width: double.infinity,
                  color: const Color.fromARGB(255, 193, 222, 255),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: const Color(0xFF8FB6E5),
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
                                color: Color(0xFF2B4C7E),
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'โปรไฟล์: $_profileLabel',
                              style: const TextStyle(
                                color: Color(0xFF5A81BB),
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
                  color: const Color.fromARGB(255, 193, 222, 255),
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
                          value: DateFormat('d MMMM yyyy', 'th_TH')
                              .format(_startDate),
                          onTap: () => _pickDate(isStart: true),
                        ),
                      ),
                      const SizedBox(width: 5),
                      const Text('ถึง'),
                      const SizedBox(width: 5),
                      Expanded(
                        child: _DateField(
                          label: '',
                          value: DateFormat('d MMMM yyyy', 'th_TH')
                              .format(_endDate),
                          onTap: () => _pickDate(isStart: false),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // ===== List =====
                Expanded(
                  child: _errorMessage.isNotEmpty
                      ? Center(
                          child: Text(
                            _errorMessage,
                            textAlign: TextAlign.center,
                          ),
                        )
                      : timeKeys.isEmpty
                          ? const Center(child: Text('ไม่มีแผนการทานยา'))
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                              itemCount: timeKeys.length,
                              itemBuilder: (context, i) {
                                final timeKey = timeKeys[i];
                                final timesGroup = grouped[timeKey]!;

                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(
                                          top: 16, bottom: 8),
                                      child: Row(
                                        children: [
                                          const Icon(
                                              Icons.access_time_filled_rounded,
                                              size: 20,
                                              color: _primary),
                                          const SizedBox(width: 8),
                                          Text(
                                            timeKey.contains(':')
                                                ? '$timeKey น.'
                                                : timeKey,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: _primary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    ...timesGroup
                                        .map((it) => _buildRegimenCard(it)),
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
                    color: Color.fromARGB(84, 196, 219, 240),
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
                      const Text(
                        'กำลังโหลด…',
                        style: TextStyle(
                          color: Color.fromARGB(255, 93, 139, 197),
                          fontSize: 16,
                        ),
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

  static const _primary = Color(0xFF2B4C7E);

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
