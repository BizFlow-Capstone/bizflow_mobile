import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';

/// Snackbar type enum
enum AppSnackBarType { info, success, warning, error }

/// AppSnackBar - Shared SnackBar Helper
class AppSnackBar {
  AppSnackBar._();

  static String? _lastMessage;
  static AppSnackBarType? _lastType;
  static DateTime? _lastShownAt;
  static const Duration _dedupeWindow = Duration(seconds: 2);

  /// Show snackbar
  static void show(
    BuildContext context, {
    required String message,
    AppSnackBarType type = AppSnackBarType.info,
    Duration duration = const Duration(seconds: 3),
    String? actionLabel,
    VoidCallback? onAction,
    bool showCloseIcon = false,
  }) {
    if (context is Element && !context.mounted) return;
    if (message.trim().isEmpty) return;

    final now = DateTime.now();
    final normalizedMessage = message.trim().replaceAll(RegExp(r'\s+'), ' ');
    final shouldSkip =
      _lastMessage == normalizedMessage &&
        _lastType == type &&
        _lastShownAt != null &&
        now.difference(_lastShownAt!) < _dedupeWindow;
    if (shouldSkip) return;

    _lastMessage = normalizedMessage;
    _lastType = type;
    _lastShownAt = now;

    final mediaQuery = MediaQuery.maybeOf(context);
    final bottomInset =
        (mediaQuery?.viewInsets.bottom ?? 0) +
        (mediaQuery?.padding.bottom ?? 0) +
        16;

    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.removeCurrentSnackBar(reason: SnackBarClosedReason.remove);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            _getIcon(type),
            SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                message,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: _getBackgroundColor(type),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.fromLTRB(16, 0, 16, bottomInset),
        shape: RoundedRectangleBorder(borderRadius: AppSpacing.borderRadiusSm),
        duration: duration,
        action: actionLabel != null
            ? SnackBarAction(
                label: actionLabel,
                textColor: AppColors.white,
                onPressed: onAction ?? () {},
              )
            : null,
        showCloseIcon: showCloseIcon,
        closeIconColor: AppColors.white,
      ),
    );
  }

  /// Show info snackbar
  static void info(BuildContext context, String message) {
    show(context, message: message, type: AppSnackBarType.info);
  }

  /// Show success snackbar
  static void success(BuildContext context, String message) {
    show(context, message: message, type: AppSnackBarType.success);
  }

  /// Show warning snackbar
  static void warning(BuildContext context, String message) {
    show(context, message: message, type: AppSnackBarType.warning);
  }

  /// Show error snackbar
  static void error(BuildContext context, String message) {
    show(context, message: message, type: AppSnackBarType.error);
  }

  static Widget _getIcon(AppSnackBarType type) {
    IconData icon;
    switch (type) {
      case AppSnackBarType.success:
        icon = Icons.check_circle;
        break;
      case AppSnackBarType.warning:
        icon = Icons.warning;
        break;
      case AppSnackBarType.error:
        icon = Icons.error;
        break;
      default:
        icon = Icons.info;
    }
    return Icon(icon, color: AppColors.white, size: 20);
  }

  static Color _getBackgroundColor(AppSnackBarType type) {
    switch (type) {
      case AppSnackBarType.success:
        return AppColors.success;
      case AppSnackBarType.warning:
        return AppColors.warning;
      case AppSnackBarType.error:
        return AppColors.error;
      default:
        return AppColors.info;
    }
  }
}

/// AppToast - Simple toast message (using snackbar)
class AppToast {
  AppToast._();

  static void show(BuildContext context, String message) {
    if (context is Element && !context.mounted) return;
    if (message.trim().isEmpty) return;

    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.removeCurrentSnackBar(reason: SnackBarClosedReason.remove);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.white),
          textAlign: TextAlign.center,
        ),
        backgroundColor: AppColors.textPrimary.withValues(alpha: 0.9),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.borderRadiusFull,
        ),
        duration: const Duration(seconds: 2),
        margin: EdgeInsets.symmetric(
          horizontal: MediaQuery.of(context).size.width * 0.2,
          vertical: AppSpacing.lg,
        ),
      ),
    );
  }
}
