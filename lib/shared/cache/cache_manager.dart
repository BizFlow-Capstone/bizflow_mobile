import 'package:flutter/foundation.dart';
import '../../core/storage/local_storage.dart';
import 'sync_status_controller.dart';

/// Quản lý việc lưu trữ cache tạm thời cho SWR Pattern
/// Dữ liệu lưu dưới dạng JSON String vào Local Storage
class CacheManager {
  static final CacheManager _instance = CacheManager._internal();
  factory CacheManager() => _instance;
  CacheManager._internal();

  LocalStorage? _storage;

  Future<void> init() async {
    _storage ??= await LocalStorage.getInstance();
  }

  /// Lấy dữ liệu từ cache theo key
  Future<Map<String, dynamic>?> get(String key) async {
    await init();
    return _storage?.getObject(key);
  }

  /// Lưu trữ dữ liệu vào cache theo key
  Future<void> set(String key, Map<String, dynamic> data) async {
    await init();
    await _storage?.setObject(key, data);
  }

  /// Xóa cache theo key
  Future<void> remove(String key) async {
    await init();
    await _storage?.remove(key);
  }

  /// Xóa toàn bộ dữ liệu (nên dùng khi Logout)
  Future<void> clearAll() async {
    await init();
    // Vì clearAll() ở LocalStorage có thể xóa cả token,
    // ta nên cân nhắc dùng một prefix riêng cho cache (VD: cache_)
    // và chỉ xóa những key bắt đầu bằng prefix đó.
    final keys = _storage?.getKeys() ?? {};
    final cacheKeys = keys.where(
      (k) => k.startsWith('cache_') || k.startsWith('data_'),
    );
    for (final k in cacheKeys) {
      await _storage?.remove(k);
    }

    // Xóa luôn context
    await _storage?.remove(StorageKeys.currentBusinessId);
  }

  /// Triển khai SWR logic: Local First + Sync Ngầm
  /// [key] là khoá để lưu cache
  /// [fetcher] là hàm callback gọi API server
  /// [onData] là callback khi có dữ liệu (từ cache HOẶC server)
  /// [onError] xử lý khi fetcher lỗi
  Future<void> fetchWithSWR<T>({
    required String key,
    required Future<T> Function() fetcher,
    required void Function(T data, bool isFromCache) onData,
    Function(dynamic error)? onError,
    T Function(Map<String, dynamic> json)? fromJson,
    Map<String, dynamic> Function(T data)? toJson,
  }) async {
    await init();

    // 1. Local-First: Đọc dữ liệu từ local cache trước
    bool hasLocalData = false;
    try {
      if (fromJson != null) {
        final cachedJson = await get(key);
        if (cachedJson != null) {
          final cachedData = fromJson(cachedJson);
          onData(cachedData, true);
          hasLocalData = true;
        }
      }
    } catch (e) {
      debugPrint('SWR Cache Error (Read): $e');
    }

    // 2. Sync-Implicit: Gọi API server ngầm ở Background
    SyncStatusController().startSync();
    try {
      final serverData = await fetcher();

      // Update callback ngay khi có data từ server
      onData(serverData, false);

      // 3. Update-On-Change: Ghi đè lại cache bằng dữ liệu mới nhất
      if (toJson != null) {
        await set(key, toJson(serverData));
      }
      SyncStatusController().endSync(updatedAt: DateTime.now());
    } catch (e) {
      debugPrint('SWR Fetcher Error: $e');
      SyncStatusController().endSync();
      if (!hasLocalData && onError != null) {
        // Chỉ ném lỗi lên UI nếu như không có local data để fallback
        onError(e);
      }
    }
  }
}
