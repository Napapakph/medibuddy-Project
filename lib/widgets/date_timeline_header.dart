import 'package:flutter/material.dart';

class DateTimelineHeader extends StatelessWidget {
  const DateTimelineHeader({
    super.key,
    required this.displayedDate,
    required this.today,
    required this.maxForwardDays,
    this.onTapCalendar,
    this.onTapNext,
    required this.canGoNext,
    this.formatDayNumber,
    this.formatMonthLabel,
    this.formatYearLabel,
  });

  final DateTime displayedDate;
  final DateTime today;
  final int maxForwardDays;

  /// Tap anywhere on the header to open calendar/date picker (handled by parent).
  final VoidCallback? onTapCalendar;

  /// Optional quick jump to next day (parent should animate PageController).
  final VoidCallback? onTapNext;

  /// If false, hide/disable swipe hint and next day preview.
  final bool canGoNext;

  /// Optional formatting overrides (recommended: pass your existing formatter from Home).
  final String Function(DateTime date)? formatDayNumber; // e.g. "6"
  final String Function(DateTime date)? formatMonthLabel; // e.g. "กุมภาพันธ์"
  final String Function(DateTime date)? formatYearLabel; // e.g. "2569"

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final active = _dateOnly(displayedDate);
    final next = _dateOnly(displayedDate.add(const Duration(days: 1)));

    final activeKey = _keyFor(active);

    final activeDay = (formatDayNumber ?? _defaultDayNumber)(active);
    final activeMonth = (formatMonthLabel ?? _defaultThaiMonth)(active);
    final activeYear = (formatYearLabel ?? _defaultThaiBuddhistYear)(active);

    final nextDay = (formatDayNumber ?? _defaultDayNumber)(next);
    final nextMonth = (formatMonthLabel ?? _defaultThaiMonth)(next);

    final activeColor = theme.colorScheme.primary;
    final hintColor =
        theme.textTheme.bodyMedium?.color?.withOpacity(0.55) ?? Colors.black54;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTapCalendar,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.black.withOpacity(0.06)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Active date (center focus feel but left-aligned within row)
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeOut,
                  transitionBuilder: (child, animation) {
                    final fade = CurvedAnimation(
                        parent: animation, curve: Curves.easeOut);
                    final slide = Tween<Offset>(
                      begin: const Offset(0.04, 0),
                      end: Offset.zero,
                    ).animate(fade);
                    return FadeTransition(
                      opacity: fade,
                      child: SlideTransition(position: slide, child: child),
                    );
                  },
                  child: _ActiveDateBlock(
                    key: ValueKey(activeKey),
                    dayNumber: activeDay,
                    monthLabel: activeMonth,
                    yearLabel: activeYear,
                    subtitle: _labelTodayOrFuture(active, today),
                    color: activeColor,
                  ),
                ),
              ),

              const SizedBox(width: 10),

              // Next day preview + arrow hint
              AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: canGoNext ? 1.0 : 0.0,
                child: IgnorePointer(
                  ignoring: !canGoNext,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _NextDateHint(
                        dayNumber: nextDay,
                        monthLabel: nextMonth,
                        color: hintColor,
                        onTap: onTapNext,
                      ),
                      const SizedBox(width: 8),
                      _ArrowHint(
                        enabled: canGoNext,
                        color: hintColor,
                        onTap: onTapNext,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static DateTime _dateOnly(DateTime d) => DateUtils.dateOnly(d);

  static String _keyFor(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static String _defaultDayNumber(DateTime d) => d.day.toString();

  static String _defaultThaiBuddhistYear(DateTime d) =>
      (d.year + 543).toString();

  static String _defaultThaiMonth(DateTime d) {
    const months = <int, String>{
      1: 'มกราคม',
      2: 'กุมภาพันธ์',
      3: 'มีนาคม',
      4: 'เมษายน',
      5: 'พฤษภาคม',
      6: 'มิถุนายน',
      7: 'กรกฎาคม',
      8: 'สิงหาคม',
      9: 'กันยายน',
      10: 'ตุลาคม',
      11: 'พฤศจิกายน',
      12: 'ธันวาคม',
    };
    return months[d.month] ?? '';
  }

  static String _labelTodayOrFuture(DateTime active, DateTime today) {
    final a = _dateOnly(active);
    final t = _dateOnly(today);
    final diff = a.difference(t).inDays;
    if (diff == 0) return 'วันนี้';
    if (diff == 1) return 'พรุ่งนี้';
    return 'อีก $diff วัน';
  }
}

class _ActiveDateBlock extends StatelessWidget {
  const _ActiveDateBlock({
    super.key,
    required this.dayNumber,
    required this.monthLabel,
    required this.yearLabel,
    required this.subtitle,
    required this.color,
  });

  final String dayNumber;
  final String monthLabel;
  final String yearLabel;
  final String subtitle;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          dayNumber,
          style: t.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: color,
            height: 1.0,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$monthLabel $yearLabel',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: t.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: t.bodySmall?.copyWith(
                  color: Colors.black.withOpacity(0.55),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _NextDateHint extends StatelessWidget {
  const _NextDateHint({
    required this.dayNumber,
    required this.monthLabel,
    required this.color,
    this.onTap,
  });

  final String dayNumber;
  final String monthLabel;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          children: [
            Text(
              dayNumber,
              style: t.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              monthLabel,
              style: t.bodyMedium?.copyWith(
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

class _ArrowHint extends StatelessWidget {
  const _ArrowHint({
    required this.enabled,
    required this.color,
    this.onTap,
  });

  final bool enabled;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(999),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(
          Icons.arrow_forward_ios_rounded,
          size: 16,
          color: enabled ? color : color.withOpacity(0.2),
        ),
      ),
    );
  }
}
