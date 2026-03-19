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
    return _storage?.getObject('cache_$key');
  }

  /// Lưu trữ dữ liệu vào cache theo key
  Future<void> set(String key, Map<String, dynamic> data) async {
    await init();
    await _storage?.setObject('cache_$key', data);
  }

  /// Xóa cache theo key
  Future<void> remove(String key) async {
    await init();
    await _storage?.remove('cache_$key');
  }

  /// Xóa toàn bộ dữ liệu (nên dùng khi Logout)
  Future<void> clearAll() async {
    await init();
    
    debugPrint('CacheManager: Aggressive clear all started');
    
    // Save essentials (locale)
    final locale = _storage?.getString(StorageKeys.locale);
    final theme = _storage?.getString(StorageKeys.themeMode);
    final isFirstLaunch = _storage?.getBool(StorageKeys.isFirstLaunch);

    // Wipe everything
    await _storage?.clear();
    
    // Restore essentials
    if (locale != null) await _storage?.setString(StorageKeys.locale, locale);
    if (theme != null) await _storage?.setString(StorageKeys.themeMode, theme);
    if (isFirstLaunch != null) await _storage?.setBool(StorageKeys.isFirstLaunch, isFirstLaunch);
    
    debugPrint('CacheManager: Aggressive clear all finished');
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
