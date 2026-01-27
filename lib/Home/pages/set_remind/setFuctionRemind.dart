import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/material.dart';
import 'package:medibuddy/Model/medicine_regimen_model.dart';
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
  final int mediListId;

  /// id ที่ server สร้างให้ (จาก POST /medicine-regimen/create)
  final int? mediRegimenId;

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
    required this.mediListId,
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
    this.mediRegimenId,
  });

  ReminderPlan copyWith({
    int? mediRegimenId,
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
      mediListId: mediListId ?? this.mediListId,
      mediRegimenId: mediRegimenId ?? this.mediRegimenId,
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

String _toFullImageUrl(String raw) {
  final base = (dotenv.env['API_BASE_URL'] ?? '').trim();
  final p = raw.trim();

  if (p.isEmpty || p.toLowerCase() == 'null') return '';

  // already full url
  if (p.startsWith('http://') || p.startsWith('https://')) return p;

  if (base.isEmpty) return '';

  try {
    final baseUri = Uri.parse(base);
    final normalizedPath = p.startsWith('/') ? p : '/$p';
    return baseUri.resolve(normalizedPath).toString();
  } catch (e) {
    debugPrint('❌ image url build failed: base=$base raw=$raw err=$e');
    return '';
  }
}

ImageProvider? buildMedicineImage(String raw) {
  debugPrint('🖼️ [MedicineImage] raw="$raw"');

  final trimmed = raw.trim();
  if (trimmed.isEmpty || trimmed.toLowerCase() == 'null') return null;

  final isLocalFile = trimmed.startsWith('/') ||
      trimmed.startsWith('file://') ||
      trimmed.contains(':\\');

  if (isLocalFile) {
    final filePath = trimmed.startsWith('file://')
        ? Uri.parse(trimmed).toFilePath()
        : trimmed;
    final file = File(filePath);
    final exists = file.existsSync();
    debugPrint(
      '🖼️ [MedicineImage] local file="$filePath" exists=$exists',
    );
    if (!exists) return null;
    return FileImage(file);
  }

  final url = _toFullImageUrl(trimmed);
  debugPrint('🖼️ [MedicineImage] network url="$url"');
  if (url.isEmpty) return null;
  return NetworkImage(url);
}

String formatTime(TimeOfDay time) {
  final hour = time.hour.toString().padLeft(2, '0');
  final minute = time.minute.toString().padLeft(2, '0');
  return '$hour:$minute น.';
}

String formatTimeValue(TimeOfDay time) {
  final hour = time.hour.toString().padLeft(2, '0');
  final minute = time.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
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
  final image = buildMedicineImage(selectedMedicine?.imagePath ?? '');

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
                image: image != null
                    ? DecorationImage(image: image, fit: BoxFit.cover)
                    : null,
              ),
              child: image == null
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
                        child: Text(
                          item.nickname_medi,
                          overflow: TextOverflow.ellipsis,
                        ),
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
  final medicineName = selectedMedicine?.nickname_medi ?? 'ยังไม่เลือกยา';
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
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
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
  final medicineName = selectedMedicine?.nickname_medi ?? 'ยังไม่เลือกยา';
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
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
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
                      textAlign: TextAlign.end,
                    ),
                  ),
                  const SizedBox(width: 8),
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

class RegimenCreateInput {
  final String scheduleType; // DAILY/WEEKLY/INTERVAL/CYCLE
  final DateTime startDateUtc;
  final DateTime? endDateUtc;
  final List<int>? daysOfWeek;
  final int? intervalDays;
  final int? cycleOnDays;
  final int? cycleBreakDays;
  final List<MedicineRegimenTime> times;

  const RegimenCreateInput({
    required this.scheduleType,
    required this.startDateUtc,
    this.endDateUtc,
    this.daysOfWeek,
    this.intervalDays,
    this.cycleOnDays,
    this.cycleBreakDays,
    required this.times,
  });
}

String mapRegimenScheduleType(FrequencyPattern pattern) {
  switch (pattern) {
    case FrequencyPattern.everyDay:
      return 'DAILY';
    case FrequencyPattern.someDays:
      return 'WEEKLY';
    case FrequencyPattern.everyInterval:
      return 'INTERVAL';
  }
}

List<String> toWeekdayCodes(Set<int> weekdays) {
  const mapping = <int, String>{
    1: 'MON',
    2: 'TUE',
    3: 'WED',
    4: 'THU',
    5: 'FRI',
    6: 'SAT',
    7: 'SUN',
  };

  final ordered = weekdays.toList()..sort();
  final codes = <String>[];
  for (final day in ordered) {
    final code = mapping[day];
    if (code != null) codes.add(code);
  }
  return codes;
}

Set<int> parseDaysOfWeekRaw(String? raw) {
  if (raw == null || raw.trim().isEmpty) return {};
  final items = raw.split(',');
  final result = <int>{};
  for (final item in items) {
    final value = int.tryParse(item.trim());
    if (value != null && value >= 1 && value <= 7) {
      result.add(value);
    }
  }
  return result;
}

ReminderPlan fromRegimenDetail({
  required MedicineRegimenDetailResponse detail,
  required MedicineItem medicineItemResolvedFromList,
  String? localId,
}) {
  final scheduleType = detail.scheduleType.trim().toUpperCase();

  FrequencyPattern pattern;
  switch (scheduleType) {
    case 'DAILY':
      pattern = FrequencyPattern.everyDay;
      break;
    case 'WEEKLY':
      pattern = FrequencyPattern.someDays;
      break;
    case 'INTERVAL':
      pattern = FrequencyPattern.everyInterval;
      break;
    case 'CYCLE':
      debugPrint('⚠️ CYCLE mapped to everyInterval for UI editing.');
      pattern = FrequencyPattern.everyInterval;
      break;
    default:
      pattern = FrequencyPattern.everyDay;
  }

  final weekdays =
      pattern == FrequencyPattern.someDays ? parseDaysOfWeekRaw(detail.daysOfWeekRaw) : <int>{};

  final doses = detail.times.map((time) {
    return ReminderDose(
      time: _parseTimeOfDay(time.time),
      amount: _formatDoseAmount(time.dose),
      unit: _mapBackendUnitToUi(time.unit),
      mealTiming: _mealTimingFromRelation(time.mealRelation),
    );
  }).toList();

  final effectiveDoses = doses.isNotEmpty
      ? doses
      : [
          ReminderDose(time: const TimeOfDay(hour: 8, minute: 0)),
        ];

  final timesPerDay = effectiveDoses.length;
  final startTime = effectiveDoses.first.time;

  var everyCount = 1;
  const everyUnit = 'วัน';
  if (scheduleType == 'INTERVAL') {
    everyCount = detail.intervalDays ?? 1;
  } else if (scheduleType == 'CYCLE') {
    everyCount = detail.cycleOnDays ?? 1;
  }
  if (everyCount < 1) everyCount = 1;

  final hasEndDate = detail.endDate != null && detail.endDate!.trim().isNotEmpty;
  final durationMode =
      hasEndDate ? DurationMode.custom : DurationMode.forever;
  var durationValue = 1;
  var durationUnit = 'วัน';
  if (hasEndDate) {
    final start = DateTime.tryParse(detail.startDate) ?? DateTime.now();
    final end = DateTime.tryParse(detail.endDate!) ?? start;
    final diffDays = end.difference(start).inDays;
    durationValue = diffDays < 1 ? 1 : diffDays;
  }

  return ReminderPlan(
    id: (localId != null && localId.trim().isNotEmpty)
        ? localId
        : detail.mediRegimenId.toString(),
    mediListId: detail.mediListId,
    mediRegimenId: detail.mediRegimenId,
    medicine: medicineItemResolvedFromList,
    frequencyMode: FrequencyMode.timesPerDay,
    timesPerDay: timesPerDay,
    everyHours: 6,
    frequencyPattern: pattern,
    weekdays: weekdays,
    everyCount: everyCount,
    everyUnit: everyUnit,
    durationMode: durationMode,
    durationValue: durationValue,
    durationUnit: durationUnit,
    startTime: startTime,
    doses: effectiveDoses,
  );
}

MealTiming _mealTimingFromRelation(String relation) {
  final normalized = relation.trim().toUpperCase();
  switch (normalized) {
    case 'BEFORE_MEAL':
      return MealTiming.beforeMeal;
    case 'AFTER_MEAL':
      return MealTiming.afterMeal;
    case 'NONE':
      return MealTiming.betweenMeals;
    default:
      return MealTiming.afterMeal;
  }
}

String _mapBackendUnitToUi(String unit) {
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

String _formatDoseAmount(num dose) {
  if (dose % 1 == 0) {
    return dose.toInt().toString();
  }
  return dose.toString();
}

TimeOfDay _parseTimeOfDay(String value) {
  final parts = value.split(':');
  if (parts.length < 2) {
    return const TimeOfDay(hour: 0, minute: 0);
  }
  final hour = int.tryParse(parts[0]) ?? 0;
  final minute = int.tryParse(parts[1]) ?? 0;
  return TimeOfDay(
    hour: hour.clamp(0, 23).toInt(),
    minute: minute.clamp(0, 59).toInt(),
  );
}

DateTime regimenStartDateUtc({DateTime? now}) {
  final base = now ?? DateTime.now();
  final local = DateTime(base.year, base.month, base.day, 0, 0, 0);
  return local.toUtc();
}

int intervalDaysFrom(int everyCount, String unit) {
  final count = everyCount < 1 ? 1 : everyCount;
  if (unit == 'วัน') return count;
  if (unit == 'เดือน') return count * 30;
  if (unit == 'ปี') return count * 365;
  return count;
}

DateTime computeDailyEndDateUtc({
  required DurationMode durationMode,
  required int durationValue,
  required String durationUnit,
  required DateTime startDateUtc,
}) {
  if (durationMode == DurationMode.custom) {
    final v = durationValue < 1 ? 1 : durationValue;
    final startLocal = startDateUtc.toLocal();
    DateTime endLocal;

    if (durationUnit == 'วัน') {
      endLocal = startLocal.add(Duration(days: v));
    } else if (durationUnit == 'สัปดาห์') {
      endLocal = startLocal.add(Duration(days: 7 * v));
    } else if (durationUnit == 'ปี') {
      endLocal =
          DateTime(startLocal.year + v, startLocal.month, startLocal.day);
    } else {
      endLocal = startLocal.add(Duration(days: 7 * v));
    }

    final normalized =
        DateTime(endLocal.year, endLocal.month, endLocal.day, 0, 0, 0);
    return normalized.toUtc();
  }

  final startLocal = startDateUtc.toLocal();
  final far =
      DateTime(startLocal.year + 20, startLocal.month, startLocal.day, 0, 0, 0);
  return far.toUtc();
}

String mapMealRelation(MealTiming timing) {
  switch (timing) {
    case MealTiming.beforeMeal:
      return 'BEFORE_MEAL';
    case MealTiming.afterMeal:
      return 'AFTER_MEAL';
    case MealTiming.betweenMeals:
      return 'NONE';
  }
}

String mapRegimenUnit(String uiUnit) {
  switch (uiUnit) {
    case 'เม็ด':
      return 'tablet';
    case 'มิลลิลิตร':
      return 'ml';
    case 'มิลลิกรัม':
      return 'mg';
    case 'เข็ม':
      return 'injection';
    case 'ยาหยอด':
      return 'drop';
    default:
      return uiUnit;
  }
}

RegimenCreateInput buildRegimenCreateInput(
  ReminderPlan plan, {
  DateTime? startDateUtc,
  int defaultMealOffsetMin = 30,
}) {
  final scheduleType = mapRegimenScheduleType(plan.frequencyPattern);
  final start = startDateUtc ?? regimenStartDateUtc();
  final times =
      buildRegimenTimes(plan, defaultMealOffsetMin: defaultMealOffsetMin);

  switch (scheduleType) {
    case 'DAILY':
      final endDateUtc = computeDailyEndDateUtc(
        durationMode: plan.durationMode,
        durationValue: plan.durationValue,
        durationUnit: plan.durationUnit,
        startDateUtc: start,
      );
      return RegimenCreateInput(
        scheduleType: scheduleType,
        startDateUtc: start,
        endDateUtc: endDateUtc,
        times: times,
      );
    case 'WEEKLY':
      final days = plan.weekdays.toList()..sort();
      if (days.isEmpty) {
        throw StateError('WEEKLY requires at least 1 day.');
      }
      return RegimenCreateInput(
        scheduleType: scheduleType,
        startDateUtc: start,
        daysOfWeek: days,
        times: times,
      );
    case 'INTERVAL':
      final interval = intervalDaysFrom(plan.everyCount, plan.everyUnit);
      if (interval < 1) {
        throw StateError('INTERVAL requires intervalDays >= 1.');
      }
      return RegimenCreateInput(
        scheduleType: scheduleType,
        startDateUtc: start,
        intervalDays: interval,
        times: times,
      );
    default:
      throw StateError('Unsupported schedule type: $scheduleType');
  }
}

List<MedicineRegimenTime> buildRegimenTimes(
  ReminderPlan plan, {
  int defaultMealOffsetMin = 30,
}) {
  final effectiveDoses = plan.frequencyMode == FrequencyMode.everyHours
      ? _generateHourlyDoses(plan)
      : plan.doses;

  if (effectiveDoses.isEmpty) {
    throw StateError('At least one time is required.');
  }

  return effectiveDoses.map((dose) {
    final relation = mapMealRelation(dose.mealTiming);
    return MedicineRegimenTime(
      time: formatTimeValue(dose.time),
      dose: num.tryParse(dose.amount) ?? 1,
      unit: mapRegimenUnit(dose.unit),
      mealRelation: relation,
      mealOffsetMin: relation == 'NONE' ? null : defaultMealOffsetMin,
    );
  }).toList();
}

List<ReminderDose> _generateHourlyDoses(ReminderPlan plan) {
  final step = plan.everyHours < 1 ? 1 : plan.everyHours;
  final template = plan.doses.isNotEmpty ? plan.doses.first : null;

  final start = plan.startTime;
  final startMinutes = start.hour * 60 + start.minute;

  final doses = <ReminderDose>[];
  var m = startMinutes;
  while (m < 24 * 60) {
    final h = m ~/ 60;
    final mm = m % 60;
    doses.add(
      ReminderDose(
        time: TimeOfDay(hour: h, minute: mm),
        amount: template?.amount ?? '1',
        unit: template?.unit ?? 'เม็ด',
        mealTiming: template?.mealTiming ?? MealTiming.afterMeal,
      ),
    );
    m += step * 60;
  }
  return doses;
}
