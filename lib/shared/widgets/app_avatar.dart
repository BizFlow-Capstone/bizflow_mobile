import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

/// AppAvatar - Shared Avatar Widget
class AppAvatar extends StatelessWidget {
  final String? imageUrl;
  final String? name;
  final double size;
  final Color? backgroundColor;
  final VoidCallback? onTap;

  const AppAvatar({
    super.key,
    this.imageUrl,
    this.name,
    this.size = 40,
    this.backgroundColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final avatar = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.primary,
        shape: BoxShape.circle,
        image: imageUrl != null
            ? DecorationImage(image: NetworkImage(imageUrl!), fit: BoxFit.cover)
            : null,
      ),
      child: imageUrl == null
          ? Center(
              child: Text(
                _getInitials(),
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: size * 0.4,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : null,
    );

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: avatar);
    }

    return avatar;
  }

  String _getInitials() {
    if (name == null || name!.isEmpty) return '?';

    final words = name!.trim().split(' ');
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    }
    return name![0].toUpperCase();
  }
}

/// AppBadge - Shared Badge Widget
class AppBadge extends StatelessWidget {
  final Widget child;
  final String? label;
  final int? count;
  final Color? backgroundColor;
  final Color? textColor;
  final bool showBadge;

  const AppBadge({
    super.key,
    required this.child,
    this.label,
    this.count,
    this.backgroundColor,
    this.textColor,
    this.showBadge = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!showBadge || (count == null && label == null)) {
      return child;
    }

    final displayText = label ?? (count! > 99 ? '99+' : count.toString());

    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          right: -4,
          top: -4,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.xs,
              vertical: 2,
            ),
            constraints: BoxConstraints(minWidth: 18),
            decoration: BoxDecoration(
              color: backgroundColor ?? AppColors.danger,
              borderRadius: AppSpacing.borderRadiusFull,
            ),
            child: Text(
              displayText,
              style: TextStyle(
                color: textColor ?? AppColors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }
}

/// AppChip - Shared Chip Widget
class AppChip extends StatelessWidget {
  final String label;
  final Color? backgroundColor;
  final Color? textColor;
  final IconData? icon;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final bool isSelected;

  const AppChip({
    super.key,
    required this.label,
    this.backgroundColor,
    this.textColor,
    this.icon,
    this.onTap,
    this.onDelete,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor =
        backgroundColor ?? (isSelected ? AppColors.primary : AppColors.divider);
    final fgColor =
        textColor ?? (isSelected ? AppColors.white : AppColors.textPrimary);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: AppSpacing.borderRadiusFull,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: fgColor),
              SizedBox(width: AppSpacing.xs),
            ],
            Text(
              label,
              style: TextStyle(
                color: fgColor,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (onDelete != null) ...[
              SizedBox(width: AppSpacing.xs),
              GestureDetector(
                onTap: onDelete,
                child: Icon(Icons.close, size: 16, color: fgColor),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
