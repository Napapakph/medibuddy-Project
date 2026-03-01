import '../Model/profile_model.dart';

class AppState {
  AppState._();
  static final AppState instance = AppState._();

  int? currentProfileId;
  String? currentProfileName;
  String? currentProfileImagePath;

  /// Last profileId confirmed via TAKE flow (used as fallback for SKIP/SNOOZE)
  int? lastSelectedProfileId;

  /// Cached profiles list for lookup (populated by profile screens)
  List<ProfileModel> cachedProfiles = [];

  void setLastSelectedProfileId(int id) {
    lastSelectedProfileId = id;
  }

  void setSelectedProfile({
    required int profileId,
    String? name,
    String? imagePath,
  }) {
    currentProfileId = profileId;
    currentProfileName = name;
    currentProfileImagePath = imagePath;
  }

  /// Replace the cached profiles list (called after profile fetch)
  void setCachedProfiles(List<ProfileModel> list) {
    cachedProfiles = List.unmodifiable(list);
  }

  /// Resolve a display name for a profileId from the cache.
  /// Returns username if found, otherwise 'โปรไฟล์ #id'.
  String resolveProfileName(int profileId) {
    for (final p in cachedProfiles) {
      if (p.profileId == profileId && p.username.trim().isNotEmpty) {
        return p.username.trim();
      }
    }
    // Fallback: if it matches the currently selected profile
    if (profileId == currentProfileId &&
        currentProfileName != null &&
        currentProfileName!.trim().isNotEmpty) {
      return currentProfileName!.trim();
    }
    return 'โปรไฟล์ #$profileId';
  }
}
