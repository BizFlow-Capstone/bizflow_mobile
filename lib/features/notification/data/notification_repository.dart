import "../../../shared/cache/cache_manager.dart";
import '../../../shared/cache/local_api_cache_store.dart';
import 'models/user_notification_dto.dart';
import 'notification_api_service.dart';

class NotificationRepository {
  final NotificationApiService _apiService;
  final LocalApiCacheStore _localApiCache;

  NotificationRepository({
    required NotificationApiService apiService,
    LocalApiCacheStore? localApiCacheStore,
  })  : _apiService = apiService,
        _localApiCache = localApiCacheStore ?? LocalApiCacheStore();

  String _cacheKey(int pageNumber, int pageSize) =>
      'notifications_page_${pageNumber}_size_$pageSize';

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
