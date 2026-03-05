import 'dart:collection';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:medibuddy/alarm_medicine/confirm_action.dart';
import 'package:medibuddy/services/log_api.dart';
import 'package:medibuddy/services/auth_manager.dart';
import 'package:medibuddy/services/notification_launch_guard.dart';
import 'package:medibuddy/services/app_route_observer.dart';
import 'package:medibuddy/main.dart' show navigatorKey;
import 'package:medibuddy/services/app_state.dart';

class AlarmScreen extends StatefulWidget {
  final Map<String, dynamic>? payload;

  const AlarmScreen({super.key, this.payload});

  @override
  State<AlarmScreen> createState() => _AlarmScreenState();
}

class _AlarmScreenState extends State<AlarmScreen> {
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _debugPayload();
  }

  Map<String, dynamic> _normalizedPayload() {
    final raw = widget.payload ?? <String, dynamic>{};
    final notif = (raw['notification'] is Map)
        ? Map<String, dynamic>.from(raw['notification'] as Map)
        : <String, dynamic>{};
    final data = (raw['data'] is Map)
        ? Map<String, dynamic>.from(raw['data'] as Map)
        : <String, dynamic>{};

    final merged = <String, dynamic>{};
    if (notif.isNotEmpty) {
      merged['title'] = notif['title'];
      merged['body'] = notif['body'];
    }
    merged.addAll(data);
    merged.addAll(raw);
    return merged;
  }

  void _debugPayload() {
    final n = _normalizedPayload();
    final items = _alarmItems();
    debugPrint('AlarmScreen raw payload = ${widget.payload}');
    debugPrint('AlarmScreen normalized keys = ${n.keys.toList()}');
    debugPrint('title=${n['title']} body=${n['body']}');
    debugPrint(
        'type=${n['type']} logId=${n['logId']} profileId=${n['profileId']} mediListId=${n['mediListId']} mediRegimenId=${n['mediRegimenId']}');
    debugPrint(
        'scheduleTime=${n['scheduleTime']} snoozedCount=${n['snoozedCount']} isSnoozeReminder=${n['isSnoozeReminder']}');
    debugPrint('items=${items.isNotEmpty} count=${items.length}');
    if (items.isNotEmpty) {
      debugPrint('items first keys=${items.first.keys.toList()}');
    }
  }

  List<Map<String, dynamic>> _parsePayloadItems(dynamic raw) {
    if (raw == null) return [];
    try {
      dynamic decoded = raw is String ? jsonDecode(raw) : raw;
      if (decoded is List) {
        return decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      } else if (decoded is Map) {
        return [Map<String, dynamic>.from(decoded)];
      }
      return [];
    } catch (e) {
      debugPrint('❌ Failed to decode payload list: $e');
      return [];
    }
  }

  List<Map<String, dynamic>> _alarmItems() {
    final normalized = _normalizedPayload();
    final itemsList = <Map<String, dynamic>>[];

    // 1) Direct check for JSON string array in 'payload'
    if (normalized['payload'] is String) {
      try {
        final decoded = jsonDecode(normalized['payload']);
        if (decoded is List) {
          final mapped =
              decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
          debugPrint(
              '✅ Decoded grouped items from data["payload"] string. Length: ${mapped.length}');
          itemsList.addAll(mapped);
        }
      } catch (e) {
        debugPrint('❌ Error parsing data["payload"] string: $e');
      }
    }

    // 2) Check if parsing with _parsePayloadItems works (if it was already a list)
    if (itemsList.isEmpty) {
      final fromPayload = _parsePayloadItems(normalized['payload']);
      if (fromPayload.isNotEmpty) {
        debugPrint('✅ Decoded items from payload array.');
        itemsList.addAll(fromPayload);
      }
    }

    // 3) Check if 'items' already contains a decoded list (from main.dart payload builder)
    if (itemsList.isEmpty) {
      final fromItems = _parsePayloadItems(normalized['items']);
      if (fromItems.isNotEmpty) {
        debugPrint('✅ Decoded items from "items" array.');
        itemsList.addAll(fromItems);
      }
    }

    // 4) Fallback: is it a single item itself?
    if (itemsList.isEmpty) {
      if (normalized['type'] == 'MEDICATION_REMINDER' ||
          normalized['logId'] != null) {
        debugPrint('ℹ️ Fallback: Treating root payload as a single item');
        itemsList.add(normalized);
      } else {
        debugPrint(
            '⚠️ Warning: No valid items found in payload! normalized=$normalized');
      }
    }

    debugPrint(
        '🧪 alarm_screen received items length: ${itemsList.length} (expect > 0)');

    return itemsList;
  }

  int? _parseLogId(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }

  /// Safe int parser for profile ID detection (separate from _parseLogId)
  int? _toInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }

  List<int> _extractLogIds() {
    final items = _alarmItems();
    final ids = <int>[];

    if (items.isNotEmpty) {
      for (final item in items) {
        final parsed = _parseLogId(item['logId']);
        if (parsed != null && parsed > 0) {
          ids.add(parsed);
        }
      }
    } else {
      // Fallback for single item structure
      final raw = widget.payload ?? <String, dynamic>{};
      if (raw['data'] is Map) {
        final data = Map<String, dynamic>.from(raw['data'] as Map);
        if (data['logId'] is List) {
          for (final item in data['logId'] as List) {
            final parsed = _parseLogId(item);
            if (parsed != null && parsed > 0) ids.add(parsed);
          }
        } else {
          final single = _parseLogId(data['logId']);
          if (single != null && single > 0) ids.add(single);
        }
      }

      final normalized = _normalizedPayload();
      final rootSingle = _parseLogId(normalized['logId']);
      if (rootSingle != null && rootSingle > 0 && !ids.contains(rootSingle)) {
        ids.add(rootSingle);
      }
    }

    return ids;
  }

  // Removed _submitResponseForLogId method

  // Removed _submitResponse method

  Future<void> _openConfirmAction({required List<int> logIds}) async {
    if (_submitting) {
      debugPrint('⚠️ _openConfirmAction blocked because _submitting=true');
      return;
    }

    setState(() {
      _submitting = true;
    });

    debugPrint('✅ Pushing ConfirmActionScreen directly');

    if (!mounted) return;
    await Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (_) => ConfirmActionScreen(
          logIds: logIds,
          payload: widget.payload,
          headerTimeText: _timeText(),
        ),
      ),
    );

    if (mounted) {
      setState(() {
        _submitting = false;
      });
    }
  }

  // ✅ NEW: format TimeOfDay to HH:mm
  String _formatHHmm(TimeOfDay t) {
    final hh = t.hour.toString().padLeft(2, '0');
    final mm = t.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  // ✅ NEW: Try parse scheduleTime (ISO) -> local HH:mm
  String _timeFromScheduleTime(dynamic value) {
    if (value == null) return '';
    final raw = value.toString().trim();
    if (raw.isEmpty) return '';
    final dt = DateTime.tryParse(raw);
    if (dt == null) return '';
    final local = dt.toLocal();
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  // ✅ UPDATED: Prefer payload['time'] then payload['scheduleTime']
  String _timeText() {
    final payload = _normalizedPayload();

    // 1) พยายามอ่านเวลาจริงจาก schedule ก่อน (แหล่งที่เชื่อถือได้)
    final fromSchedule = _timeFromScheduleTime(payload['scheduleTime']);
    if (fromSchedule.isNotEmpty) {
      return fromSchedule;
    }

    final items = _alarmItems();
    if (items.isNotEmpty) {
      final fromItems = _timeFromScheduleTime(items.first['scheduleTime']);
      if (fromItems.isNotEmpty) {
        return fromItems;
      }
    }

    // 2) fallback ไปใช้ time (ถ้ามีและไม่ใช่ค่าเพี้ยน)
    final rawTime = payload['time']?.toString().trim();
    if (rawTime != null &&
        rawTime.isNotEmpty &&
        rawTime != 'null' &&
        rawTime != '00:00') {
      return rawTime;
    }

    // 3) fallback สุดท้าย
    return '12:00';
  }

  String _titleText() {
    final payloadTitle = _normalizedPayload()['title']?.toString() ?? '';
    if (payloadTitle.isNotEmpty) return payloadTitle;
    return 'ได้เวลาทานยาแล้ว';
  }

  String _bodyText() {
    return _normalizedPayload()['body']?.toString() ?? '';
  }

  /// Clean a raw medication name string:
  /// remove Thai/English prefixes and trailing " for <profile>."
  String _cleanMedName(String raw) {
    var s = raw.trim();
    // Thai prefix
    s = s.replaceAll('ได้เวลาทานยา ', '').trim();
    // English prefix
    if (s.startsWith("It's time to take ")) {
      s = s.substring("It's time to take ".length).trim();
    }
    // English trailing " for <profileName>."
    final trailingMatch = RegExp(r'\s+for\s+.+\.$').firstMatch(s);
    if (trailingMatch != null) {
      s = s.substring(0, trailingMatch.start).trim();
    }
    return s;
  }

  /// Build a summary list from the payload items.
  ///
  /// - EMPTY:  placeholder text
  /// - SINGLE: medication names only (no profile header)
  /// - MULTI:  profile names only (no med details)
  List<Widget> _buildItemsSummaryWidgets() {
    final items = _alarmItems();

    // ── EMPTY mode ──
    if (items.isEmpty) {
      debugPrint('🔔 [AlarmSummary] EMPTY itemsCount=0');
      return [
        const Padding(
          padding: EdgeInsets.only(top: 8),
          child: Text(
            'แตะ Take เพื่อดูรายละเอียด',
            style: TextStyle(fontSize: 14, color: Color(0xFF8A9BB5)),
            textAlign: TextAlign.center,
          ),
        ),
      ];
    }

    // ── Build profileId → displayName map from PAYLOAD (primary source) ──
    final profileMap = LinkedHashMap<int, String>();
    for (final item in items) {
      final id = _toInt(item['profileId']);
      if (id == null || id <= 0) continue;
      if (profileMap.containsKey(id)) continue; // first occurrence wins

      // Primary: payload item's profileName
      final payloadName = (item['profileName']?.toString() ?? '').trim();
      if (payloadName.isNotEmpty) {
        profileMap[id] = payloadName;
        continue;
      }

      // Fallback: AppState cache
      final cachedName = AppState.instance.resolveProfileName(id);
      profileMap[id] = cachedName; // resolveProfileName never returns empty
    }

    final isMulti = profileMap.length > 1;
    final mode = isMulti ? 'MULTI_PROFILE' : 'SINGLE_PROFILE';
    debugPrint('🔔 [AlarmSummary] mode=$mode itemsCount=${items.length} '
        'profileMapCount=${profileMap.length} '
        'cachedProfilesCount=${AppState.instance.cachedProfiles.length}');

    final widgets = <Widget>[];

    if (isMulti) {
      // ── MULTI mode: show only profile names (from payload, never blank) ──
      debugPrint('🔔 [AlarmSummary] resolvedNames=$profileMap');

      for (final entry in profileMap.entries) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.person, size: 16, color: Color(0xFF2B4C7E)),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    entry.value,
                    style:
                        const TextStyle(fontSize: 13, color: Color(0xFF5A81BB)),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      }
    } else {
      // ── SINGLE mode: show only medication names ──
      final uniqueMeds = LinkedHashSet<String>();
      for (final item in items) {
        final raw =
            (item['mediNickname'] ?? item['medicineName'] ?? item['body'] ?? '')
                .toString();
        var cleaned = _cleanMedName(raw);
        if (cleaned.isEmpty) cleaned = 'ยา (ไม่ทราบชื่อ)';
        uniqueMeds.add(cleaned);
      }
      for (final med in uniqueMeds) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(left: 24, top: 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.medication,
                    size: 14, color: Color(0xFF5A81BB)),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    med,
                    style:
                        const TextStyle(fontSize: 13, color: Color(0xFF5A81BB)),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }

    return widgets;
  }

  List<Widget> _headerWidgets(String title, String body) {
    return [
      Image.asset(
        'assets/main_mascot.png',
        width: 160,
        height: 160,
        fit: BoxFit.contain,
      ),
      const SizedBox(height: 5),
      Text(
        _timeText(),
        style: const TextStyle(
          fontSize: 56,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
          color: Color(0xFF2B4C7E),
        ),
      ),
      if (title.isNotEmpty) ...[
        const SizedBox(height: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: Color(0xFF2B4C7E),
          ),
          textAlign: TextAlign.center,
        ),
      ],
      // Show items summary (profiles + medicines)
      ..._buildItemsSummaryWidgets(),
      // Fallback: show body text if no items summary
      if (_buildItemsSummaryWidgets().isEmpty && body.isNotEmpty) ...[
        const SizedBox(height: 4),
        Text(
          body,
          style: const TextStyle(fontSize: 14, color: Color(0xFF8A9BB5)),
          textAlign: TextAlign.center,
        ),
      ],
    ];
  }

  // Removing unused _buildAlarmItemCard method

  // Removed _exitToApp method

  void _onGreen() {
    debugPrint('▶️ _onGreen called: TAKE -> opening confirm');
    final logIds = _extractLogIds();
    if (logIds.isEmpty) {
      debugPrint('ไม่เจอ logId ใน notification payload');
      return;
    }
    // Mark user action BEFORE opening confirm screen
    NotificationLaunchGuard.markUserAction();
    //เป็นเมธอดที่ใช้บันทึกสถานะว่าผู้ใช้ได้ดำเนินการตอบสนองต่อการแจ้งเตือนแล้ว
    //เพื่อป้องกันไม่ให้ระบบประมวลผลการแจ้งเตือนเดิมซ้ำ
    //หรือเปิดหน้าจอแจ้งเตือนซ้อนกันหลายครั้ง
    _openConfirmAction(logIds: logIds);
  }

  Future<void> _processBatchAction(String responseStatus) async {
    debugPrint('▶️ _processBatchAction called with status: $responseStatus');
    if (_submitting) {
      debugPrint('⚠️ _processBatchAction blocked because _submitting=true');
      return;
    }

    final logIds = _extractLogIds();
    if (logIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Missing logId in notification payload')),
      );
      return;
    }

    // Mark user action for guard
    NotificationLaunchGuard.markUserAction();

    setState(() {
      _submitting = true;
    });

    try {
      debugPrint(
          '🔄 Fetching access token for batch action (Cold start protection)');
      final token = await AuthManager.service.getAccessToken();
      final api = LogApiService();

      // Execute all requests in parallel using Future.wait
      await Future.wait(
        logIds.map((id) => api.submitMedicationLogResponse(
              logId: id,
              responseStatus: responseStatus,
              accessToken: token,
            )),
      );

      if (!mounted) return;

      // Resolve profileId for /home navigation
      int? fallbackProfileId;

      // If payload has exactly ONE profileId, use it
      final items = _alarmItems();
      final uniqueIds = <int>{};
      for (final item in items) {
        final id = _toInt(item['profileId']);
        if (id != null && id > 0) uniqueIds.add(id);
      }
      if (uniqueIds.length == 1) {
        fallbackProfileId = uniqueIds.first;
      }

      // Otherwise, use lastSelectedProfileId from previous TAKE
      fallbackProfileId ??= AppState.instance.lastSelectedProfileId;

      // Final fallback: current profile
      fallbackProfileId ??= AppState.instance.currentProfileId;

      if (fallbackProfileId != null && fallbackProfileId > 0) {
        AppState.instance.setSelectedProfile(profileId: fallbackProfileId);
      }

      debugPrint('✅ Batch action success -> navigating to /home '
          'profileId=$fallbackProfileId');
      debugPrint(
          '📍 Current route before /home: ${AppRouteObserver.currentRouteName}');
      debugPrint(StackTrace.current.toString());

      Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil(
        '/home',
        (route) => false,
        arguments: {
          if (fallbackProfileId != null) 'profileId': fallbackProfileId,
        },
      );

      // Clear guard and handle deferred session redirect
      final shouldRedirectSession =
          NotificationLaunchGuard.clearAndCheckDeferred();
      if (shouldRedirectSession) {
        debugPrint('🔒 Deferred session redirect -> /login');
        navigatorKey.currentState?.pushNamedAndRemoveUntil(
          '/login',
          (route) => false,
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to $responseStatus: $e')),
      );
    }
  }

  void _onRed() {
    debugPrint('▶️ _onRed called: SKIP -> routing to /home');
    _processBatchAction('SKIP');
  }

  void _onSnooze(int minutes) {
    debugPrint('▶️ _onSnooze called: SNOOZE -> routing to /home');
    _processBatchAction('SNOOZE');
  }

  @override
  Widget build(BuildContext context) {
    final title = _titleText();
    final body = _bodyText();

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 228, 241, 255),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                const Text(
                  'MediBuddy',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2B4C7E),
                  ),
                ),

                // ✅ ส่วนหัว/รายละเอียด scroll ได้ตามเดิม
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: _headerWidgets(title, body),
                    ),
                  ),
                ),

                // ✅ ล็อกความสูงให้ slider -> ไม่เกิด infinite height
                SizedBox(
                  height: 360, // ปรับได้ เช่น 320/360/380
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: PillSlideAction(
                      onTake: _onGreen,
                      onSkip: _onRed,
                      onSnooze: () => _onSnooze(10),
                    ),
                  ),
                ),
              ],
            ),
            if (_submitting)
              Container(
                color: const Color.fromARGB(84, 196, 219, 240),
                child: const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF5A81BB),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

enum _SlideTarget { none, skip, take, snooze }

class PillSlideAction extends StatefulWidget {
  final VoidCallback onTake;
  final VoidCallback onSkip;
  final VoidCallback onSnooze;

  const PillSlideAction({
    required this.onTake,
    required this.onSkip,
    required this.onSnooze,
  });

  @override
  State<PillSlideAction> createState() => _PillSlideActionState();
}

class _PillSlideActionState extends State<PillSlideAction>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Animation<Offset> _animation = const AlwaysStoppedAnimation(Offset.zero);
  Offset _thumbOffset = Offset.zero;
  double _maxX = 0;
  double _maxUp = 0;
  double _maxDown = 0;
  _SlideTarget _activeTarget = _SlideTarget.none;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    )..addListener(() {
        setState(() {
          _thumbOffset = _animation.value;
        });
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _animateTo(Offset target) {
    _animation = Tween<Offset>(begin: _thumbOffset, end: target).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _controller.forward(from: 0);
  }

  _SlideTarget _resolveTarget(Offset offset) {
    final sideThreshold = _maxX * 0.55;
    final upThreshold = _maxUp * 0.55;

    if (_maxUp > 0 &&
        offset.dy <= -upThreshold &&
        offset.dy.abs() > offset.dx.abs()) {
      return _SlideTarget.snooze;
    }
    if (offset.dx <= -sideThreshold) return _SlideTarget.skip;
    if (offset.dx >= sideThreshold) return _SlideTarget.take;
    return _SlideTarget.none;
  }

  Offset _snapOffset(_SlideTarget target) {
    switch (target) {
      case _SlideTarget.skip:
        return Offset(-_maxX, 0);
      case _SlideTarget.take:
        return Offset(_maxX, 0);
      case _SlideTarget.snooze:
        return Offset(0, -_maxUp);
      case _SlideTarget.none:
        return Offset.zero;
    }
  }

  void _trigger(_SlideTarget target) {
    switch (target) {
      case _SlideTarget.skip:
        debugPrint('ACTION: SKIP');
        widget.onSkip();
        break;
      case _SlideTarget.take:
        debugPrint('ACTION: TAKE');
        widget.onTake();
        break;
      case _SlideTarget.snooze:
        debugPrint('ACTION: SNOOZE');
        widget.onSnooze();
        break;
      case _SlideTarget.none:
        break;
    }
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    if (_controller.isAnimating) {
      _controller.stop();
    }
    final next = _thumbOffset + details.delta;
    final clamped = Offset(
      next.dx.clamp(-_maxX, _maxX),
      next.dy.clamp(-_maxUp, _maxDown),
    );
    setState(() {
      _thumbOffset = clamped;
      _activeTarget = _resolveTarget(_thumbOffset);
    });
  }

  void _handlePanEnd(DragEndDetails details) {
    final target = _resolveTarget(_thumbOffset);
    if (target == _SlideTarget.none) {
      setState(() => _activeTarget = _SlideTarget.none);
      _animateTo(Offset.zero);
      return;
    }

    _trigger(target);
    _animateTo(_snapOffset(target));
    Future.delayed(const Duration(milliseconds: 220), () {
      if (!mounted) return;
      setState(() => _activeTarget = _SlideTarget.none);
      _animateTo(Offset.zero);
    });
  }

  @override
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final size = width.clamp(260.0, 360.0);
        final scale = size / 320.0;
        final pillWidth = 70.0 * scale;
        final pillHeight = 50.0 * scale;
        final iconSize = 36.0 * scale;
        final inset = 24.0 * scale;

        _maxX = (size / 2) - (pillWidth / 2) - inset;
        if (_maxX < 0) _maxX = 0;
        _maxUp = (size / 2) - (pillHeight / 2) - inset;
        if (_maxUp < 0) _maxUp = 0;
        _maxDown = 12.0 * scale;

        final isSkip = _activeTarget == _SlideTarget.skip;
        final isTake = _activeTarget == _SlideTarget.take;
        final isSnooze = _activeTarget == _SlideTarget.snooze;

        // ✅ ทำให้ widget นี้กินพื้นที่เต็มกว้างของ parent
        // แล้วจัดวงกลมไปล่างกลาง
        return SizedBox(
          width: double.infinity,
          height: constraints.maxHeight, // ให้ parent เป็นตัวกำหนดความสูง
          child: Align(
            alignment: Alignment.bottomCenter,
            child: SizedBox(
              width: size,
              height: size,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: size,
                    height: size,
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  Positioned(
                    left: inset,
                    child: _TargetIcon(
                      icon: Icons.close,
                      color: const Color(0xFFD98A8A),
                      active: isSkip,
                      size: iconSize,
                      label: 'Skip',
                    ),
                  ),
                  Positioned(
                    top: inset,
                    child: _TargetIcon(
                      icon: Icons.snooze,
                      color: const Color(0xFF8A9BB5),
                      active: isSnooze,
                      size: iconSize,
                      label: 'Snooze',
                    ),
                  ),
                  Positioned(
                    right: inset,
                    child: _TargetIcon(
                      icon: Icons.check,
                      color: const Color(0xFF6EB89C),
                      active: isTake,
                      size: iconSize,
                      label: 'Take',
                    ),
                  ),
                  GestureDetector(
                    onPanUpdate: _handlePanUpdate,
                    onPanEnd: _handlePanEnd,
                    child: Transform.translate(
                      offset: _thumbOffset,
                      child: _PillThumb(
                        width: pillWidth,
                        height: pillHeight,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TargetIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final bool active;
  final double size;
  final String label;

  const _TargetIcon({
    required this.icon,
    required this.color,
    required this.active,
    required this.size,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final opacity = active ? 1.0 : 0.5;
    final scale = active ? 1.1 : 1.0;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 120),
      opacity: opacity,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 120),
        scale: scale,
        child: Column(
          children: [
            Icon(icon, color: color, size: size),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PillThumb extends StatelessWidget {
  final double width;
  final double height;

  const _PillThumb({
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(height / 2),
        border: Border.all(color: const Color(0xFFB7DAFF), width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A7BAEE5),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
    );
  }
}
