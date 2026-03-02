import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

/// AppCard - Shared Card Widget
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;
  final double? elevation;
  final BorderRadius? borderRadius;
  final VoidCallback? onTap;
  final Border? border;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.elevation,
    this.borderRadius,
    this.onTap,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      margin: margin,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.surface,
        borderRadius: borderRadius ?? AppSpacing.borderRadiusMd,
        border: border,
        boxShadow: elevation != null && elevation! > 0
            ? [
                BoxShadow(
                  color: AppColors.black.withOpacity(0.1),
                  blurRadius: elevation!,
                  offset: Offset(0, elevation! / 2),
                ),
              ]
            : null,
      ),
      child: Padding(padding: padding ?? AppSpacing.paddingMd, child: child),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: borderRadius ?? AppSpacing.borderRadiusMd,
        child: card,
      );
    }

    return card;
  }
}

/// AppListTile - Shared ListTile Widget
class AppListTile extends StatelessWidget {
  final Widget? leading;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? contentPadding;
  final bool showDivider;

  const AppListTile({
    super.key,
    this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.contentPadding,
    this.showDivider = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          leading: leading,
          title: Text(title),
          subtitle: subtitle != null ? Text(subtitle!) : null,
          trailing:
              trailing ??
              (onTap != null ? const Icon(Icons.chevron_right) : null),
          onTap: onTap,
          contentPadding: contentPadding,
        ),
        if (showDivider) const Divider(height: 1),
      ],
    );
  }
}
