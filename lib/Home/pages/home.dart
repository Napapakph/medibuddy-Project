import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:medibuddy/widgets/app_drawer.dart';
import 'package:medibuddy/services/regimen_api.dart';
import '../../Model/profile_model.dart';
import '../../Model/medicine_regimen_model.dart';
import 'select_profile.dart';
import '../../services/app_state.dart';
import '../../Home/pages/select_profile.dart';
import '../../widgets/bottomBar.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class Home extends StatefulWidget {
  final ProfileModel? selectedProfile;

  const Home({
    super.key,
    this.selectedProfile,
  });

  @override
  State<Home> createState() => _Home();
}

class _Home extends State<Home> {
  String _imageBaseUrl = '';
  final RegimenApiService _regimenApi = RegimenApiService();
  bool _loading = false;
  String? _error;
  List<_MedicineReminder> _homeReminders = [];
  String? _profileName; // ✅ PROFILE_BIND: resolved name
  String? _profileImagePath; // ✅ PROFILE_BIND: resolved image path
  bool _profileBound = false; // ⚠️ GUARD: bind once
  int? _profileId;
  static const int _maxForwardDays = 365;
  late final PageController _pageController;
  final DateTime _today = DateUtils.dateOnly(DateTime.now());
  int _currentPageIndex = 0;
  int? _loadingPageIndex;
  final Map<int, List<_MedicineReminder>> _remindersByIndex = {};

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchHomeReminders(date: _today, pageIndex: 0);
    });
    _imageBaseUrl = dotenv.env['API_BASE_URL'] ?? '';
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_profileBound) return; // ⚠️ GUARD: bind once

    final routeArgs =
        ModalRoute.of(context)?.settings.arguments; // ✅ PROFILE_BIND

    int? resolvedProfileId;
    String? resolvedProfileName;
    String? resolvedProfileImagePath;
    _profileId = resolvedProfileId ?? AppState.instance.currentProfileId;

    if (routeArgs is Map) {
      final rawId = routeArgs['profileId'];
      if (rawId is int) {
        resolvedProfileId = rawId;
      } else if (rawId != null) {
        resolvedProfileId = int.tryParse(rawId.toString());
      }

      final rawName = routeArgs['profileName'] ?? routeArgs['username'];
      resolvedProfileName = rawName?.toString();

      final rawImage = routeArgs['profileImage'] ?? routeArgs['imagePath'];
      resolvedProfileImagePath = rawImage?.toString();
    } else if (routeArgs is int) {
      resolvedProfileId = routeArgs;
    }

    resolvedProfileId ??= widget.selectedProfile?.profileId;
    resolvedProfileName ??= widget.selectedProfile?.username;
    resolvedProfileImagePath ??= widget.selectedProfile?.imagePath;

    setState(() {
      // 🔥 FIX: trigger UI rebuild after binding

      _profileName =
          (resolvedProfileName != null && resolvedProfileName.trim().isNotEmpty)
              ? resolvedProfileName.trim()
              : 'Profile'; // ✅ PROFILE_BIND
      _profileImagePath =
          (resolvedProfileImagePath ?? '').trim(); // ✅ PROFILE_BIND
      _profileBound = true; // ⚠️ GUARD
    });

    debugPrint(
        '🏠 HOME bound profileId=$_profileId name="$_profileName" image="$_profileImagePath"');
    debugPrint(
        '🧪 HOME routeArgs = ${ModalRoute.of(context)?.settings.arguments} '
        '(type=${ModalRoute.of(context)?.settings.arguments.runtimeType})');
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  ImageProvider _buildProfileImage(String path) {
    final p = path.trim(); // 🔥 FIX: trim

    if (p.isEmpty || p.toLowerCase() == 'null') {
      return const AssetImage('assets/cat_profile.png');
    }

    if (p.startsWith('http://') || p.startsWith('https://')) {
      return NetworkImage(p);
    }

    // ✅ FIX: server-relative "/uploads/..."
    if (p.startsWith('/')) {
      return NetworkImage('$_imageBaseUrl$p');
    }

    // ✅ FIX: relative "uploads/..." -> treat as network
    if (p.contains('/')) {
      return NetworkImage('$_imageBaseUrl/$p');
    }

    return FileImage(File(p));
  }

  int _resolveProfileId() {
    final routeArgs = ModalRoute.of(context)?.settings.arguments;
    int? resolved;

    if (routeArgs is Map) {
      final raw =
          routeArgs['profileId'] ?? routeArgs['profileID'] ?? routeArgs['id'];
      resolved = _readInt(raw);
    } else if (routeArgs is int) {
      resolved = routeArgs;
    } else if (routeArgs != null) {
      resolved = _readInt(routeArgs);
    }

    resolved ??= _profileId;
    resolved ??= widget.selectedProfile?.profileId;
    resolved ??= AppState.instance.currentProfileId;

    if (resolved != null && resolved > 0) {
      _profileId = resolved;
      return resolved;
    }

    return 0;
  }

  int? _readInt(dynamic value) {
    if (value == null) return null;
    return int.tryParse(value.toString());
  }

  DateTime _dateForIndex(int index) {
    return _today.add(Duration(days: index));
  }

  int _indexForDate(DateTime date) {
    final diff = DateUtils.dateOnly(date).difference(_today).inDays;
    if (diff < 0) return 0;
    if (diff > _maxForwardDays) return _maxForwardDays;
    return diff;
  }

  Future<void> _pickDisplayedDate(DateTime currentDate) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: currentDate,
      firstDate: _today,
      lastDate: _today.add(const Duration(days: _maxForwardDays)),
    );
    if (picked == null) return;
    final targetIndex = _indexForDate(picked);
    await _pageController.animateToPage(
      targetIndex,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  void _handlePageChanged(int index) {
    setState(() {
      _currentPageIndex = index;
      _homeReminders = _remindersByIndex[index] ?? [];
    });
    _fetchHomeReminders(date: _dateForIndex(index), pageIndex: index);
  }

  Future<void> _fetchHomeReminders({
    required DateTime date,
    required int pageIndex,
  }) async {
    final profileId = _resolveProfileId();
    debugPrint('\u{1F3E0} home profileId=$profileId date=$date');

    if (profileId <= 0) {
      const message = 'missing profileId';
      debugPrint('\u274C home reminder error=$message');
      if (mounted) {
        setState(() {
          _error = message;
          _loading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(message)),
        );
      } else {
        _error = message;
      }
      return;
    }

    if (mounted) {
      setState(() {
        _loading = true;
        _loadingPageIndex = pageIndex;
        _error = null;
      });
    }

    try {
      final response = await _regimenApi.getRegimensByProfileId(
        profileId: profileId,
      );
      final items = response.items;
      debugPrint('\u{1F3E0} fetched items=${items.length}');
      final reminders = _mapHomeRemindersFromProfile(
        items,
        forDate: date,
      );
      if (!mounted) return;
      setState(() {
        _remindersByIndex[pageIndex] = reminders;
        if (pageIndex == _currentPageIndex) {
          _homeReminders = reminders;
          _error = null;
        }
      });
    } catch (e) {
      if (!mounted) return;
      final message = e.toString();
      debugPrint('\u274C home reminder error=$message');
      setState(() {
        if (pageIndex == _currentPageIndex) {
          _error = message;
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } finally {
      if (mounted && pageIndex == _currentPageIndex) {
        setState(() {
          _loading = false;
          _loadingPageIndex = null;
        });
      }
    }
  }

  List<_MedicineReminder> _mapHomeRemindersFromProfile(
    List<MedicineRegimenItem> items, {
    DateTime? forDate,
  }) {
    final flattened = <_HomeReminderFlat>[];
    final targetDate = forDate != null ? DateUtils.dateOnly(forDate) : null;
    for (final item in items) {
      if (targetDate != null && !_isRegimenActiveOnDate(item, targetDate)) {
        continue;
      }
      final nickname = (item.medicineList?.mediNickname ?? '').trim();
      for (final time in item.times) {
        final timeValue = time.time.trim();
        if (timeValue.isEmpty) continue;
        flattened.add(
          _HomeReminderFlat(
            time: timeValue,
            nickname: nickname,
            mealRelation: time.mealRelation,
            dose: time.dose,
            unit: time.unit,
          ),
        );
      }
    }

    debugPrint('\u{1F3E0} flattened times=${flattened.length}');

    final grouped = <String, Map<String, _HomeReminderAggregate>>{};
    for (final entry in flattened) {
      final timeKey = entry.time;
      final nameKey = entry.nickname;
      final groupForTime = grouped.putIfAbsent(timeKey, () => {});
      final existing = groupForTime[nameKey];
      if (existing == null) {
        groupForTime[nameKey] = _HomeReminderAggregate(
          nickname: entry.nickname,
          mealRelation: entry.mealRelation,
          totalDose: entry.dose,
          unit: entry.unit,
        );
      } else {
        existing.totalDose += entry.dose;
        existing.mealRelation =
            _mergeMealRelation(existing.mealRelation, entry.mealRelation);
        if (existing.unit.trim().isEmpty && entry.unit.trim().isNotEmpty) {
          existing.unit = entry.unit;
        }
      }
    }

    debugPrint('\u{1F3E0} grouped times=${grouped.length}');

    final reminders = <_MedicineReminder>[];
    final sortedTimes = grouped.keys.toList()..sort(_compareTime);
    for (final timeKey in sortedTimes) {
      final medicines = grouped[timeKey]!;
      final names = medicines.keys.toList()..sort();
      for (final nameKey in names) {
        final agg = medicines[nameKey]!;
        final unitText = _mapUnitToText(agg.unit);
        final doseText = unitText.isEmpty
            ? _formatDose(agg.totalDose)
            : '${_formatDose(agg.totalDose)} $unitText';
        reminders.add(
          _MedicineReminder(
            time: timeKey,
            name: agg.nickname,
            meal: _mealTextFromRelation(agg.mealRelation),
            pills: doseText,
          ),
        );
      }
    }

    return reminders;
  }

  DateTime? _parseDateOnly(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    final parsed = DateTime.tryParse(trimmed);
    if (parsed == null) return null;
    return DateUtils.dateOnly(parsed);
  }

  List<int> _parseDaysOfWeek(String? raw) {
    if (raw == null) return [];
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return [];
    final parts = trimmed.split(',');
    final days = <int>[];
    for (final part in parts) {
      final value = int.tryParse(part.trim());
      if (value != null) {
        days.add(value);
      }
    }
    return days;
  }

  bool _isRegimenActiveOnDate(MedicineRegimenItem item, DateTime date) {
    final target = DateUtils.dateOnly(date);
    final start = _parseDateOnly(item.startDate);
    if (start != null && target.isBefore(start)) return false;

    final end = item.endDate == null ? null : _parseDateOnly(item.endDate!);
    if (end != null && target.isAfter(end)) return false;

    final schedule = item.scheduleType.trim().toUpperCase();
    switch (schedule) {
      case 'WEEKLY':
        final days = _parseDaysOfWeek(item.daysOfWeekRaw);
        if (days.isEmpty) return true;
        return days.contains(target.weekday);
      case 'INTERVAL':
        final interval = item.intervalDays ?? 0;
        if (interval <= 0 || start == null) return true;
        final diffDays = target.difference(start).inDays;
        if (diffDays < 0) return false;
        return diffDays % interval == 0;
      case 'CYCLE':
        final onDays = item.cycleOnDays ?? 0;
        final breakDays = item.cycleBreakDays ?? 0;
        if (onDays <= 0 || start == null) return true;
        final total = onDays + breakDays;
        if (total <= 0) return true;
        final diffDays = target.difference(start).inDays;
        if (diffDays < 0) return false;
        final pos = diffDays % total;
        return pos < onDays;
      case 'DAILY':
      default:
        return true;
    }
  }

  String _mergeMealRelation(String current, String incoming) {
    final normalizedCurrent = current.trim().toUpperCase();
    final normalizedIncoming = incoming.trim().toUpperCase();
    if (normalizedCurrent.isEmpty || normalizedCurrent == 'NONE') {
      return incoming;
    }
    if (normalizedIncoming.isEmpty || normalizedIncoming == 'NONE') {
      return current;
    }
    return current;
  }

  String _mealTextFromRelation(String relation) {
    switch (relation.trim().toUpperCase()) {
      case 'AFTER_MEAL':
        return '\u0E2B\u0E25\u0E31\u0E07\u0E2D\u0E32\u0E2B\u0E32\u0E23';
      case 'BEFORE_MEAL':
        return '\u0E01\u0E48\u0E2D\u0E19\u0E2D\u0E32\u0E2B\u0E32\u0E23';
      case 'NONE':
        return '';
      default:
        return '';
    }
  }

  String _mapUnitToText(String unit) {
    final normalized = unit.trim().toLowerCase();
    switch (normalized) {
      case 'tablet':
        return '\u0E40\u0E21\u0E47\u0E14';
      case 'mg':
        return '\u0E21\u0E01.';
      case 'ml':
        return '\u0E21\u0E25.';
      default:
        return unit.trim();
    }
  }

  String _formatDose(num dose) {
    if (dose % 1 == 0) {
      return dose.toInt().toString();
    }
    return dose.toString();
  }

  int _compareTime(String a, String b) {
    final aMinutes = _timeToMinutes(a);
    final bMinutes = _timeToMinutes(b);
    final cmp = aMinutes.compareTo(bMinutes);
    if (cmp != 0) return cmp;
    return a.compareTo(b);
  }

  int _timeToMinutes(String value) {
    final parts = value.split(':');
    if (parts.length < 2) return 0;
    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = int.tryParse(parts[1]) ?? 0;
    final safeHour = hour.clamp(0, 23).toInt();
    final safeMinute = minute.clamp(0, 59).toInt();
    return (safeHour * 60) + safeMinute;
  }

  int? _tryTimeToMinutes(String value) {
    final parts = value.split(':');
    if (parts.length < 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;
    return (hour * 60) + minute;
  }

  bool _isPastDueTime(String time, int nowMinutes) {
    final minutes = _tryTimeToMinutes(time);
    if (minutes == null) return false;
    return minutes < nowMinutes;
  }

  bool _isPastDueForDate(String time, DateTime displayDate, int nowMinutes) {
    final display = DateUtils.dateOnly(displayDate);
    if (display.isAfter(_today)) return false;
    if (display.isBefore(_today)) return true;
    return _isPastDueTime(time, nowMinutes);
  }

  List<_MedicineReminder> _orderedReminders(
    List<_MedicineReminder> reminders,
    DateTime displayDate,
  ) {
    final now = DateTime.now();
    final nowMinutes = (now.hour * 60) + now.minute;
    final indexed = reminders.asMap().entries.toList();
    indexed.sort((a, b) {
      final aPast = _isPastDueForDate(a.value.time, displayDate, nowMinutes);
      final bPast = _isPastDueForDate(b.value.time, displayDate, nowMinutes);
      if (aPast == bPast) return a.key.compareTo(b.key);
      return aPast ? 1 : -1;
    });
    return indexed.map((entry) => entry.value).toList();
  }

  void _toggleReminder(int index) {
    setState(() {
      _homeReminders[index].isTaken = !_homeReminders[index].isTaken;
      _remindersByIndex[_currentPageIndex] = _homeReminders;
    });
  }

  Widget _buildReminderCard(
    BuildContext context,
    _MedicineReminder reminder, {
    required bool pastDue,
  }) {
    final isTaken = reminder.isTaken;
    final checkColor =
        isTaken ? const Color(0xFF1F497D) : const Color(0xFF9EC6F5);
    final timeColor =
        isTaken ? const Color(0xFF1F497D) : const Color(0xFF6FA8DC);

    return Row(
      children: [
        Expanded(
          child: Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isTaken
                        ? const Color(0xFF1F497D)
                        : const Color(0xFFD6E3F3),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            reminder.time,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: timeColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            reminder.name,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.circle,
                                size: 6,
                                color: Color(0xFF6FA8DC),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                reminder.meal,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF6FA8DC),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: 56,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            reminder.pills,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6FA8DC),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (pastDue)
                Positioned.fill(
                  child: IgnorePointer(
                    ignoring: true,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: const Color.fromARGB(255, 159, 159, 183)
                            .withOpacity(0.18),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'MediBuddy',
          style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F497D),
              fontSize: 30),
        ),
        backgroundColor: Color(0xFFB7DAFF),
        centerTitle: true,
        leading: Builder(
          builder: (context) {
            return IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            );
          },
        ),
      ),
      drawer: const AppDrawer(),
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxWidth = constraints.maxWidth;
            final maxHeight = constraints.maxHeight;

            //ถ้าจอกว้างแบบแท็บเล็ต
            final bool isTablet = maxWidth > 600;

            //จำกัดความกว้างสูงสุดของหน้าจอ
            final double containerWidth = isTablet ? 500 : maxWidth;
            // ใช้ DateTime + intl ได้เลย เพราะ main() init ไว้แล้ว
            final displayedDate = _dateForIndex(_currentPageIndex);
            final buddhistYear = displayedDate.year + 543;
            final dayMonth = DateFormat('d MMMM').format(displayedDate);
            final thaiBuddhistDate = '$dayMonth $buddhistYear';
            final profileImage = _buildProfileImage(
                _profileImagePath ?? ''); // ✅ PROFILE_BIND: image
            final profileName =
                _profileName ?? 'Profile'; // ✅ PROFILE_BIND: name

            return Align(
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.only(bottom: maxHeight * 0.03),
                    color: const Color(0xFFB7DAFF), // สีฟ้าของเดียร์
                    child: Column(
                      children: [
                        InkWell(
                          onTap: () => _pickDisplayedDate(displayedDate),
                          child: Text(
                            thaiBuddhistDate,
                            style: TextStyle(
                              fontSize: 18,
                              color: Color(0xFF1F497D),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: SizedBox(
                        width: containerWidth,
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: maxWidth * 0.05,
                            vertical: maxHeight * 0.02,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              InkWell(
                                borderRadius: BorderRadius.circular(40),
                                onTap: () {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const SelectProfile(),
                                    ),
                                  );
                                },
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 22,
                                      backgroundImage: profileImage,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      profileName,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF1F497D),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: maxHeight * 0.02),
                              Expanded(
                                child: PageView.builder(
                                  controller: _pageController,
                                  itemCount: _maxForwardDays + 1,
                                  onPageChanged: _handlePageChanged,
                                  itemBuilder: (context, pageIndex) {
                                    final pageDate = _dateForIndex(pageIndex);
                                    final reminders =
                                        _remindersByIndex[pageIndex] ??
                                            (pageIndex == _currentPageIndex
                                                ? _homeReminders
                                                : <_MedicineReminder>[]);
                                    final orderedReminders =
                                        _orderedReminders(reminders, pageDate);
                                    final now = DateTime.now();
                                    final nowMinutes =
                                        (now.hour * 60) + now.minute;
                                    final isLoading = _loading &&
                                        _loadingPageIndex == pageIndex;

                                    return Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE8F2FF),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: isLoading
                                          ? const Center(
                                              child:
                                                  CircularProgressIndicator(),
                                            )
                                          : reminders.isEmpty
                                              ? const Center(
                                                  child:
                                                      Text('No reminders yet'),
                                                )
                                              : ListView.separated(
                                                  itemCount:
                                                      orderedReminders.length,
                                                  separatorBuilder: (_, __) =>
                                                      const SizedBox(
                                                          height: 12),
                                                  itemBuilder:
                                                      (context, index) {
                                                    final reminder =
                                                        orderedReminders[index];
                                                    final pastDue =
                                                        _isPastDueForDate(
                                                      reminder.time,
                                                      pageDate,
                                                      nowMinutes,
                                                    );
                                                    return _buildReminderCard(
                                                      context,
                                                      reminder,
                                                      pastDue: pastDue,
                                                    );
                                                  },
                                                ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  BottomBar(
                    currentRoute: '/home',
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _MedicineReminder {
  final String time;
  final String name;
  final String meal;
  final String pills;
  bool isTaken;

  _MedicineReminder({
    required this.time,
    required this.name,
    required this.meal,
    required this.pills,
    this.isTaken = false,
  });
}

class _HomeReminderFlat {
  final String time;
  final String nickname;
  final String mealRelation;
  final num dose;
  final String unit;

  _HomeReminderFlat({
    required this.time,
    required this.nickname,
    required this.mealRelation,
    required this.dose,
    required this.unit,
  });
}

class _HomeReminderAggregate {
  final String nickname;
  String mealRelation;
  num totalDose;
  String unit;

  _HomeReminderAggregate({
    required this.nickname,
    required this.mealRelation,
    required this.totalDose,
    required this.unit,
  });
}
