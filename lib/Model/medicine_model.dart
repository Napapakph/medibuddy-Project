class MedicineDraft {
  final String displayName;
  final String imagePath;
  final String selectedName;

  const MedicineDraft({
    required this.displayName,
    required this.imagePath,
    this.selectedName = '',
  });

  MedicineDraft copyWith({
    String? displayName,
    String? imagePath,
    String? selectedName,
  }) {
    return MedicineDraft(
      displayName: displayName ?? this.displayName,
      imagePath: imagePath ?? this.imagePath,
      selectedName: selectedName ?? this.selectedName,
    );
  }
}

class MedicineItem {
  final String id;
  final String displayName;
  final String selectedName;
  final String imagePath;

  const MedicineItem({
    required this.id,
    required this.displayName,
    required this.selectedName,
    required this.imagePath,
  });

  MedicineItem copyWith({
    String? displayName,
    String? selectedName,
    String? imagePath,
  }) {
    return MedicineItem(
      id: id,
      displayName: displayName ?? this.displayName,
      selectedName: selectedName ?? this.selectedName,
      imagePath: imagePath ?? this.imagePath,
    );
  }

  // ✅ แก้ตรงนี้
  int get mediId => int.tryParse(id) ?? 0;
}
