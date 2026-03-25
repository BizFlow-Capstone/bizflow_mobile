import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'dart:async';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/notification/notification_navigation_contract.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/services/notification_realtime_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/context/notification_context.dart';
import '../../../../shared/widgets/app_sync_status_text.dart';
import '../../data/models/user_notification_dto.dart';
import '../../data/notification_repository.dart';

class NotificationListPage extends StatefulWidget {
  const NotificationListPage({super.key});

  @override
  State<NotificationListPage> createState() => _NotificationListPageState();
}

class _NotificationListPageState extends State<NotificationListPage> {
  static const int _pageSize = 20;

  final ScrollController _scrollController = ScrollController();
  final List<UserNotificationDto> _notifications = [];

  bool _isInitialLoading = true;
  bool _isLoadingMore = false;
  bool _hasNextPage = false;
  String? _errorMessage;
  int _currentPage = 1;
  StreamSubscription<Map<String, dynamic>>? _realtimeSubscription;

  NotificationRepository get _repository =>
      context.read<NotificationRepository>();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    NotificationRealtimeService().connect();
    _realtimeSubscription = NotificationRealtimeService.notificationStream
        .listen((_) {
          _loadInitial();
        });
    _loadInitial();
  }

  @override
  void dispose() {
    _realtimeSubscription?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadInitial() async {
    setState(() {
      _isInitialLoading = true;
      _errorMessage = null;
      _currentPage = 1;
    });

    try {
      final page = await _repository.getMyNotifications(
        pageNumber: _currentPage,
        pageSize: _pageSize,
      );

      if (!mounted) return;
      setState(() {
        _notifications
          ..clear()
          ..addAll(page.items);
        _hasNextPage = page.hasNextPage;
        _isInitialLoading = false;
      });

      NotificationContext().refreshUnreadCount();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.toString();
        _isInitialLoading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasNextPage) {
      return;
    }

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final nextPage = _currentPage + 1;
      final page = await _repository.getMyNotifications(
        pageNumber: nextPage,
        pageSize: _pageSize,
      );

      if (!mounted) return;
      setState(() {
        _currentPage = nextPage;
        _notifications.addAll(page.items);
        _hasNextPage = page.hasNextPage;
      });
    } catch (_) {
      // Keep current list on load-more failure.
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    }
  }

  Future<void> _markAllAsRead() async {
    await _repository.markAllAsRead();

    if (!mounted) return;
    setState(() {
      for (var index = 0; index < _notifications.length; index++) {
        if (!_notifications[index].isRead) {
          _notifications[index] = _notifications[index].copyWith(
            readAt: DateTime.now(),
          );
        }
      }
    });
    NotificationContext().resetUnread();
  }

  Future<void> _handleNotificationTap(UserNotificationDto notification) async {
    if (!notification.isRead) {
      try {
        await _repository.markAsRead(notification.userNotificationId);
        if (!mounted) return;

        final index = _notifications.indexWhere(
          (item) => item.userNotificationId == notification.userNotificationId,
        );
        if (index >= 0) {
          setState(() {
            _notifications[index] = _notifications[index].copyWith(
              readAt: DateTime.now(),
            );
          });
        }
        NotificationContext().decrementUnreadIfPossible();
      } catch (_) {
        // Keep UX smooth if mark-read API fails.
      }
    }

    if (!mounted) return;

    final targetRoute = _resolveRouteFromNotification(notification);
    if (targetRoute != null) {
      await AppRouter.navigateFromNotificationTarget(targetRoute);
      return;
    }

    AppRouter.navigateTo(
      AppRoutes.notificationDetail,
      arguments: {
        'title': notification.title,
        'body': notification.content,
        'time': _formatTime(context, notification.createdAt),
        'icon': _resolveIcon(notification.notificationType),
        'iconColor': _resolveIconColor(notification.notificationType),
      },
    );
  }

  String? _resolveRouteFromNotification(UserNotificationDto notification) {
    return NotificationNavigationContract.resolve(
      actionType: notification.actionType,
      targetScreen: notification.targetScreen,
      actionPayloadJson: notification.actionPayloadJson,
      type: notification.notificationType,
    );
  }

  void _onScroll() {
    if (!_scrollController.hasClients) {
      return;
    }

    final threshold = _scrollController.position.maxScrollExtent - 200;
    if (_scrollController.position.pixels >= threshold) {
      _loadMore();
    }
  }

  String _formatTime(BuildContext context, DateTime time) {
    final l10n = AppLocalizations.of(context);
    final diff = DateTime.now().difference(time);

    if (diff.inMinutes < 1) {
      return l10n.translate('notification.just_now');
    }

    if (diff.inHours < 1) {
      return l10n.translate(
        'notification.minutes_ago',
        params: {'count': diff.inMinutes.toString()},
      );
    }

    if (diff.inDays < 1) {
      return l10n.translate(
        'notification.hours_ago',
        params: {'count': diff.inHours.toString()},
      );
    }

    return l10n.translate(
      'notification.days_ago',
      params: {'count': diff.inDays.toString()},
    );
  }

  IconData _resolveIcon(String notificationType) {
    switch (notificationType.toUpperCase()) {
      case 'ORDER_CREATED':
        return Icons.shopping_cart_outlined;
      case 'INVITE_EMPLOYEE':
      case 'EMPLOYEE_INVITE':
        return Icons.group_add_outlined;
      case 'PROMOTION':
        return Icons.local_offer_outlined;
      case 'SYSTEM_UPDATE':
        return Icons.system_update_alt_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color _resolveIconColor(String notificationType) {
    switch (notificationType.toUpperCase()) {
      case 'ORDER_CREATED':
        return AppColors.secondary;
      case 'INVITE_EMPLOYEE':
      case 'EMPLOYEE_INVITE':
        return AppColors.primary;
      case 'PROMOTION':
        return AppColors.warning;
      case 'SYSTEM_UPDATE':
        return AppColors.info;
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.textPrimary,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        elevation: 0,
        title: Text(
          l10n.translate('notification.title'),
          style: AppTextStyles.titleLarge.copyWith(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
          color: Colors.black,
        ),
        bottom: const AppSyncStatusText(),
      ),
      body: SafeArea(
        child: _isInitialLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
            ? _ErrorState(onRetry: _loadInitial)
            : _notifications.isEmpty
            ? _EmptyState()
            : Column(
                children: [
                  if (_notifications.any((item) => !item.isRead))
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.xs,
                      ),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _markAllAsRead,
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: 4,
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            l10n.translate('notification.mark_all_read'),
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: _loadInitial,
                      child: ListView.separated(
                        controller: _scrollController,
                        padding: const EdgeInsets.only(
                          left: AppSpacing.md,
                          right: AppSpacing.md,
                          top: AppSpacing.sm,
                          bottom: 40,
                        ),
                        itemCount:
                            _notifications.length + (_isLoadingMore ? 1 : 0),
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: AppSpacing.sm),
                        itemBuilder: (context, index) {
                          if (index >= _notifications.length) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(
                                vertical: AppSpacing.sm,
                              ),
                              child: Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            );
                          }

                          final notification = _notifications[index];
                          return _NotificationTile(
                            notification: notification,
                            icon: _resolveIcon(notification.notificationType),
                            iconColor: _resolveIconColor(
                              notification.notificationType,
                            ),
                            timeText: _formatTime(
                              context,
                              notification.createdAt,
                            ),
                            onTap: () => _handleNotificationTap(notification),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final UserNotificationDto notification;
  final IconData icon;
  final Color iconColor;
  final String timeText;
  final VoidCallback onTap;

  const _NotificationTile({
    required this.notification,
    required this.icon,
    required this.iconColor,
    required this.timeText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: notification.isRead
          ? AppColors.white
          : AppColors.primary.withValues(alpha: 0.04),
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Center(child: Icon(icon, color: iconColor, size: 22)),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: AppTextStyles.titleSmall.copyWith(
                              fontWeight: notification.isRead
                                  ? FontWeight.w500
                                  : FontWeight.bold,
                            ),
                          ),
                        ),
                        if (!notification.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.content,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      timeText,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.textHint,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_off_outlined,
            size: 64,
            color: AppColors.textHint,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            l10n.translate('notification.empty'),
            style: AppTextStyles.titleMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.translate('notification.empty_sub'),
            style: AppTextStyles.labelSmall.copyWith(color: AppColors.textHint),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final Future<void> Function() onRetry;

  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: AppColors.error),
          const SizedBox(height: AppSpacing.md),
          Text(
            l10n.translate('common.error_occurred'),
            style: AppTextStyles.titleMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextButton(
            onPressed: () {
              onRetry();
            },
            child: Text(l10n.translate('common.retry')),
          ),
        ],
      ),
    );
  }
}
