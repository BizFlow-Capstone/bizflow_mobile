import "../../../shared/cache/cache_manager.dart";
import '../../../shared/cache/local_api_cache_store.dart';
import 'models/user_notification_dto.dart';
import 'notification_api_service.dart';

class NotificationRepository {
  final NotificationApiService _apiService;
  final CacheManager _cache;
  final LocalApiCacheStore _localApiCache;

  NotificationRepository({
    required NotificationApiService apiService,
    CacheManager? cacheManager,
    LocalApiCacheStore? localApiCacheStore,
  }) : _apiService = apiService,
       _cache = cacheManager ?? CacheManager(),
       _localApiCache = localApiCacheStore ?? LocalApiCacheStore();

  String _cacheKey(int pageNumber, int pageSize) =>
      'notifications_page_${pageNumber}_size_$pageSize';
  static const String _unreadCacheKey = 'notifications_unread_count';

  Future<void> fetchNotificationsSWR({
    int pageNumber = 1,
    int pageSize = 20,
    required void Function(PaginatedNotificationsDto page, bool isFromCache)
    onData,
    void Function(dynamic error)? onError,
  }) async {
    final key = _cacheKey(pageNumber, pageSize);
    final localCached = await _localApiCache.getMap(key);
    if (localCached != null) {
      onData(PaginatedNotificationsDto.fromJson(localCached), true);
    }

    await _cache.fetchWithSWR<Map<String, dynamic>>(
      key: key,
      fetcher: ({cancelToken}) async {
        final page = await _apiService.getMyNotifications(
          pageNumber: pageNumber,
          pageSize: pageSize,
        );
        return page.toJson();
      },
      fromJson: (json) => json,
      toJson: (data) => data,
      onData: (json, isFromCache) {
        _localApiCache.setMap(
          key,
          json,
          groupKey: 'notifications',
          cacheType: 'list',
        );
        onData(PaginatedNotificationsDto.fromJson(json), isFromCache);
      },
      onError: onError,
    );
  }

  Future<PaginatedNotificationsDto> getMyNotifications({
    int pageNumber = 1,
    int pageSize = 20,
  }) async {
    final key = _cacheKey(pageNumber, pageSize);
    try {
      final data = await _apiService.getMyNotifications(
        pageNumber: pageNumber,
        pageSize: pageSize,
      );
      await _localApiCache.setMap(
        key,
        data.toJson(),
        groupKey: 'notifications',
        cacheType: 'list',
      );
      return data;
    } catch (e) {
      final localCached = await _localApiCache.getMap(key);
      if (localCached != null) {
        return PaginatedNotificationsDto.fromJson(localCached);
      }
      rethrow;
    }
  }

  Future<int> getUnreadCount() => _apiService.getUnreadCount();

  Future<int> getUnreadCountSWR() async {
    try {
      final unreadCount = await _apiService.getUnreadCount();
      await _localApiCache.setMap(
        _unreadCacheKey,
        {'unreadCount': unreadCount},
        groupKey: 'notifications',
        cacheType: 'meta',
      );
      return unreadCount;
    } catch (_) {
      final localCached = await _localApiCache.getMap(_unreadCacheKey);
      return (localCached?['unreadCount'] as num?)?.toInt() ?? 0;
    }
  }

  Future<void> markAsRead(int userNotificationId) async {
    await _apiService.markAsRead(userNotificationId);
    await clearCache();
  }

  Future<void> markAllAsRead() async {
    await _apiService.markAllAsRead();
    await clearCache();
  }

  Future<void> clearCache() async {
    await CacheManager().removeByPrefix("notifications_");
    await _localApiCache.removeByGroup('notifications');
  }
}
