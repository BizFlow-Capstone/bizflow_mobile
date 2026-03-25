import '../../../core/network/api_client.dart';

import 'models/user_notification_dto.dart';

class NotificationApiService {
  final ApiClient _apiClient;

  NotificationApiService({required ApiClient apiClient})
    : _apiClient = apiClient;

  Future<PaginatedNotificationsDto> getMyNotifications({
    int pageNumber = 1,
    int pageSize = 20,
  }) async {
    final response = await _apiClient.get(
      '/api/notifications',
      queryParams: {'pageNumber': pageNumber, 'pageSize': pageSize},
    );

    if (!response.isSuccess || response.data == null) {
      throw Exception(response.message ?? 'Failed to load notifications');
    }

    final payload = response.data as Map<String, dynamic>;
    final data = payload['data'] as Map<String, dynamic>?;
    if (data == null) {
      throw Exception('Invalid notification response payload');
    }

    return PaginatedNotificationsDto.fromJson(data);
  }

  Future<int> getUnreadCount() async {
    final response = await _apiClient.get('/api/notifications/unread-count');

    if (!response.isSuccess || response.data == null) {
      throw Exception(response.message ?? 'Failed to load unread count');
    }

    final payload = response.data as Map<String, dynamic>;
    final data = payload['data'] as Map<String, dynamic>?;
    return (data?['unreadCount'] as num?)?.toInt() ?? 0;
  }

  Future<void> markAsRead(int userNotificationId) async {
    final response = await _apiClient.put(
      '/api/notifications/$userNotificationId/read',
    );

    if (!response.isSuccess) {
      throw Exception(
        response.message ?? 'Failed to mark notification as read',
      );
    }
  }

  Future<void> markAllAsRead() async {
    final response = await _apiClient.put('/api/notifications/read-all');

    if (!response.isSuccess) {
      throw Exception(
        response.message ?? 'Failed to mark all notifications as read',
      );
    }
  }
}
