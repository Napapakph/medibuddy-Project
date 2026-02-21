import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:medibuddy/Home/pages/alarm_medicine/confirm_action.dart';

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
      final decoded = raw is String ? jsonDecode(raw) : raw;
      if (decoded is! List) return [];
      final items = <Map<String, dynamic>>[];
      for (final item in decoded) {
        if (item is Map) {
          items.add(item.map((key, value) => MapEntry(key.toString(), value)));
        }
      }
      return items;
    } catch (e) {
      debugPrint('❌ Failed to decode payload list: $e');
      return [];
    }
  }

  List<Map<String, dynamic>> _alarmItems() {
    final normalized = _normalizedPayload();

    // Check for "payload" field which might contain a JSON string of items
    if (normalized['payload'] is String) {
      try {
        final decoded = jsonDecode(normalized['payload']);
        if (decoded is List) {
          return decoded
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
        }
      } catch (e) {
        debugPrint('Error parsing payload string: $e');
      }
    }

    final fromItems = _parsePayloadItems(normalized['items']);
    if (fromItems.isNotEmpty) return fromItems;

    // Fallback: Check if payload is directly a list (rare)
    return _parsePayloadItems(normalized['payload']);
  }

  int? _parseLogId(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
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

  void _openConfirmAction({required List<int> logIds}) {
    if (_submitting) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ConfirmActionScreen(
          logIds: logIds,
          payload: widget.payload,
          headerTimeText: _timeText(),
        ),
      ),
    );
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

  String _titleText() => _normalizedPayload()['title']?.toString() ?? '';
  String _bodyText() => _normalizedPayload()['body']?.toString() ?? '';

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
        ),
      ),
      if (title.isNotEmpty) ...[
        const SizedBox(height: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
          textAlign: TextAlign.center,
        ),
      ],
      if (body.isNotEmpty) ...[
        const SizedBox(height: 4),
        Text(
          body,
          style: const TextStyle(fontSize: 14, color: Colors.black54),
          textAlign: TextAlign.center,
        ),
      ],
    ];
  }

  // Removing unused _buildAlarmItemCard method

  // Removed _exitToApp method

  void _onGreen() {
    debugPrint('Alarm action: taken');
    final logIds = _extractLogIds();
    if (logIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Missing logId in notification payload')),
      );
      return;
    }
    _openConfirmAction(logIds: logIds);
    // _submitResponse('TAKE');
  }

  void _onRed() {
    debugPrint('Alarm action: skip');
    final logIds = _extractLogIds();
    if (logIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Missing logId in notification payload')),
      );
      return;
    }
    _openConfirmAction(logIds: logIds);
  }

  void _onSnooze(int minutes) {
    debugPrint('Alarm action: snooze $minutes minutes');
    final logIds = _extractLogIds();
    if (logIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Missing logId in notification payload')),
      );
      return;
    }
    _openConfirmAction(logIds: logIds);
  }

  @override
  Widget build(BuildContext context) {
    final title = _titleText();
    final body = _bodyText();

    return Scaffold(
      backgroundColor: const Color(0xFFF6F2EA),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 12),
            const Text(
              'MediBuddy',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: _headerWidgets(title, body),
              ),
            ),
            const SizedBox(height: 24),
            PillSlideAction(
              onTake: _onGreen,
              onSkip: _onRed,
              onSnooze: () => _onSnooze(10),
            ),
            const SizedBox(height: 16),
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

        return SizedBox(
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
                  color: Colors.red,
                  active: isSkip,
                  size: iconSize,
                  label: 'Skip',
                ),
              ),
              Positioned(
                top: inset,
                child: _TargetIcon(
                  icon: Icons.snooze,
                  color: Colors.black87,
                  active: isSnooze,
                  size: iconSize,
                  label: 'Snooze',
                ),
              ),
              Positioned(
                right: inset,
                child: _TargetIcon(
                  icon: Icons.check,
                  color: Colors.green,
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
        border: Border.all(color: Colors.black12, width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
    );
  }
}
