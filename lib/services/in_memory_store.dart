import '../Model/medicine_model.dart';
import '../Model/profile_model.dart';

// In-memory cache only; data resets on app restart.
class MedicineStore {
  static final List<MedicineItem> _items = [];

  static List<MedicineItem> get items => List.unmodifiable(_items);

  static void replaceAll(List<MedicineItem> items) {
    _items
      ..clear()
      ..addAll(items);
  }

  static void add(MedicineItem item) => _items.add(item);

  static void updateAt(int index, MedicineItem item) {
    if (index < 0 || index >= _items.length) return;
    _items[index] = item;
  }

  static void removeAt(int index) {
    if (index < 0 || index >= _items.length) return;
    _items.removeAt(index);
  }
}

class ProfileStore {
  static final List<ProfileModel> _items = [];

  static List<ProfileModel> get items => List.unmodifiable(_items);

  static void replaceAll(List<ProfileModel> items) {
    _items
      ..clear()
      ..addAll(items);
  }

  static void add(ProfileModel item) => _items.add(item);

  static void updateAt(int index, ProfileModel item) {
    if (index < 0 || index >= _items.length) return;
    _items[index] = item;
  }

  static void removeAt(int index) {
    if (index < 0 || index >= _items.length) return;
    _items.removeAt(index);
  }

  static List<ProfileModel> mergeApi(List<ProfileModel> apiItems) {
    final merged = <ProfileModel>[];
    final byId = <String, int>{};

    for (final item in apiItems) {
      if (item.profileId.isNotEmpty) {
        byId[item.profileId] = merged.length;
      }
      merged.add(item);
    }

    for (final local in _items) {
      if (local.profileId.isEmpty) {
        merged.add(local);
        continue;
      }
      if (!byId.containsKey(local.profileId)) {
        merged.add(local);
      }
    }

    return merged;
  }
}
