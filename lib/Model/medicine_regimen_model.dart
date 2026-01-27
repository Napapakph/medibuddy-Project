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
    final relation = mealRelation.trim().toUpperCase();
    final map = <String, dynamic>{
      'time': time,
      'dose': dose,
      'unit': unit,
      'mealRelation': relation,
    };

    // rule: mealOffsetMin must exist when mealRelation != NONE,
    // and must be omitted/null when NONE
    if (relation != 'NONE') {
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

class MedicineRegimenDetailResponse {
  final int mediRegimenId;
  final int mediListId;
  final String scheduleType; // DAILY/WEEKLY/INTERVAL/CYCLE
  final String startDate;
  final String? endDate;
  final String? daysOfWeekRaw; // "1,2"
  final int? intervalDays;
  final int? cycleOnDays;
  final int? cycleBreakDays;
  final List<MedicineRegimenTime> times;
  final MedicineListDetail? medicineList;

  MedicineRegimenDetailResponse({
    required this.mediRegimenId,
    required this.mediListId,
    required this.scheduleType,
    required this.startDate,
    this.endDate,
    this.daysOfWeekRaw,
    this.intervalDays,
    this.cycleOnDays,
    this.cycleBreakDays,
    required this.times,
    this.medicineList,
  });

  factory MedicineRegimenDetailResponse.fromJson(Map<String, dynamic> json) {
    String? daysRaw;
    final rawDays = json['daysOfWeek'];
    if (rawDays is String) {
      daysRaw = rawDays;
    } else if (rawDays is List) {
      daysRaw = rawDays.join(',');
    } else if (rawDays != null) {
      daysRaw = rawDays.toString();
    }

    final timesJson = (json['times'] as List?) ?? [];
    final parsedTimes = <MedicineRegimenTime>[];
    for (final item in timesJson) {
      if (item is Map<String, dynamic>) {
        parsedTimes.add(MedicineRegimenTime.fromJson(item));
      } else if (item is Map) {
        parsedTimes
            .add(MedicineRegimenTime.fromJson(Map<String, dynamic>.from(item)));
      }
    }

    final medicineListJson = json['medicineList'];
    MedicineListDetail? medicineList;
    if (medicineListJson is Map<String, dynamic>) {
      medicineList = MedicineListDetail.fromJson(medicineListJson);
    } else if (medicineListJson is Map) {
      medicineList =
          MedicineListDetail.fromJson(Map<String, dynamic>.from(medicineListJson));
    }

    return MedicineRegimenDetailResponse(
      mediRegimenId: _readInt(json['mediRegimenId']),
      mediListId: _readInt(json['mediListId']),
      scheduleType: _readString(json['scheduleType']),
      startDate: _readString(json['startDate']),
      endDate: _readNullableString(json['endDate']),
      daysOfWeekRaw: daysRaw,
      intervalDays: _readNullableInt(json['intervalDays']),
      cycleOnDays: _readNullableInt(json['cycleOnDays']),
      cycleBreakDays: _readNullableInt(json['cycleBreakDays']),
      times: parsedTimes,
      medicineList: medicineList,
    );
  }

  static int _readInt(dynamic value) {
    if (value == null) return 0;
    return int.tryParse(value.toString()) ?? 0;
  }

  static int? _readNullableInt(dynamic value) {
    if (value == null) return null;
    return int.tryParse(value.toString());
  }

  static String _readString(dynamic value) {
    if (value == null) return '';
    return value.toString().trim();
  }

  static String? _readNullableString(dynamic value) {
    if (value == null) return null;
    final s = value.toString();
    return s.trim().isEmpty ? null : s.trim();
  }
}

class MedicineListDetail {
  final int mediListId;
  final String mediNickname;
  final String? pictureOption;
  final MedicineDetail? medicine;

  MedicineListDetail({
    required this.mediListId,
    required this.mediNickname,
    this.pictureOption,
    this.medicine,
  });

  factory MedicineListDetail.fromJson(Map<String, dynamic> json) {
    final medicineJson = json['medicine'];
    MedicineDetail? medicine;
    if (medicineJson is Map<String, dynamic>) {
      medicine = MedicineDetail.fromJson(medicineJson);
    } else if (medicineJson is Map) {
      medicine = MedicineDetail.fromJson(Map<String, dynamic>.from(medicineJson));
    }

    return MedicineListDetail(
      mediListId: _readInt(json['mediListId']),
      mediNickname: _readString(json['mediNickname']),
      pictureOption: _readNullableString(json['pictureOption']),
      medicine: medicine,
    );
  }

  static int _readInt(dynamic value) {
    if (value == null) return 0;
    return int.tryParse(value.toString()) ?? 0;
  }

  static String _readString(dynamic value) {
    if (value == null) return '';
    return value.toString().trim();
  }

  static String? _readNullableString(dynamic value) {
    if (value == null) return null;
    final s = value.toString();
    return s.trim().isEmpty ? null : s.trim();
  }
}

class MedicineDetail {
  final String mediThName;
  final String mediEnName;
  final String mediPicture;

  MedicineDetail({
    required this.mediThName,
    required this.mediEnName,
    required this.mediPicture,
  });

  factory MedicineDetail.fromJson(Map<String, dynamic> json) {
    return MedicineDetail(
      mediThName: _readString(json['mediThName']),
      mediEnName: _readString(json['mediEnName']),
      mediPicture: _readString(json['mediPicture']),
    );
  }

  static String _readString(dynamic value) {
    if (value == null) return '';
    return value.toString().trim();
  }
}

class MedicineRegimenListResponse {
  final List<MedicineRegimenItem> items;

  MedicineRegimenListResponse({required this.items});

  factory MedicineRegimenListResponse.fromJson(Map<String, dynamic> json) {
    List rawItems = const [];
    final itemsJson = json['items'];
    if (itemsJson is List) {
      rawItems = itemsJson;
    } else if (json['data'] is Map) {
      final data = json['data'] as Map;
      if (data['items'] is List) rawItems = data['items'] as List;
    }

    final parsed = <MedicineRegimenItem>[];
    for (final item in rawItems) {
      if (item is Map<String, dynamic>) {
        parsed.add(MedicineRegimenItem.fromJson(item));
      } else if (item is Map) {
        parsed.add(MedicineRegimenItem.fromJson(Map<String, dynamic>.from(item)));
      }
    }

    return MedicineRegimenListResponse(items: parsed);
  }
}

class MedicineRegimenItem {
  final int mediRegimenId;
  final int mediListId;
  final String scheduleType;
  final String startDate;
  final String? endDate;
  final String? nextOccurrenceAt;
  final String? daysOfWeekRaw;
  final int? intervalDays;
  final int? cycleOnDays;
  final int? cycleBreakDays;
  final List<MedicineRegimenTime> times;
  final MedicineListDetail? medicineList;

  MedicineRegimenItem({
    required this.mediRegimenId,
    required this.mediListId,
    required this.scheduleType,
    required this.startDate,
    this.endDate,
    this.nextOccurrenceAt,
    this.daysOfWeekRaw,
    this.intervalDays,
    this.cycleOnDays,
    this.cycleBreakDays,
    required this.times,
    this.medicineList,
  });

  factory MedicineRegimenItem.fromJson(Map<String, dynamic> json) {
    String? daysRaw;
    final rawDays = json['daysOfWeek'];
    if (rawDays is String) {
      daysRaw = rawDays;
    } else if (rawDays is List) {
      daysRaw = rawDays.join(',');
    } else if (rawDays != null) {
      daysRaw = rawDays.toString();
    }

    final timesJson = (json['times'] as List?) ?? [];
    final parsedTimes = <MedicineRegimenTime>[];
    for (final item in timesJson) {
      if (item is Map<String, dynamic>) {
        parsedTimes.add(MedicineRegimenTime.fromJson(item));
      } else if (item is Map) {
        parsedTimes
            .add(MedicineRegimenTime.fromJson(Map<String, dynamic>.from(item)));
      }
    }

    final medicineListJson = json['medicineList'];
    MedicineListDetail? medicineList;
    if (medicineListJson is Map<String, dynamic>) {
      medicineList = MedicineListDetail.fromJson(medicineListJson);
    } else if (medicineListJson is Map) {
      medicineList =
          MedicineListDetail.fromJson(Map<String, dynamic>.from(medicineListJson));
    }

    return MedicineRegimenItem(
      mediRegimenId: _readInt(json['mediRegimenId']),
      mediListId: _readInt(json['mediListId']),
      scheduleType: _readString(json['scheduleType']),
      startDate: _readString(json['startDate']),
      endDate: _readNullableString(json['endDate']),
      nextOccurrenceAt: _readNullableString(json['nextOccurrenceAt']),
      daysOfWeekRaw: daysRaw,
      intervalDays: _readNullableInt(json['intervalDays']),
      cycleOnDays: _readNullableInt(json['cycleOnDays']),
      cycleBreakDays: _readNullableInt(json['cycleBreakDays']),
      times: parsedTimes,
      medicineList: medicineList,
    );
  }

  static int _readInt(dynamic value) {
    if (value == null) return 0;
    return int.tryParse(value.toString()) ?? 0;
  }

  static int? _readNullableInt(dynamic value) {
    if (value == null) return null;
    return int.tryParse(value.toString());
  }

  static String _readString(dynamic value) {
    if (value == null) return '';
    return value.toString().trim();
  }

  static String? _readNullableString(dynamic value) {
    if (value == null) return null;
    final s = value.toString();
    return s.trim().isEmpty ? null : s.trim();
  }
}
