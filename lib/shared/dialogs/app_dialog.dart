import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../widgets/app_button.dart';

/// Dialog type enum
enum AppDialogType { info, success, warning, error, confirm }

/// AppDialog - Shared Dialog Widget
class AppDialog extends StatelessWidget {
  final String title;
  final String? message;
  final Widget? content;
  final AppDialogType type;
  final String? confirmText;
  final String? cancelText;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;
  final bool barrierDismissible;

  const AppDialog({
    super.key,
    required this.title,
    this.message,
    this.content,
    this.type = AppDialogType.info,
    this.confirmText,
    this.cancelText,
    this.onConfirm,
    this.onCancel,
    this.barrierDismissible = true,
  });

  /// Show dialog helper
  static Future<bool?> show(
    BuildContext context, {
    required String title,
    String? message,
    Widget? content,
    AppDialogType type = AppDialogType.info,
    String? confirmText,
    String? cancelText,
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
    bool barrierDismissible = true,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (context) => AppDialog(
        title: title,
        message: message,
        content: content,
        type: type,
        confirmText: confirmText,
        cancelText: cancelText,
        onConfirm: onConfirm,
        onCancel: onCancel,
        barrierDismissible: barrierDismissible,
      ),
    );
  }

  /// Show confirm dialog
  static Future<bool?> confirm(
    BuildContext context, {
    required String title,
    String? message,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
  }) {
    return show(
      context,
      title: title,
      message: message,
      type: AppDialogType.confirm,
      confirmText: confirmText,
      cancelText: cancelText,
    );
  }

  /// Show success dialog
  static Future<bool?> success(
    BuildContext context, {
    required String title,
    String? message,
    String confirmText = 'OK',
  }) {
    return show(
      context,
      title: title,
      message: message,
      type: AppDialogType.success,
      confirmText: confirmText,
    );
  }

  /// Show error dialog
  static Future<bool?> error(
    BuildContext context, {
    required String title,
    String? message,
    String confirmText = 'OK',
  }) {
    return show(
      context,
      title: title,
      message: message,
      type: AppDialogType.error,
      confirmText: confirmText,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: AppSpacing.borderRadiusMd,
      ),
      title: Row(
        children: [
          _buildIcon(),
          SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              title,
              style: AppTextStyles.titleMedium,
            ),
          ),
        ],
      ),
      content: content ??
          (message != null
              ? Text(
                  message!,
                  style: AppTextStyles.bodyMedium,
                )
              : null),
      actions: _buildActions(context),
    );
  }

  Widget _buildIcon() {
    IconData icon;
    Color color;

    switch (type) {
      case AppDialogType.success:
        icon = Icons.check_circle;
        color = AppColors.success;
        break;
      case AppDialogType.warning:
        icon = Icons.warning;
        color = AppColors.warning;
        break;
      case AppDialogType.error:
        icon = Icons.error;
        color = AppColors.error;
        break;
      case AppDialogType.confirm:
        icon = Icons.help;
        color = AppColors.primary;
        break;
      default:
        icon = Icons.info;
        color = AppColors.info;
    }

    return Icon(icon, color: color, size: 28);
  }

  List<Widget> _buildActions(BuildContext context) {
    final actions = <Widget>[];

    // Cancel button
    if (cancelText != null || type == AppDialogType.confirm) {
      actions.add(
        AppButton(
          label: cancelText ?? 'Cancel',
          type: AppButtonType.text,
          size: AppButtonSize.small,
          onPressed: () {
            Navigator.of(context).pop(false);
            onCancel?.call();
          },
        ),
      );
    }

    // Confirm button
    actions.add(
      AppButton(
        label: confirmText ?? 'OK',
        type: type == AppDialogType.error
            ? AppButtonType.danger
            : AppButtonType.primary,
        size: AppButtonSize.small,
        onPressed: () {
          Navigator.of(context).pop(true);
          onConfirm?.call();
        },
      ),
    );

    return actions;
  }
}
