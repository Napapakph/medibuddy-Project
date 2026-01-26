class MedicineCatalogItem {
  final int mediId;
  final String mediThName;
  final String mediEnName;
  final String mediTradeName;
  final String mediType;
  final String imageUrl;
  final String indications;
  final String usageAdvice;
  final String adverseReactions;
  final String contraindications;
  final String precautions;
  final String interactions;
  final String storage;

  const MedicineCatalogItem({
    required this.mediId,
    required this.mediThName,
    required this.mediEnName,
    required this.mediTradeName,
    required this.mediType,
    required this.imageUrl,
    required this.indications,
    required this.usageAdvice,
    required this.adverseReactions,
    required this.contraindications,
    required this.precautions,
    required this.interactions,
    required this.storage,
  });

  String get displayOfficialName {
    if (mediTradeName.isNotEmpty) return mediTradeName;
    if (mediEnName.isNotEmpty) return mediEnName;
    return mediThName;
  }

  static int _readInt(dynamic value) {
    if (value == null) return 0;
    return int.tryParse(value.toString()) ?? 0;
  }

  static String _readString(dynamic value) {
    if (value == null) return '';
    return value.toString().trim();
  }

  static String _withFallback(String value, String fallback) {
    return value.isEmpty ? fallback : value;
  }

  factory MedicineCatalogItem.fromJson(Map<String, dynamic> json) {
    final mediType = _readString(json['mediType']);
    return MedicineCatalogItem(
      mediId: _readInt(json['mediId'] ?? json['medId'] ?? json['id']),
      mediThName: _readString(json['mediThName']),
      mediEnName: _readString(json['mediEnName']),
      mediTradeName: _readString(json['mediTradeName']),
      mediType: mediType,
      imageUrl: _readString(
        json['imageUrl'] ??
            json['image'] ??
            json['mediImage'] ??
            json['mediPicture'] ??
            json['picture'],
      ),
      indications: _withFallback(
        _readString(
          json['indications'] ??
              json['mediIndication'] ??
              json['mediIndications'],
        ),
        '-',
      ),
      usageAdvice: _withFallback(
        _readString(
          json['usageAdvice'] ??
              json['usage'] ??
              json['mediUsage'] ??
              json['howToUse'],
        ),
        '-',
      ),
      adverseReactions: _withFallback(
        _readString(
          json['adverseReactions'] ??
              json['sideEffects'] ??
              json['mediSideEffect'],
        ),
        '-',
      ),
      contraindications: _withFallback(
        _readString(
          json['contraindications'] ??
              json['mediContraindication'] ??
              json['contraindication'],
        ),
        '-',
      ),
      precautions: _withFallback(
        _readString(
          json['precautions'] ?? json['mediPrecaution'] ?? json['warning'],
        ),
        '-',
      ),
      interactions: _withFallback(
        _readString(
          json['interactions'] ??
              json['mediInteraction'] ??
              json['interaction'],
        ),
        '-',
      ),
      storage: _withFallback(
        _readString(
          json['storage'] ?? json['mediStorage'] ?? json['storageAdvice'],
        ),
        '-',
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
    String? nickname_medi,
    String? officialName_medi,
    String? imagePath,
  }) {
    return MedicineItem(
      mediListId: mediListId,
      id: id,
      nickname_medi: nickname_medi ?? this.nickname_medi,
      officialName_medi: officialName_medi ?? this.officialName_medi,
      imagePath: imagePath ?? this.imagePath,
    );
  }

  int get mediId => int.tryParse(id) ?? 0;
}
