import 'dart:convert';
import 'package:flutter/material.dart';

class AlarmScreen extends StatefulWidget {
  final Map<String, dynamic>? payload;

  const AlarmScreen({super.key, this.payload});

  @override
  State<AlarmScreen> createState() => _AlarmScreenState();
}

class _AlarmScreenState extends State<AlarmScreen> {
  late final PageController _pageController;
  int _menuIndex = 0;

  @override
  void initState() {
    super.initState();
    debugPrint('✅ AlarmScreen opened args=${widget.payload}');
    _menuIndex = _parseMenuIndex(widget.payload?['menuIndex']);
    _pageController = PageController(initialPage: _menuIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  int _parseMenuIndex(dynamic value) {
    if (value is int) {
      return value.clamp(0, 2);
    }
    if (value != null) {
      final parsed = int.tryParse(value.toString());
      if (parsed != null) return parsed.clamp(0, 2);
    }
    return 0;
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
    final rawTime = widget.payload?['time']?.toString().trim();
    if (rawTime != null && rawTime.isNotEmpty) {
      return rawTime;
    }

    final fromSchedule = _timeFromScheduleTime(widget.payload?['scheduleTime']);
    if (fromSchedule.isNotEmpty) return fromSchedule;

    return '12:00';
  }

  String _titleText() => widget.payload?['title']?.toString() ?? '';
  String _bodyText() => widget.payload?['body']?.toString() ?? '';

  // ✅ NEW: exit helper (return to previous screen safely)
  void _exitToApp({required String action, int? snoozeMinutes}) {
    final payload = widget.payload ?? {};

    debugPrint(
        '✅ Alarm action="$action" payload=$payload snooze=$snoozeMinutes');

    // (optional) ส่งผลลัพธ์กลับไปหน้าก่อนหน้า เผื่ออยากเอาไปใช้ต่อ
    final result = <String, dynamic>{
      'action': action,
      'snoozeMinutes': snoozeMinutes,
      'payload': payload,
    };

    // ถ้า stack มีหลายหน้า -> popUntil หน้าแรกของแอพ
    // ถ้าเปิดมาจาก noti แล้วมีแค่หน้าเดียว -> popUntil จะไม่พัง และยังอยู่หน้าแรก
    Navigator.of(context).popUntil((route) => route.isFirst);

    // ถ้าอยากให้ "ปิด AlarmScreen" เฉพาะหน้าเดียว (กลับไปหน้าก่อนหน้าแบบเป๊ะ)
    // ใช้บรรทัดนี้แทน popUntil:
    // if (Navigator.of(context).canPop()) Navigator.of(context).pop(result);
  }

  void _onGreen() {
    debugPrint('Alarm action: taken');
    _exitToApp(action: 'taken');
  }

  void _onRed() {
    debugPrint('Alarm action: skip');
    _exitToApp(action: 'skip');
  }

  void _onSnooze(int minutes) {
    debugPrint('Alarm action: snooze $minutes minutes');
    _exitToApp(action: 'snooze', snoozeMinutes: minutes);
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
                children: [
                  Image.asset(
                    'assets/main_mascot.png',
                    width: 160,
                    height: 160,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _timeText(), // ✅ now shows scheduleTime/time
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
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  if (body.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      body,
                      style:
                          const TextStyle(fontSize: 14, color: Colors.black54),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(
              height: 130,
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) => setState(() => _menuIndex = index),
                children: [
                  const _MenuCard(
                    title: 'Taken',
                    subtitle: 'Confirm you took the dose',
                    color: Colors.green,
                  ),
                  const _MenuCard(
                    title: 'Skip',
                    subtitle: 'Dismiss this dose',
                    color: Colors.red,
                  ),
                  _SnoozeMenu(onSelect: _onSnooze),
                ],
              ),
            ),
            const SizedBox(height: 8),
            _MenuIndicator(index: _menuIndex),
            const SizedBox(height: 12),
            _ActionRing(
              onRed: _onRed,
              onGreen: _onGreen,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color color;

  const _MenuCard({
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 14, color: Colors.black54),
          ),
        ],
      ),
    );
  }
}

class _SnoozeMenu extends StatelessWidget {
  final void Function(int minutes) onSelect;

  const _SnoozeMenu({required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Snooze',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              _SnoozeChip(label: '5 min', onTap: () => onSelect(5)),
              _SnoozeChip(label: '10 min', onTap: () => onSelect(10)),
              _SnoozeChip(label: '15 min', onTap: () => onSelect(15)),
            ],
          ),
        ],
      ),
    );
  }
}

class _SnoozeChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _SnoozeChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.black87,
        side: const BorderSide(color: Colors.black26),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      child: Text(label),
    );
  }
}

class _MenuIndicator extends StatelessWidget {
  final int index;

  const _MenuIndicator({required this.index});

  @override
  Widget build(BuildContext context) {
    const labels = ['Taken', 'Skip', 'Snooze'];
    return Column(
      children: [
        Text(
          'Menu: ${labels[index]}',
          style: const TextStyle(fontSize: 13, color: Colors.black54),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            labels.length,
            (i) => Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i == index ? Colors.black87 : Colors.black26,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionRing extends StatelessWidget {
  final VoidCallback onRed;
  final VoidCallback onGreen;

  const _ActionRing({required this.onRed, required this.onGreen});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      height: 70,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: Colors.black12, width: 2),
        color: Colors.white,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _ActionButton(
            color: Colors.red,
            icon: Icons.close,
            onTap: onRed,
          ),
          _ActionButton(
            color: Colors.green,
            icon: Icons.check,
            onTap: onGreen,
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  const _ActionButton({
    required this.color,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, color: Colors.white),
      ),
    );
  }
}
