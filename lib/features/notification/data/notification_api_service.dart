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

    final raw = response.data;
    if (raw is! Map) {
      throw Exception('Invalid notification response payload');
    }

    final payload = Map<String, dynamic>.from(raw);
    final data = payload['data'];

    if (data is Map) {
      return PaginatedNotificationsDto.fromJson(
        Map<String, dynamic>.from(data),
      );
    }

    if (data is List) {
      return PaginatedNotificationsDto.fromJson({
        'items': data,
        'pageNumber': pageNumber,
        'pageSize': pageSize,
        'totalPages': 1,
        'totalCount': data.length,
        'hasNextPage': false,
      });
    }

    if (payload['items'] is List || payload['notifications'] is List) {
      return PaginatedNotificationsDto.fromJson(payload);
    }

    throw Exception('Invalid notification response payload');
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
