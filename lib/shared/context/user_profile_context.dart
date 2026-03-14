import '../../core/storage/local_storage.dart';

class UserProfileContext {
  static final UserProfileContext _instance = UserProfileContext._internal();
  factory UserProfileContext() => _instance;
  UserProfileContext._internal();

  LocalStorage? _storage;

  String? _fullName;
  String? _avatarUrl;

  String? get fullName => _fullName;
  String? get avatarUrl => _avatarUrl;

  Future<void> init() async {
    _storage ??= await LocalStorage.getInstance();
    _fullName = _storage?.getString(StorageKeys.currentUserFullName);
    _avatarUrl = _storage?.getString(StorageKeys.currentUserAvatarUrl);
  }

  Future<void> saveProfile({String? fullName, String? avatarUrl}) async {
    await init();

    _fullName = fullName?.trim().isEmpty == true ? null : fullName?.trim();
    _avatarUrl = avatarUrl?.trim().isEmpty == true ? null : avatarUrl?.trim();

    if (_fullName == null) {
      await _storage?.remove(StorageKeys.currentUserFullName);
    } else {
      await _storage?.setString(StorageKeys.currentUserFullName, _fullName!);
    }

    if (_avatarUrl == null) {
      await _storage?.remove(StorageKeys.currentUserAvatarUrl);
    } else {
      await _storage?.setString(StorageKeys.currentUserAvatarUrl, _avatarUrl!);
    }
  }

  Future<void> clear() async {
    await init();
    _fullName = null;
    _avatarUrl = null;
    await _storage?.remove(StorageKeys.currentUserFullName);
    await _storage?.remove(StorageKeys.currentUserAvatarUrl);
  }
}
