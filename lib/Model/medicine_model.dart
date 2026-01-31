class MedicineCatalogItem {
  final int mediId;

  final String? mediThName;
  final String? mediEnName;
  final String? mediTradeName;
  final String? mediType;

  final String? mediUse;
  final String? mediGuide;
  final String? mediEffects;
  final String? mediNoUse;
  final String? mediWarning;
  final String? mediStore;
  final String? mediPicture;

  const MedicineCatalogItem({
    required this.mediId,
    this.mediThName,
    this.mediEnName,
    this.mediTradeName,
    this.mediType,
    this.mediUse,
    this.mediGuide,
    this.mediEffects,
    this.mediNoUse,
    this.mediWarning,
    this.mediStore,
    this.mediPicture,
  });

  /// ใช้เลือกชื่อหลักสำหรับแสดงใน UI
  /// (ถ้ามีชื่อการค้าใช้ก่อน, รองลงมาชื่ออังกฤษ, แล้วชื่อไทย)
  String get displayOfficialName {
    final trade = (mediTradeName ?? '').trim();
    if (trade.isNotEmpty) return trade;

    final en = (mediEnName ?? '').trim();
    if (en.isNotEmpty) return en;

    return (mediThName ?? '-').trim().isEmpty
        ? '-'
        : (mediThName ?? '-').trim();
  }

  static int _readInt(dynamic value) {
    if (value == null) return 0;
    return int.tryParse(value.toString()) ?? 0;
  }

  static String? _readNullableString(dynamic value) {
    if (value == null) return null;
    final s = value.toString().trim();
    return s.isEmpty ? null : s;
  }

  factory MedicineCatalogItem.fromJson(Map<String, dynamic> json) {
    return MedicineCatalogItem(
      mediId: _readInt(json['mediId'] ?? json['medId'] ?? json['id']),
      mediThName: _readNullableString(json['mediThName']),
      mediEnName: _readNullableString(json['mediEnName']),
      mediTradeName: _readNullableString(json['mediTradeName']),
      mediType: _readNullableString(json['mediType']),

      // detail fields
      mediUse: _readNullableString(json['mediUse']),
      mediGuide: _readNullableString(json['mediGuide']),
      mediEffects: _readNullableString(json['mediEffects']),
      mediNoUse: _readNullableString(json['mediNoUse']),
      mediWarning: _readNullableString(json['mediWarning']),
      mediStore: _readNullableString(json['mediStore']),

      // picture: รองรับ key หลายแบบ เผื่อ API/หน้าอื่นส่งต่างกัน
      mediPicture: _readNullableString(
        json['mediPicture'] ??
            json['imageUrl'] ??
            json['image'] ??
            json['mediImage'] ??
            json['picture'],
      ),
    );
  }
}

class MedicineDraft {
  final String nickname_medi;
  final String searchQuery_medi;
  final String officialName_medi;
  final String imagePath;
  final String? mediId;
  final MedicineCatalogItem? catalogItem;

  const MedicineDraft({
    required this.nickname_medi,
    this.searchQuery_medi = '',
    this.officialName_medi = '',
    this.imagePath = '',
    this.mediId,
    this.catalogItem,
  });

  MedicineDraft copyWith({
    String? nickname_medi,
    String? searchQuery_medi,
    String? officialName_medi,
    String? imagePath,
    String? mediId,
    MedicineCatalogItem? catalogItem,
  }) {
    return MedicineDraft(
      nickname_medi: nickname_medi ?? this.nickname_medi,
      searchQuery_medi: searchQuery_medi ?? this.searchQuery_medi,
      officialName_medi: officialName_medi ?? this.officialName_medi,
      imagePath: imagePath ?? this.imagePath,
      catalogItem: catalogItem ?? this.catalogItem,
      mediId: mediId ?? this.mediId,
    );
  }
}

class MedicineItem {
  final int mediListId;
  final String id;
  final String nickname_medi;
  final String officialName_medi;
  final String imagePath;

  const MedicineItem({
    required this.mediListId,
    required this.id,
    required this.nickname_medi,
    required this.officialName_medi,
    required this.imagePath,
  });

  MedicineItem copyWith({
    int? mediListId,
    String? id,
    String? nickname_medi,
    String? officialName_medi,
    String? imagePath,
  }) {
    return MedicineItem(
      mediListId: mediListId ?? this.mediListId,
      id: id ?? this.id,
      nickname_medi: nickname_medi ?? this.nickname_medi,
      officialName_medi: officialName_medi ?? this.officialName_medi,
      imagePath: imagePath ?? this.imagePath,
    );
  }

  int get mediId => int.tryParse(id) ?? 0;
}

class MedicineDetail {
  final int mediId;
  final String? mediThName;
  final String? mediEnName;
  final String? mediTradeName;
  final String? mediType;
  final String? mediUse;
  final String? mediGuide;
  final String? mediEffects;
  final String? mediNoUse;
  final String? mediWarning;
  final String? mediStore;
  final String? mediPicture;

  MedicineDetail({
    required this.mediId,
    required this.mediThName,
    required this.mediEnName,
    required this.mediTradeName,
    required this.mediType,
    required this.mediUse,
    required this.mediGuide,
    required this.mediEffects,
    required this.mediNoUse,
    required this.mediWarning,
    required this.mediStore,
    required this.mediPicture,
  });

  factory MedicineDetail.fromJson(Map<String, dynamic> json) {
    return MedicineDetail(
      mediId: (json['mediId'] ?? 0) as int,
      mediThName: json['mediThName'] as String?,
      mediEnName: json['mediEnName'] as String?,
      mediTradeName: json['mediTradeName'] as String?,
      mediType: json['mediType'] as String?,
      mediUse: json['mediUse'] as String?,
      mediGuide: json['mediGuide'] as String?,
      mediEffects: json['mediEffects'] as String?,
      mediNoUse: json['mediNoUse'] as String?,
      mediWarning: json['mediWarning'] as String?,
      mediStore: json['mediStore'] as String?,
      mediPicture: json['mediPicture'] as String?,
    );
  }
}
