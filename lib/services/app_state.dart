class AppState {
  AppState._();
  static final AppState instance = AppState._();

  int? currentProfileId;
  String? currentProfileName;
  String? currentProfileImagePath;

  void setSelectedProfile({
    required int profileId,
    String? name,
    String? imagePath,
  }) {
    currentProfileId = profileId;
    currentProfileName = name;
    currentProfileImagePath = imagePath;
  }
}
