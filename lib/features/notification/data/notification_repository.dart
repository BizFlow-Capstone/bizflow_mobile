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

  Future<void> markAsRead(int userNotificationId) =>
      _apiService.markAsRead(userNotificationId);

  Future<void> markAllAsRead() => _apiService.markAllAsRead();
}
