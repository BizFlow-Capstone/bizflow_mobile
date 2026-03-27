import "../../../shared/cache/cache_manager.dart";
import 'models/user_notification_dto.dart';
import 'notification_api_service.dart';

class NotificationRepository {
  final NotificationApiService _apiService;

  NotificationRepository({required NotificationApiService apiService})
    : _apiService = apiService;

  Future<PaginatedNotificationsDto> getMyNotifications({
    int pageNumber = 1,
    int pageSize = 20,
  }) {
    return _apiService.getMyNotifications(
      pageNumber: pageNumber,
      pageSize: pageSize,
    );
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
  }
}
