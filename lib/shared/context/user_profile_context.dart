import '../../core/storage/local_storage.dart';

class UserProfileContext {
  static final UserProfileContext _instance = UserProfileContext._internal();
  factory UserProfileContext() => _instance;
  UserProfileContext._internal();

  LocalStorage? _storage;

  String? _fullName;
  String? _avatarUrl;
  String? _email;
  String? _phone;
  String? _planName;
  String? _taxCode;

  String? get fullName => _fullName;
  String? get avatarUrl => _avatarUrl;
  String? get email => _email;
  String? get phone => _phone;
  String? get planName => _planName;
  String? get taxCode => _taxCode;

  Future<void> init() async {
    _storage ??= await LocalStorage.getInstance();
    _fullName = _storage?.getString(StorageKeys.currentUserFullName);
    _avatarUrl = _storage?.getString(StorageKeys.currentUserAvatarUrl);
    _email = _storage?.getString(StorageKeys.currentUserEmail);
    _phone = _storage?.getString(StorageKeys.currentUserPhone);
    _taxCode = _storage?.getString(StorageKeys.currentUserTaxCode);
  }

  Future<void> saveProfile({
    String? fullName,
    String? avatarUrl,
    String? email,
    String? phone,
    String? taxCode,
  }) async {
    await init();

    _fullName = fullName?.trim().isEmpty == true ? null : fullName?.trim();
    _avatarUrl = avatarUrl?.trim().isEmpty == true ? null : avatarUrl?.trim();
    _email = email?.trim().isEmpty == true ? null : email?.trim();
    _phone = phone?.trim().isEmpty == true ? null : phone?.trim();
    _taxCode = taxCode?.trim().isEmpty == true ? null : taxCode?.trim();

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

    if (_email == null) {
      await _storage?.remove(StorageKeys.currentUserEmail);
    } else {
      await _storage?.setString(StorageKeys.currentUserEmail, _email!);
    }

    if (_phone == null) {
      await _storage?.remove(StorageKeys.currentUserPhone);
    } else {
      await _storage?.setString(StorageKeys.currentUserPhone, _phone!);
    }

    if (_taxCode == null) {
      await _storage?.remove(StorageKeys.currentUserTaxCode);
    } else {
      await _storage?.setString(StorageKeys.currentUserTaxCode, _taxCode!);
    }
  }

  void updatePlanName(String? name) {
    _planName = name;
  }

  Future<void> clear() async {
    await init();
    _fullName = null;
    _avatarUrl = null;
    _email = null;
    _phone = null;
    _planName = null;
    _taxCode = null;
    await _storage?.remove(StorageKeys.currentUserFullName);
    await _storage?.remove(StorageKeys.currentUserAvatarUrl);
    await _storage?.remove(StorageKeys.currentUserEmail);
    await _storage?.remove(StorageKeys.currentUserPhone);
    await _storage?.remove(StorageKeys.currentUserTaxCode);
  }
}
