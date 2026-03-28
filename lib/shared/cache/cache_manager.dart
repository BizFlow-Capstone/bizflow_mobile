import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../core/storage/local_storage.dart';
import 'sync_status_controller.dart';

/// Quản lý việc lưu trữ cache tạm thời cho SWR Pattern
class CacheManager {
  static final CacheManager _instance = CacheManager._internal();
  factory CacheManager() => _instance;
  CacheManager._internal();

  LocalStorage? _storage;
  bool _hasScheduledCleanup = false;

  final Map<String, CancelToken> _cancelTokens = {};
  final Map<String, int> _sequences = {};

  Future<void> init() async {
    if (_storage == null) {
      _storage = await LocalStorage.getInstance();
      if (!_hasScheduledCleanup) {
        _hasScheduledCleanup = true;
        _scheduleCleanup();
      }
    }
  }

  void _scheduleCleanup() {
    Future.delayed(const Duration(seconds: 5), () async {
      await _cleanupExpiredCache();
    });
  }

  Future<void> _cleanupExpiredCache({Duration ttl = const Duration(days: 7)}) async {
    await init();
    int deleted = 0;
    try {
      final keys = _storage?.getKeys();
      if (keys == null) return;
      final now = DateTime.now().millisecondsSinceEpoch;

      for (final key in keys.toList()) {
        if (key.startsWith('cache_')) {
          final wrapper = _storage?.getObject(key);
          if (wrapper != null && wrapper.containsKey('timestamp')) {
            final timestamp = wrapper['timestamp'] as int;
            if (now - timestamp > ttl.inMilliseconds) {
              await _storage?.remove(key);
              deleted++;
            }
          }
        }
      }
      if (deleted > 0) {
        debugPrint('CacheManager: Cleaned up $deleted expired cache entries');
      }
    } catch (e) {
      debugPrint('CacheManager: Cleanup error: $e');
    }
  }

  /// Lấy dữ liệu từ cache theo key
  Future<Map<String, dynamic>?> get(String key) async {
    await init();
    final data = _storage?.getObject('cache_$key');
    if (data != null && data.containsKey('data')) {
      return data['data'] as Map<String, dynamic>;
    }
    return data;
  }

  /// Lưu trữ dữ liệu vào cache theo key
  Future<void> set(String key, Map<String, dynamic> data) async {
    await init();
    final wrapper = {
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'data': data,
    };
    await _storage?.setObject('cache_$key', wrapper);
  }

  /// Xóa cache theo key
  Future<void> remove(String key) async {
    await init();
    await _storage?.remove('cache_$key');
  }

  /// Xóa cache theo prefix key
  Future<void> removeByPrefix(String prefix) async {
    await init();
    final keys = _storage?.getKeys() ?? <String>{};
    final targetPrefix = 'cache_$prefix';

    for (final key in keys.toList()) {
      if (key.startsWith(targetPrefix)) {
        await _storage?.remove(key);
      }
    }
  }

  /// Xóa toàn bộ dữ liệu
  Future<void> clearAll() async {
    await init();
    debugPrint('CacheManager: Aggressive clear all started');

    final locale = _storage?.getString(StorageKeys.locale);
    final theme = _storage?.getString(StorageKeys.themeMode);
    final isFirstLaunch = _storage?.getBool(StorageKeys.isFirstLaunch);

    await _storage?.clear();

    if (locale != null) await _storage?.setString(StorageKeys.locale, locale);
    if (theme != null) await _storage?.setString(StorageKeys.themeMode, theme);
    if (isFirstLaunch != null) await _storage?.setBool(StorageKeys.isFirstLaunch, isFirstLaunch);

    debugPrint('CacheManager: Aggressive clear all finished');
  }

  /// Triển khai SWR logic: Local First + Sync Ngầm (Non-blocking)
  Future<void> fetchWithSWR<T>({
    required String key,
    required Future<T> Function({CancelToken? cancelToken}) fetcher,
    required void Function(T data, bool isFromCache) onData,
    Function(dynamic error)? onError,
    T Function(Map<String, dynamic> json)? fromJson,
    Map<String, dynamic> Function(T data)? toJson,
  }) async {
    await init();
    final completer = Completer<void>();

    bool hasLocalData = false;
    String? localDataHash;
    try {
      if (fromJson != null && toJson != null) {
        final cachedJson = await get(key);
        if (cachedJson != null) {
          final cachedData = fromJson(cachedJson);
          localDataHash = jsonEncode(toJson(cachedData));
          onData(cachedData, true);
          hasLocalData = true;
          completer.complete();
        }
      } else if (fromJson != null) {
        final cachedJson = await get(key);
        if (cachedJson != null) {
          final cachedData = fromJson(cachedJson);
          onData(cachedData, true);
          hasLocalData = true;
          completer.complete();
        }
      }
    } catch (e) {
      debugPrint('SWR Cache Error (Read): $e');
    }

    _cancelTokens[key]?.cancel('New request triggered for $key');
    final cancelToken = CancelToken();
    _cancelTokens[key] = cancelToken;

    final sequence = (_sequences[key] ?? 0) + 1;
    _sequences[key] = sequence;

    SyncStatusController().startSync();

    unawaited(_performNetworkSync<T>(
      key: key,
      fetcher: fetcher,
      onData: onData,
      onError: onError,
      toJson: toJson,
      hasLocalData: hasLocalData,
      localDataHash: localDataHash,
      sequence: sequence,
      cancelToken: cancelToken,
      completerToResolveIfNoCache: hasLocalData ? null : completer,
    ));

    return completer.future;
  }

  Future<void> _performNetworkSync<T>({
    required String key,
    required Future<T> Function({CancelToken? cancelToken}) fetcher,
    required void Function(T data, bool isFromCache) onData,
    Function(dynamic error)? onError,
    Map<String, dynamic> Function(T data)? toJson,
    required bool hasLocalData,
    String? localDataHash,
    required int sequence,
    required CancelToken cancelToken,
    Completer<void>? completerToResolveIfNoCache,
  }) async {
    try {
      final serverData = await fetcher(cancelToken: cancelToken);

      if (_sequences[key] != sequence) {
        debugPrint('SWR Sequence mismatch for $key, discarding result');
        if (completerToResolveIfNoCache?.isCompleted == false) {
          completerToResolveIfNoCache?.complete();
        }
        return;
      }

      bool shouldEmit = true;
      if (hasLocalData && localDataHash != null && toJson != null) {
        final serverDataHash = jsonEncode(toJson(serverData));
        if (serverDataHash == localDataHash) {
          shouldEmit = false;
        }
      }

      if (shouldEmit) {
        onData(serverData, false);
      }

      if (toJson != null) {
        await set(key, toJson(serverData));
      }
      SyncStatusController().endSync(updatedAt: DateTime.now(), hasError: false);
      
      if (completerToResolveIfNoCache?.isCompleted == false) {
        completerToResolveIfNoCache?.complete();
      }
    } catch (e) {
      if (e is DioException && CancelToken.isCancel(e)) {
        debugPrint('SWR request cancelled: $key');
        if (completerToResolveIfNoCache?.isCompleted == false) {
          completerToResolveIfNoCache?.complete();
        }
        return; 
      }

      debugPrint('SWR Fetcher Error: $e');
      SyncStatusController().endSync(hasError: true);
      
      if (!hasLocalData && onError != null) {
        onError(e);
      }
      
      if (completerToResolveIfNoCache?.isCompleted == false) {
        completerToResolveIfNoCache?.completeError(e);
      }
    } finally {
      if (_cancelTokens[key] == cancelToken) {
        _cancelTokens.remove(key);
      }
    }
  }
}
