class MedicineRegimenTime {
  final int? timeId;
  final String time; // "09:00"
  final num dose; // 1
  final String unit; // "tablet"
  final String mealRelation; // "BEFORE_MEAL" | "AFTER_MEAL" | "NONE"
  final int? mealOffsetMin; // required when mealRelation != NONE

  MedicineRegimenTime({
    this.timeId,
    required this.time,
    required this.dose,
    required this.unit,
    required this.mealRelation,
    this.mealOffsetMin,
  });

  factory MedicineRegimenTime.fromJson(Map<String, dynamic> json) {
    return MedicineRegimenTime(
      timeId: json['timeId'],
      time: json['time'] ?? '',
      dose: json['dose'] ?? 0,
      unit: json['unit'] ?? '',
      mealRelation: json['mealRelation'] ?? 'NONE',
      mealOffsetMin: json['mealOffsetMin'],
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'time': time,
      'dose': dose,
      'unit': unit,
      'mealRelation': mealRelation,
    };

    // rule: mealOffsetMin must exist when mealRelation != NONE,
    // and must be omitted/null when NONE
    if (mealRelation != 'NONE') {
      map['mealOffsetMin'] = mealOffsetMin ?? 30;
    }
    return map;
  }
}

class MedicineRegimenResponse {
  final int mediRegimenId;
  final int mediListId;
  final String scheduleType; // DAILY/WEEKLY/INTERVAL/CYCLE
  final String startDate;
  final String? endDate;
  final List<int>? daysOfWeek;
  final int? intervalDays;
  final int? cycleOnDays;
  final int? cycleBreakDays;
  final String? nextOccurrenceAt;
  final List<MedicineRegimenTime> times;

  MedicineRegimenResponse({
    required this.mediRegimenId,
    required this.mediListId,
    required this.scheduleType,
    required this.startDate,
    this.endDate,
    this.daysOfWeek,
    this.intervalDays,
    this.cycleOnDays,
    this.cycleBreakDays,
    this.nextOccurrenceAt,
    required this.times,
  });

  factory MedicineRegimenResponse.fromJson(Map<String, dynamic> json) {
    return MedicineRegimenResponse(
      mediRegimenId: json['mediRegimenId'] ?? 0,
      mediListId: json['mediListId'] ?? 0,
      scheduleType: json['scheduleType'] ?? '',
      startDate: json['startDate'] ?? '',
      endDate: json['endDate'],
      daysOfWeek: (json['daysOfWeek'] as List?)?.map((e) => e as int).toList(),
      intervalDays: json['intervalDays'],
      cycleOnDays: json['cycleOnDays'],
      cycleBreakDays: json['cycleBreakDays'],
      nextOccurrenceAt: json['nextOccurrenceAt'],
      times: ((json['times'] as List?) ?? [])
          .map((e) => MedicineRegimenTime.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
