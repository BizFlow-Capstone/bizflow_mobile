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
  final Map<String, DateTime> _lastNetworkFetchAt = {};

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

  Future<void> _cleanupExpiredCache({
    Duration ttl = const Duration(days: 7),
  }) async {
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

  /// Đọc cache đồng bộ (synchronous) — chỉ dùng sau khi init() đã được gọi ít nhất 1 lần.
  /// SharedPreferences đã load vào RAM, nên read là instant, không cần await.
  /// Trả về null nếu CacheManager chưa khởi tạo hoặc không có cache.
  Map<String, dynamic>? tryGetSync(String key) {
    if (_storage == null) return null;
    final data = _storage!.getObject('cache_$key');
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
    if (isFirstLaunch != null)
      await _storage?.setBool(StorageKeys.isFirstLaunch, isFirstLaunch);

    debugPrint('CacheManager: Aggressive clear all finished');
  }

  /// Reset thời điểm fetch cuối cùng của một key để buộc SWR revalidate ngầm
  /// mà không xóa cache — data cũ vẫn được serve nếu network fail.
  void resetRevalidateTimer(String key) {
    _lastNetworkFetchAt.remove(key);
  }

  /// Triển khai SWR logic: Local First + Sync Ngầm (Non-blocking)
  Future<void> fetchWithSWR<T>({
    required String key,
    required Future<T> Function({CancelToken? cancelToken}) fetcher,
    required void Function(T data, bool isFromCache) onData,
    Function(dynamic error)? onError,
    T Function(Map<String, dynamic> json)? fromJson,
    Map<String, dynamic> Function(T data)? toJson,
    Duration networkTimeout = const Duration(seconds: 5),
    Duration minRevalidateInterval = const Duration(seconds: 15),
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

    if (!hasLocalData) {
      Timer(networkTimeout, () {
        if (!completer.isCompleted) {
          debugPrint(
            'SWR: Initial fetch for $key timed out after ${networkTimeout.inSeconds}s, resolving.',
          );
          completer.complete();
        }
      });
    }

    // With local cache available, skip very frequent revalidate requests to
    // avoid re-sync flicker and redundant API calls when users switch tabs fast.
    if (hasLocalData) {
      final lastFetch = _lastNetworkFetchAt[key];
      if (lastFetch != null &&
          DateTime.now().difference(lastFetch) < minRevalidateInterval) {
        return completer.future;
      }
    }

    _cancelTokens[key]?.cancel('New request triggered for $key');
    final cancelToken = CancelToken();
    _cancelTokens[key] = cancelToken;

    final sequence = (_sequences[key] ?? 0) + 1;
    _sequences[key] = sequence;

    final trackSyncStatus = !hasLocalData;
    if (trackSyncStatus) {
      SyncStatusController().startSync();
    }

    unawaited(
      _performNetworkSync<T>(
        key: key,
        fetcher: fetcher,
        onData: onData,
        onError: onError,
        toJson: toJson,
        hasLocalData: hasLocalData,
        localDataHash: localDataHash,
        sequence: sequence,
        cancelToken: cancelToken,
        trackSyncStatus: trackSyncStatus,
        completerToResolveIfNoCache: hasLocalData ? null : completer,
      ),
    );

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
    required bool trackSyncStatus,
    Completer<void>? completerToResolveIfNoCache,
  }) async {
    try {
      final serverData = await fetcher(cancelToken: cancelToken);
      _lastNetworkFetchAt[key] = DateTime.now();

      if (_sequences[key] != sequence) {
        debugPrint('SWR Sequence mismatch for $key, discarding result');
        if (trackSyncStatus) {
          SyncStatusController().endSync();
        }
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
      if (trackSyncStatus) {
        SyncStatusController().endSync(
          updatedAt: DateTime.now(),
          hasError: false,
        );
      }

      if (completerToResolveIfNoCache?.isCompleted == false) {
        completerToResolveIfNoCache?.complete();
      }
    } catch (e) {
      if (e is DioException && CancelToken.isCancel(e)) {
        debugPrint('SWR request cancelled: $key');
        if (trackSyncStatus) {
          SyncStatusController().endSync();
        }
        if (completerToResolveIfNoCache?.isCompleted == false) {
          completerToResolveIfNoCache?.complete();
        }
        return;
      }

      debugPrint('SWR Fetcher Error: $e');
      if (trackSyncStatus) {
        SyncStatusController().endSync(hasError: true);
      }

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
