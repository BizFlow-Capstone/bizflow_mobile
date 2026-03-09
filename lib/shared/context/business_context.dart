import 'package:flutter/foundation.dart';
import '../../core/storage/local_storage.dart';

/// Quản lý context kinh doanh hiện tại của user (Dựa trên BusinessLocation)
class BusinessContext extends ChangeNotifier {
  static final BusinessContext _instance = BusinessContext._internal();
  factory BusinessContext() => _instance;
  BusinessContext._internal();

  String? _currentBusinessId;
  String? _currentBusinessName;
  LocalStorage? _storage;

  String? get currentBusinessId => _currentBusinessId;
  String? get currentBusinessName => _currentBusinessName;

  /// Khởi tạo và đọc giá trị lưu trước đó từ ổ cứng (Local Storage)
  Future<void> init() async {
    _storage ??= await LocalStorage.getInstance();
    _currentBusinessId = _storage?.getString(StorageKeys.currentBusinessId);
    _currentBusinessName = _storage?.getString(StorageKeys.currentBusinessName);
  }

  /// Thay đổi địa điểm kinh doanh, cập nhật bộ nhớ tạm, Notify listeners (UI rebuild)
  Future<void> switchBusinessLocation(String id, String name) async {
    _currentBusinessId = id;
    _currentBusinessName = name;

    await _storage?.setString(StorageKeys.currentBusinessId, id);
    await _storage?.setString(StorageKeys.currentBusinessName, name);

    // Kích hoạt tất cả UI widget phụ thuộc đang build với BusinessContext
    notifyListeners();
  }

  /// Xoá context (thường gọi lúc Logout)
  Future<void> clear() async {
    _currentBusinessId = null;
    _currentBusinessName = null;
    await _storage?.remove(StorageKeys.currentBusinessId);
    await _storage?.remove(StorageKeys.currentBusinessName);
    notifyListeners();
  }
}
