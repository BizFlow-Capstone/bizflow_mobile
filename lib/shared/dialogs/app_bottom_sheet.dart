import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';

/// AppBottomSheet - Shared Bottom Sheet Widget
class AppBottomSheet extends StatelessWidget {
  final String? title;
  final Widget child;
  final bool showCloseButton;
  final bool isDismissible;
  final double? maxHeight;
  final EdgeInsetsGeometry? padding;

  const AppBottomSheet({
    super.key,
    this.title,
    required this.child,
    this.showCloseButton = true,
    this.isDismissible = true,
    this.maxHeight,
    this.padding,
  });

  /// Show bottom sheet helper
  static Future<T?> show<T>(
    BuildContext context, {
    String? title,
    required Widget child,
    bool showCloseButton = true,
    bool isDismissible = true,
    double? maxHeight,
    EdgeInsetsGeometry? padding,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isDismissible: isDismissible,
      enableDrag: isDismissible,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AppBottomSheet(
        title: title,
        showCloseButton: showCloseButton,
        isDismissible: isDismissible,
        maxHeight: maxHeight,
        padding: padding,
        child: child,
      ),
    );
  }

  /// Show list bottom sheet
  static Future<T?> showList<T>(
    BuildContext context, {
    String? title,
    required List<AppBottomSheetItem<T>> items,
  }) {
    return show<T>(
      context,
      title: title,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: items.map((item) {
          return ListTile(
            leading: item.icon != null ? Icon(item.icon) : null,
            title: Text(item.title),
            subtitle: item.subtitle != null ? Text(item.subtitle!) : null,
            onTap: () => Navigator.of(context).pop(item.value),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final maxSheetHeight = maxHeight ?? screenHeight * 0.9;

    return Container(
      constraints: BoxConstraints(maxHeight: maxSheetHeight),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppSpacing.radiusLg),
          topRight: Radius.circular(AppSpacing.radiusLg),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Center(
            child: Container(
              margin: EdgeInsets.only(top: AppSpacing.sm),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: AppSpacing.borderRadiusFull,
              ),
            ),
          ),

          // Header
          if (title != null || showCloseButton)
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                children: [
                  if (title != null)
                    Expanded(
                      child: Text(
                        title!,
                        style: AppTextStyles.titleMedium,
                      ),
                    )
                  else
                    const Spacer(),
                  if (showCloseButton)
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                ],
              ),
            ),

          // Divider
          if (title != null) const Divider(height: 1),

          // Content
          Flexible(
            child: SingleChildScrollView(
              padding: padding ?? AppSpacing.paddingMd,
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

/// Bottom sheet item model
class AppBottomSheetItem<T> {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final T value;

  const AppBottomSheetItem({
    required this.title,
    this.subtitle,
    this.icon,
    required this.value,
  });
}
