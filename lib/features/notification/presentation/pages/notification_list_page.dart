import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Mock notification data
class _MockNotification {
  final String id;
  final String titleKey;
  final String body;
  final DateTime time;
  final bool isRead;
  final IconData icon;
  final Color iconColor;

  const _MockNotification({
    required this.id,
    required this.titleKey,
    required this.body,
    required this.time,
    this.isRead = false,
    required this.icon,
    required this.iconColor,
  });
}

/// Notification List Page
class NotificationListPage extends StatefulWidget {
  const NotificationListPage({super.key});

  @override
  State<NotificationListPage> createState() => _NotificationListPageState();
}

class _NotificationListPageState extends State<NotificationListPage> {
  late List<_MockNotification> _notifications;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _notifications = [
      _MockNotification(
        id: '1',
        titleKey: 'notification.order_confirmed',
        body: 'Đơn hàng DH-2024-001 đã được xác nhận thành công.',
        time: now.subtract(const Duration(minutes: 5)),
        isRead: false,
        icon: Icons.check_circle_outline,
        iconColor: AppColors.success,
      ),
      _MockNotification(
        id: '2',
        titleKey: 'notification.payment_received',
        body: 'Nhận thanh toán 2,000,000đ từ Nguyễn Văn An.',
        time: now.subtract(const Duration(hours: 1)),
        isRead: false,
        icon: Icons.payment,
        iconColor: AppColors.primary,
      ),
      _MockNotification(
        id: '3',
        titleKey: 'notification.stock_low',
        body: 'Sản phẩm "iPhone 15 Pro Max" sắp hết hàng (còn 2 chiếc).',
        time: now.subtract(const Duration(hours: 3)),
        isRead: true,
        icon: Icons.warning_amber_outlined,
        iconColor: AppColors.warning,
      ),
      _MockNotification(
        id: '4',
        titleKey: 'notification.new_order',
        body: 'Đơn hàng mới DH-2024-008 từ Trần Thị Bình.',
        time: now.subtract(const Duration(hours: 6)),
        isRead: true,
        icon: Icons.shopping_cart_outlined,
        iconColor: AppColors.secondary,
      ),
      _MockNotification(
        id: '5',
        titleKey: 'notification.import_completed',
        body: 'Phiếu nhập kho PNK-2026-009 đã được xác nhận.',
        time: now.subtract(const Duration(days: 1)),
        isRead: true,
        icon: Icons.inventory_2_outlined,
        iconColor: AppColors.info,
      ),
      _MockNotification(
        id: '6',
        titleKey: 'notification.payment_received',
        body: 'Nhận thanh toán 1,500,000đ từ Lê Hoàng Cường.',
        time: now.subtract(const Duration(days: 2)),
        isRead: true,
        icon: Icons.payment,
        iconColor: AppColors.primary,
      ),
    ];
  }

  String _formatTime(BuildContext context, DateTime time) {
    final l10n = AppLocalizations.of(context);
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) {
      return l10n.translate('notification.just_now');
    } else if (diff.inHours < 1) {
      return l10n.translate(
        'notification.minutes_ago',
        params: {'count': diff.inMinutes.toString()},
      );
    } else if (diff.inDays < 1) {
      return l10n.translate(
        'notification.hours_ago',
        params: {'count': diff.inHours.toString()},
      );
    } else {
      return l10n.translate(
        'notification.days_ago',
        params: {'count': diff.inDays.toString()},
      );
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
      ),
      body: SafeArea(
        child: _notifications.isEmpty
            ? Center(
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
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.textHint,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            : Column(
                children: [
                  // Mark all read row
                  if (_notifications.any((n) => !n.isRead))
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.xs,
                      ),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            setState(() {
                              _notifications = _notifications
                                  .map(
                                    (n) => _MockNotification(
                                      id: n.id,
                                      titleKey: n.titleKey,
                                      body: n.body,
                                      time: n.time,
                                      isRead: true,
                                      icon: n.icon,
                                      iconColor: n.iconColor,
                                    ),
                                  )
                                  .toList();
                            });
                          },
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
                  // Notification list
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.only(
                        left: AppSpacing.md,
                        right: AppSpacing.md,
                        top: AppSpacing.sm,
                        bottom: 40,
                      ),
                      itemCount: _notifications.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (context, index) {
                        final notification = _notifications[index];
                        return _buildNotificationTile(context, notification);
                      },
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildNotificationTile(
    BuildContext context,
    _MockNotification notification,
  ) {
    final l10n = AppLocalizations.of(context);

    return Material(
      color: notification.isRead
          ? AppColors.white
          : AppColors.primary.withValues(alpha: 0.04),
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: InkWell(
        onTap: () {
          AppRouter.navigateTo(
            AppRoutes.notificationDetail,
            arguments: {
              'title': l10n.translate(notification.titleKey),
              'body': notification.body,
              'time': _formatTime(context, notification.time),
              'icon': notification.icon,
              'iconColor': notification.iconColor,
            },
          );
          // Mark as read
          setState(() {
            final idx = _notifications.indexOf(notification);
            _notifications[idx] = _MockNotification(
              id: notification.id,
              titleKey: notification.titleKey,
              body: notification.body,
              time: notification.time,
              isRead: true,
              icon: notification.icon,
              iconColor: notification.iconColor,
            );
          });
        },
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: notification.iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Center(
                  child: Icon(
                    notification.icon,
                    color: notification.iconColor,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            l10n.translate(notification.titleKey),
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
                      notification.body,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatTime(context, notification.time),
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
