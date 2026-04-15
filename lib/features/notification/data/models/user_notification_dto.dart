class UserNotificationDto {
  Map<String, dynamic> toJson() => {
    'userNotificationId': userNotificationId,
    'notificationType': notificationType,
    'priority': priority,
    'title': title,
    'content': content,
    'actionType': actionType,
    'targetScreen': targetScreen,
    'actionPayloadJson': actionPayloadJson,
    'deliveryStatus': deliveryStatus,
    'createdAt': createdAt.toIso8601String(),
    'sentAt': sentAt?.toIso8601String(),
    'readAt': readAt?.toIso8601String(),
  };

  final int userNotificationId;
  final String notificationType;
  final String priority;
  final String title;
  final String content;
  final String? actionType;
  final String? targetScreen;
  final String? actionPayloadJson;
  final String deliveryStatus;
  final DateTime createdAt;
  final DateTime? sentAt;
  final DateTime? readAt;

  const UserNotificationDto({
    required this.userNotificationId,
    required this.notificationType,
    required this.priority,
    required this.title,
    required this.content,
    this.actionType,
    this.targetScreen,
    this.actionPayloadJson,
    required this.deliveryStatus,
    required this.createdAt,
    this.sentAt,
    this.readAt,
  });

  bool get isRead => readAt != null;

  UserNotificationDto copyWith({DateTime? readAt, DateTime? sentAt}) {
    return UserNotificationDto(
      userNotificationId: userNotificationId,
      notificationType: notificationType,
      priority: priority,
      title: title,
      content: content,
      actionType: actionType,
      targetScreen: targetScreen,
      actionPayloadJson: actionPayloadJson,
      deliveryStatus: deliveryStatus,
      createdAt: createdAt,
      sentAt: sentAt ?? this.sentAt,
      readAt: readAt ?? this.readAt,
    );
  }

  factory UserNotificationDto.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      if (value is String && value.trim().isNotEmpty) {
        return DateTime.tryParse(value)?.toLocal();
      }
      return null;
    }

    return UserNotificationDto(
      userNotificationId: (json['userNotificationId'] as num?)?.toInt() ?? 0,
      notificationType: (json['notificationType'] ?? '').toString(),
      priority: (json['priority'] ?? 'NORMAL').toString(),
      title: (json['title'] ?? '').toString(),
      content: (json['content'] ?? '').toString(),
      actionType: json['actionType']?.toString(),
      targetScreen: json['targetScreen']?.toString(),
      actionPayloadJson: json['actionPayloadJson']?.toString(),
      deliveryStatus: (json['deliveryStatus'] ?? '').toString(),
      createdAt: parseDate(json['createdAt']) ?? DateTime.now(),
      sentAt: parseDate(json['sentAt']),
      readAt: parseDate(json['readAt']),
    );
  }
}

class PaginatedNotificationsDto {
  Map<String, dynamic> toJson() => {
    'items': items.map((e) => e.toJson()).toList(),
    'pageNumber': pageNumber,
    'pageSize': pageSize,
    'totalPages': totalPages,
    'totalCount': totalCount,
    'hasNextPage': hasNextPage,
  };

  final List<UserNotificationDto> items;
  final int pageNumber;
  final int pageSize;
  final int totalPages;
  final int totalCount;
  final bool hasNextPage;

  const PaginatedNotificationsDto({
    required this.items,
    required this.pageNumber,
    required this.pageSize,
    required this.totalPages,
    required this.totalCount,
    required this.hasNextPage,
  });

  factory PaginatedNotificationsDto.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic>? asStringKeyMap(dynamic value) {
      if (value is Map<String, dynamic>) {
        return value;
      }
      if (value is Map) {
        return Map<String, dynamic>.from(value);
      }
      return null;
    }

    final rawItems =
        json['items'] ?? json['notifications'] ?? json['rows'] ?? json['data'];
    final items = <UserNotificationDto>[];
    if (rawItems is List) {
      for (final item in rawItems) {
        final map = asStringKeyMap(item);
        if (map != null) {
          items.add(UserNotificationDto.fromJson(map));
        }
      }
    }

    final pageNumber =
        (json['pageNumber'] as num?)?.toInt() ??
        (json['page'] as num?)?.toInt() ??
        1;
    final pageSize =
        (json['pageSize'] as num?)?.toInt() ??
        (json['size'] as num?)?.toInt() ??
        items.length;
    final totalPages =
        (json['totalPages'] as num?)?.toInt() ??
        (json['pages'] as num?)?.toInt() ??
        1;
    final totalCount =
        (json['totalCount'] as num?)?.toInt() ??
        (json['total'] as num?)?.toInt() ??
        items.length;
    final hasNextPage =
        json['hasNextPage'] == true ||
        (json['hasMore'] == true) ||
        (pageNumber < totalPages);

    return PaginatedNotificationsDto(
      items: items,
      pageNumber: pageNumber,
      pageSize: pageSize,
      totalPages: totalPages,
      totalCount: totalCount,
      hasNextPage: hasNextPage,
    );
  }
}
