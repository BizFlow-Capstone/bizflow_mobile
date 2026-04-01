import 'package:flutter/foundation.dart';
import '../../core/storage/local_storage.dart';

/// Quản lý context kinh doanh hiện tại của user (Dựa trên BusinessLocation)
class BusinessContext extends ChangeNotifier {
  static final BusinessContext _instance = BusinessContext._internal();
  factory BusinessContext() => _instance;
  BusinessContext._internal();

  String? _currentBusinessId;
  String? _currentBusinessName;
  String? _currentOwnerProfileId;
  bool _isOwnerOfCurrentLocation = false;
  LocalStorage? _storage;

  String? get currentBusinessId => _currentBusinessId;
  String? get currentBusinessName => _currentBusinessName;
  String? get currentOwnerProfileId => _currentOwnerProfileId;

  /// true nếu user là owner của location hiện tại
  bool get isOwner => _isOwnerOfCurrentLocation;

  /// Khởi tạo và đọc giá trị lưu trước đó từ ổ cứng (Local Storage)
  Future<void> init() async {
    _storage ??= await LocalStorage.getInstance();
    _currentBusinessId = _storage?.getString(StorageKeys.currentBusinessId);
    _currentBusinessName = _storage?.getString(StorageKeys.currentBusinessName);
    _currentOwnerProfileId = _storage?.getString(StorageKeys.currentOwnerProfileId);
    _isOwnerOfCurrentLocation =
        _storage?.getBool(StorageKeys.isOwnerOfCurrentLocation) ?? false;
  }

  /// Thay đổi địa điểm kinh doanh, cập nhật bộ nhớ tạm, Notify listeners (UI rebuild)
  Future<void> switchBusinessLocation(
    String id,
    String name, {
    bool isOwner = false,
    String? ownerProfileId,
  }) async {
    _currentBusinessId = id;
    _currentBusinessName = name;
    _isOwnerOfCurrentLocation = isOwner;
    _currentOwnerProfileId = ownerProfileId;

    await _storage?.setString(StorageKeys.currentBusinessId, id);
    await _storage?.setString(StorageKeys.currentBusinessName, name);
    await _storage?.setBool(
      StorageKeys.isOwnerOfCurrentLocation,
      isOwner,
    );
    if ((ownerProfileId ?? '').isNotEmpty) {
      await _storage?.setString(StorageKeys.currentOwnerProfileId, ownerProfileId!);
    } else {
      await _storage?.remove(StorageKeys.currentOwnerProfileId);
    }

    // Kích hoạt tất cả UI widget phụ thuộc đang build với BusinessContext
    notifyListeners();
  }

  /// Xoá context (thường gọi lúc Logout)
  Future<void> clear() async {
    _currentBusinessId = null;
    _currentBusinessName = null;
    _currentOwnerProfileId = null;
    _isOwnerOfCurrentLocation = false;
    await _storage?.remove(StorageKeys.currentBusinessId);
    await _storage?.remove(StorageKeys.currentBusinessName);
    await _storage?.remove(StorageKeys.currentOwnerProfileId);
    await _storage?.remove(StorageKeys.isOwnerOfCurrentLocation);
    notifyListeners();
  }
}
