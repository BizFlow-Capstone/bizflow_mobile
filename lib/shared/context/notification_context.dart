import 'package:flutter/foundation.dart';

import '../../features/notification/data/notification_repository.dart';

class NotificationContext extends ChangeNotifier {
  static final NotificationContext _instance = NotificationContext._internal();
  factory NotificationContext() => _instance;
  NotificationContext._internal();

  NotificationRepository? _repository;
  int _unreadCount = 0;

  int get unreadCount => _unreadCount;

  void configure(NotificationRepository repository) {
    _repository = repository;
  }

  Future<void> refreshUnreadCount() async {
    final repository = _repository;
    if (repository == null) return;

    try {
      final unreadCount = await repository.getUnreadCountSWR();
      if (_unreadCount != unreadCount) {
        _unreadCount = unreadCount;
        notifyListeners();
      }
    } catch (_) {
      // Keep existing badge value on API errors
    }
  }

  void decrementUnreadIfPossible() {
    if (_unreadCount <= 0) return;
    _unreadCount -= 1;
    notifyListeners();
  }

  void resetUnread() {
    if (_unreadCount == 0) return;
    _unreadCount = 0;
    notifyListeners();
  }

  void clear() {
    _unreadCount = 0;
    notifyListeners();
  }
}
