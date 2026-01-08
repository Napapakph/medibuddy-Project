import 'dart:io';

import 'package:flutter/material.dart';
import 'package:medibuddy/Model/medicine_model.dart';

enum FrequencyMode { timesPerDay, everyHours }

enum FrequencyPattern { everyDay, someDays, everyInterval }

enum DurationMode { forever, custom }

enum MealTiming { beforeMeal, betweenMeals, afterMeal }

class ReminderDose {
  TimeOfDay time;
  String amount;
  String unit;
  MealTiming mealTiming;

  ReminderDose({
    required this.time,
    this.amount = '1',
    this.unit = 'เม็ด',
    this.mealTiming = MealTiming.afterMeal,
  });

  ReminderDose copyWith({
    TimeOfDay? time,
    String? amount,
    String? unit,
    MealTiming? mealTiming,
  }) {
    return ReminderDose(
      time: time ?? this.time,
      amount: amount ?? this.amount,
      unit: unit ?? this.unit,
      mealTiming: mealTiming ?? this.mealTiming,
    );
  }
}

class ReminderPlan {
  final String id;
  final MedicineItem medicine;
  final FrequencyMode frequencyMode;
  final int timesPerDay;
  final int everyHours;
  final FrequencyPattern frequencyPattern;
  final Set<int> weekdays;
  final int everyCount;
  final String everyUnit;
  final DurationMode durationMode;
  final int durationValue;
  final String durationUnit;
  final TimeOfDay startTime;
  final List<ReminderDose> doses;

  const ReminderPlan({
    required this.id,
    required this.medicine,
    required this.frequencyMode,
    required this.timesPerDay,
    required this.everyHours,
    required this.frequencyPattern,
    required this.weekdays,
    required this.everyCount,
    required this.everyUnit,
    required this.durationMode,
    required this.durationValue,
    required this.durationUnit,
    required this.startTime,
    required this.doses,
  });

  ReminderPlan copyWith({
    MedicineItem? medicine,
    FrequencyMode? frequencyMode,
    int? timesPerDay,
    int? everyHours,
    FrequencyPattern? frequencyPattern,
    Set<int>? weekdays,
    int? everyCount,
    String? everyUnit,
    DurationMode? durationMode,
    int? durationValue,
    String? durationUnit,
    TimeOfDay? startTime,
    List<ReminderDose>? doses,
  }) {
    return ReminderPlan(
      id: id,
      medicine: medicine ?? this.medicine,
      frequencyMode: frequencyMode ?? this.frequencyMode,
      timesPerDay: timesPerDay ?? this.timesPerDay,
      everyHours: everyHours ?? this.everyHours,
      frequencyPattern: frequencyPattern ?? this.frequencyPattern,
      weekdays: weekdays ?? this.weekdays,
      everyCount: everyCount ?? this.everyCount,
      everyUnit: everyUnit ?? this.everyUnit,
      durationMode: durationMode ?? this.durationMode,
      durationValue: durationValue ?? this.durationValue,
      durationUnit: durationUnit ?? this.durationUnit,
      startTime: startTime ?? this.startTime,
      doses: doses ?? this.doses,
    );
  }

  String get frequencyLabel {
    if (frequencyMode == FrequencyMode.timesPerDay) {
      return '$timesPerDay ครั้งต่อวัน';
    }
    return 'ทุก $everyHours ชั่วโมง';
  }

  String get durationLabel {
    if (durationMode == DurationMode.forever) return 'ตลอดไป';
    return '$durationValue $durationUnit';
  }
}

ImageProvider? buildMedicineImage(String path) {
  if (path.isEmpty) return null;
  if (path.startsWith('http')) return NetworkImage(path);
  return FileImage(File(path));
}

String formatTime(TimeOfDay time) {
  final hour = time.hour.toString().padLeft(2, '0');
  final minute = time.minute.toString().padLeft(2, '0');
  return '$hour:$minute น.';
}

Widget type_frequency({
  required BuildContext context,
  required String title,
  required String subtitle,
  required List<MedicineItem> medicines,
  required MedicineItem? selectedMedicine,
  required ValueChanged<MedicineItem?> onMedicineChanged,
  required FrequencyMode frequencyMode,
  required ValueChanged<FrequencyMode> onFrequencyModeChanged,
  required TextEditingController timesPerDayController,
  required TextEditingController everyHoursController,
  required FrequencyPattern frequencyPattern,
  required ValueChanged<FrequencyPattern> onFrequencyPatternChanged,
  required Set<int> selectedWeekdays,
  required ValueChanged<Set<int>> onWeekdaysChanged,
  required TextEditingController everyCountController,
  required String everyUnit,
  required ValueChanged<String?> onEveryUnitChanged,
  required DurationMode durationMode,
  required ValueChanged<DurationMode> onDurationModeChanged,
  required TextEditingController durationValueController,
  required String durationUnit,
  required ValueChanged<String?> onDurationUnitChanged,
  VoidCallback? onAddMedicine,
}) {
  final hasMedicines = medicines.isNotEmpty;
  final avatarImage = buildMedicineImage(selectedMedicine?.imagePath ?? '');

  final weekDayLabels = const [
    'จ.',
    'อ.',
    'พ.',
    'พฤ.',
    'ศ.',
    'ส.',
    'อา.',
  ];

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: Color(0xFF1F497D),
        ),
      ),
      const SizedBox(height: 4),
      Text(
        subtitle,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1F497D),
        ),
      ),
      const SizedBox(height: 16),
      const Text(
        'รูปแบบและความถี่การรับประทานยา',
        style: TextStyle(fontWeight: FontWeight.w600),
      ),
      const SizedBox(height: 8),
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF2F4F8),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFFE3EAF6),
                borderRadius: BorderRadius.circular(12),
                image: avatarImage != null
                    ? DecorationImage(image: avatarImage, fit: BoxFit.cover)
                    : null,
              ),
              child: avatarImage == null
                  ? const Icon(Icons.medication, color: Color(0xFF1F497D))
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<MedicineItem>(
                value: selectedMedicine,
                isExpanded: true,
                hint: const Text('เลือกรายการยา'),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                items: medicines
                    .map(
                      (item) => DropdownMenuItem(
                        value: item,
                        child: Text(item.displayName),
                      ),
                    )
                    .toList(),
                onChanged: hasMedicines ? onMedicineChanged : null,
              ),
            ),
            IconButton(
              onPressed: onAddMedicine,
              icon: const Icon(Icons.add_circle, color: Color(0xFF6FA8DC)),
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF2F4F8),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'รูปแบบการรับประทานยา',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Radio<FrequencyMode>(
                  value: FrequencyMode.timesPerDay,
                  groupValue: frequencyMode,
                  onChanged: (value) {
                    if (value != null) onFrequencyModeChanged(value);
                  },
                ),
                const Text('จำนวน'),
                const SizedBox(width: 8),
                SizedBox(
                  width: 72,
                  child: TextField(
                    controller: timesPerDayController,
                    enabled: frequencyMode == FrequencyMode.timesPerDay,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      isDense: true,
                      border: OutlineInputBorder(borderSide: BorderSide.none),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Text('ครั้งต่อวัน'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Radio<FrequencyMode>(
                  value: FrequencyMode.everyHours,
                  groupValue: frequencyMode,
                  onChanged: (value) {
                    if (value != null) onFrequencyModeChanged(value);
                  },
                ),
                const Text('ทุก'),
                const SizedBox(width: 8),
                SizedBox(
                  width: 72,
                  child: TextField(
                    controller: everyHoursController,
                    enabled: frequencyMode == FrequencyMode.everyHours,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      isDense: true,
                      border: OutlineInputBorder(borderSide: BorderSide.none),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Text('ชั่วโมง'),
              ],
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF2F4F8),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ความถี่ในการรับประทานยา',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            RadioListTile<FrequencyPattern>(
              value: FrequencyPattern.everyDay,
              groupValue: frequencyPattern,
              onChanged: (value) {
                if (value != null) onFrequencyPatternChanged(value);
              },
              title: const Text('ทุกวัน'),
              dense: true,
              contentPadding: EdgeInsets.zero,
            ),
            RadioListTile<FrequencyPattern>(
              value: FrequencyPattern.someDays,
              groupValue: frequencyPattern,
              onChanged: (value) {
                if (value != null) onFrequencyPatternChanged(value);
              },
              title: const Text('บางวัน'),
              dense: true,
              contentPadding: EdgeInsets.zero,
            ),
            Wrap(
              spacing: 6,
              children: List.generate(7, (index) {
                final dayIndex = index + 1;
                final isSelected = selectedWeekdays.contains(dayIndex);
                final isEnabled = frequencyPattern == FrequencyPattern.someDays;

                return FilterChip(
                  label: Text(weekDayLabels[index]),
                  selected: isSelected,
                  onSelected: isEnabled
                      ? (value) {
                          final updated = Set<int>.from(selectedWeekdays);
                          if (value) {
                            updated.add(dayIndex);
                          } else {
                            updated.remove(dayIndex);
                          }
                          onWeekdaysChanged(updated);
                        }
                      : null,
                );
              }),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Radio<FrequencyPattern>(
                  value: FrequencyPattern.everyInterval,
                  groupValue: frequencyPattern,
                  onChanged: (value) {
                    if (value != null) onFrequencyPatternChanged(value);
                  },
                ),
                const Text('ทุก'),
                const SizedBox(width: 8),
                SizedBox(
                  width: 72,
                  child: TextField(
                    controller: everyCountController,
                    enabled: frequencyPattern == FrequencyPattern.everyInterval,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      isDense: true,
                      border: OutlineInputBorder(borderSide: BorderSide.none),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: everyUnit,
                  underline: const SizedBox.shrink(),
                  items: const [
                    DropdownMenuItem(value: 'วัน', child: Text('วัน')),
                    DropdownMenuItem(value: 'เดือน', child: Text('เดือน')),
                    DropdownMenuItem(value: 'ปี', child: Text('ปี')),
                  ],
                  onChanged: frequencyPattern == FrequencyPattern.everyInterval
                      ? onEveryUnitChanged
                      : null,
                ),
              ],
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      const Text(
        'ระยะเวลา',
        style: TextStyle(fontWeight: FontWeight.w600),
      ),
      const SizedBox(height: 8),
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF2F4F8),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            RadioListTile<DurationMode>(
              value: DurationMode.forever,
              groupValue: durationMode,
              onChanged: (value) {
                if (value != null) onDurationModeChanged(value);
              },
              title: const Text('ตลอดไป'),
              dense: true,
              contentPadding: EdgeInsets.zero,
            ),
            Row(
              children: [
                Radio<DurationMode>(
                  value: DurationMode.custom,
                  groupValue: durationMode,
                  onChanged: (value) {
                    if (value != null) onDurationModeChanged(value);
                  },
                ),
                const Text('ระยะเวลา'),
                const SizedBox(width: 8),
                SizedBox(
                  width: 72,
                  child: TextField(
                    controller: durationValueController,
                    enabled: durationMode == DurationMode.custom,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      isDense: true,
                      border: OutlineInputBorder(borderSide: BorderSide.none),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: durationUnit,
                  underline: const SizedBox.shrink(),
                  items: const [
                    DropdownMenuItem(value: 'วัน', child: Text('วัน')),
                    DropdownMenuItem(value: 'สัปดาห์', child: Text('สัปดาห์')),
                    DropdownMenuItem(value: 'ปี', child: Text('ปี')),
                  ],
                  onChanged: durationMode == DurationMode.custom
                      ? onDurationUnitChanged
                      : null,
                ),
              ],
            ),
          ],
        ),
      ),
    ],
  );
}

Widget detail_time({
  required BuildContext context,
  required String title,
  required String subtitle,
  required MedicineItem? selectedMedicine,
  required FrequencyMode frequencyMode,
  required int timesPerDay,
  required int everyHours,
  required TimeOfDay startTime,
  required ValueChanged<TimeOfDay> onStartTimeChanged,
  required List<ReminderDose> doses,
  required void Function(int, ReminderDose) onDoseChanged,
}) {
  final avatarImage = buildMedicineImage(selectedMedicine?.imagePath ?? '');
  final medicineName = selectedMedicine?.displayName ?? 'ยังไม่เลือกยา';
  final enabledTimes = frequencyMode == FrequencyMode.timesPerDay;
  final timeLabel = frequencyMode == FrequencyMode.timesPerDay
      ? '$timesPerDay ครั้งต่อวัน'
      : 'ทุก $everyHours ชั่วโมง';

  Future<void> pickTime(int index) async {
    final selected = await showTimePicker(
      context: context,
      initialTime: doses[index].time,
    );
    if (selected == null) return;
    onDoseChanged(index, doses[index].copyWith(time: selected));
  }

  Future<void> pickStartTime() async {
    final selected = await showTimePicker(
      context: context,
      initialTime: startTime,
    );
    if (selected == null) return;
    onStartTimeChanged(selected);
  }

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: Color(0xFF1F497D),
        ),
      ),
      const SizedBox(height: 4),
      Text(
        subtitle,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1F497D),
        ),
      ),
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF2F4F8),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFFE3EAF6),
                borderRadius: BorderRadius.circular(12),
                image: avatarImage != null
                    ? DecorationImage(image: avatarImage, fit: BoxFit.cover)
                    : null,
              ),
              child: avatarImage == null
                  ? const Icon(Icons.medication, color: Color(0xFF1F497D))
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                medicineName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF2F4F8),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const Text('จำนวน', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(width: 12),
            Text(
              timeLabel,
              style: const TextStyle(color: Color(0xFF1F497D)),
            ),
          ],
        ),
      ),
      if (!enabledTimes) ...[
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF2F4F8),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              const Text('เริ่มต้นเวลา'),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: pickStartTime,
                child: Text(formatTime(startTime)),
              ),
              const Spacer(),
              Text('ทุก $everyHours ชั่วโมง'),
            ],
          ),
        ),
      ],
      const SizedBox(height: 16),
      Column(
        children: List.generate(doses.length, (index) {
          final dose = doses[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFD6E3F3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('เวลา'),
                    const SizedBox(width: 8),
                    Expanded(
                      child: InkWell(
                        onTap: enabledTimes ? () => pickTime(index) : null,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: enabledTimes
                                ? const Color(0xFFE8F1FF)
                                : const Color(0xFFF2F4F8),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            enabledTimes
                                ? formatTime(dose.time)
                                : 'ทุก $everyHours ชั่วโมง',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 56,
                      child: TextFormField(
                        initialValue: dose.amount,
                        onChanged: (value) {
                          onDoseChanged(
                            index,
                            dose.copyWith(amount: value.isEmpty ? '0' : value),
                          );
                        },
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          isDense: true,
                          filled: true,
                          fillColor: Color(0xFFE8F1FF),
                          border:
                              OutlineInputBorder(borderSide: BorderSide.none),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    DropdownButton<String>(
                      value: dose.unit,
                      underline: const SizedBox.shrink(),
                      items: const [
                        DropdownMenuItem(value: 'เม็ด', child: Text('เม็ด')),
                        DropdownMenuItem(
                            value: 'มิลลิลิตร', child: Text('มิลลิลิตร')),
                        DropdownMenuItem(
                            value: 'มิลลิกรัม', child: Text('มิลลิกรัม')),
                        DropdownMenuItem(value: 'เข็ม', child: Text('เข็ม')),
                        DropdownMenuItem(
                            value: 'ยาหยอด', child: Text('ยาหยอด')),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        onDoseChanged(index, dose.copyWith(unit: value));
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _MealTimingRow(
                  value: dose.mealTiming,
                  onChanged: (timing) {
                    onDoseChanged(index, dose.copyWith(mealTiming: timing));
                  },
                ),
              ],
            ),
          );
        }),
      ),
    ],
  );
}

Widget summary_rejimen({
  required BuildContext context,
  required String title,
  required String subtitle,
  required MedicineItem? selectedMedicine,
  required FrequencyMode frequencyMode,
  required int timesPerDay,
  required int everyHours,
  required List<ReminderDose> doses,
}) {
  final avatarImage = buildMedicineImage(selectedMedicine?.imagePath ?? '');
  final medicineName = selectedMedicine?.displayName ?? 'ยังไม่เลือกยา';
  final frequencyLabel = frequencyMode == FrequencyMode.timesPerDay
      ? '$timesPerDay ครั้งต่อวัน'
      : 'ทุก $everyHours ชั่วโมง';

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: Color(0xFF1F497D),
        ),
      ),
      const SizedBox(height: 4),
      Text(
        subtitle,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1F497D),
        ),
      ),
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF2F4F8),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFFE3EAF6),
                borderRadius: BorderRadius.circular(12),
                image: avatarImage != null
                    ? DecorationImage(image: avatarImage, fit: BoxFit.cover)
                    : null,
              ),
              child: avatarImage == null
                  ? const Icon(Icons.medication, color: Color(0xFF1F497D))
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    medicineName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    frequencyLabel,
                    style: const TextStyle(color: Color(0xFF6B7C93)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFD6E3F3)),
        ),
        child: Column(
          children: doses.map((dose) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  SizedBox(
                    width: 80,
                    child: Text(
                      formatTime(dose.time),
                      style: const TextStyle(
                        color: Color(0xFF1F497D),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'ปริมาณ ${dose.amount} ${dose.unit}',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  MealTimingIcon(timing: dose.mealTiming),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    ],
  );
}

class _MealTimingRow extends StatelessWidget {
  final MealTiming value;
  final ValueChanged<MealTiming> onChanged;

  const _MealTimingRow({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _MealTimingOption(
          timing: MealTiming.beforeMeal,
          label: 'ก่อนอาหาร',
          icon: Icons.restaurant,
          selected: value == MealTiming.beforeMeal,
          onTap: () => onChanged(MealTiming.beforeMeal),
        ),
        _MealTimingOption(
          timing: MealTiming.betweenMeals,
          label: 'ระหว่างมื้อ',
          icon: Icons.restaurant_menu,
          selected: value == MealTiming.betweenMeals,
          onTap: () => onChanged(MealTiming.betweenMeals),
        ),
        _MealTimingOption(
          timing: MealTiming.afterMeal,
          label: 'หลังอาหาร',
          icon: Icons.local_dining,
          selected: value == MealTiming.afterMeal,
          onTap: () => onChanged(MealTiming.afterMeal),
        ),
      ],
    );
  }
}

class _MealTimingOption extends StatelessWidget {
  final MealTiming timing;
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _MealTimingOption({
    required this.timing,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? const Color(0xFF1F497D) : const Color(0xFF9DB3D4);

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            if (selected)
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Color(0xFF1F497D),
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class MealTimingIcon extends StatelessWidget {
  final MealTiming timing;

  const MealTimingIcon({required this.timing});

  @override
  Widget build(BuildContext context) {
    IconData icon;
    switch (timing) {
      case MealTiming.beforeMeal:
        icon = Icons.restaurant;
        break;
      case MealTiming.betweenMeals:
        icon = Icons.restaurant_menu;
        break;
      case MealTiming.afterMeal:
        icon = Icons.local_dining;
        break;
    }

    return Icon(icon, color: const Color(0xFF1F497D));
  }
}
