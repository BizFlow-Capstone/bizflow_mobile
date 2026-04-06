import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';

/// Button type enum
enum AppButtonType { primary, secondary, outlined, text, danger }

/// Button size enum
enum AppButtonSize { small, medium, large }

/// AppButton - Shared Button Widget
/// Stateless, nhận config qua constructor, không import bloc/provider/api
class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonType type;
  final AppButtonSize size;
  final bool isLoading;
  final bool isDisabled;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final double? width;
  final bool isFullWidth;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.type = AppButtonType.primary,
    this.size = AppButtonSize.medium,
    this.isLoading = false,
    this.isDisabled = false,
    this.prefixIcon,
    this.suffixIcon,
    this.width,
    this.isFullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: isFullWidth ? double.infinity : width,
      height: _getHeight(),
      child: _buildButton(),
    );
  }

  Widget _buildButton() {
    final child = _buildChild();

    switch (type) {
      case AppButtonType.primary:
        return ElevatedButton(
          onPressed: _isEnabled ? onPressed : null,
          style: _primaryStyle(),
          child: child,
        );

      case AppButtonType.secondary:
        return ElevatedButton(
          onPressed: _isEnabled ? onPressed : null,
          style: _secondaryStyle(),
          child: child,
        );

      case AppButtonType.outlined:
        return OutlinedButton(
          onPressed: _isEnabled ? onPressed : null,
          style: _outlinedStyle(),
          child: child,
        );

      case AppButtonType.text:
        return TextButton(
          onPressed: _isEnabled ? onPressed : null,
          style: _textStyle(),
          child: child,
        );

      case AppButtonType.danger:
        return ElevatedButton(
          onPressed: _isEnabled ? onPressed : null,
          style: _dangerStyle(),
          child: child,
        );
    }
  }

  Widget _buildChild() {
    if (isLoading) {
      return SizedBox(
        width: _getLoadingSize(),
        height: _getLoadingSize(),
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: _getLoadingColor(),
        ),
      );
    }

    final textStyle = _getTextStyle();
    final iconSize = _getIconSize();
    final textColor = _getTextColor();

    return Row(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (prefixIcon != null) ...[
          Icon(prefixIcon, size: iconSize),
          SizedBox(width: AppSpacing.sm),
        ],
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: textStyle.copyWith(color: textColor),
          ),
        ),
        if (suffixIcon != null) ...[
          SizedBox(width: AppSpacing.sm),
          Icon(suffixIcon, size: iconSize),
        ],
      ],
    );
  }

  bool get _isEnabled => !isDisabled && !isLoading;

  double _getHeight() {
    switch (size) {
      case AppButtonSize.small:
        return 36;
      case AppButtonSize.medium:
        return 44;
      case AppButtonSize.large:
        return 52;
    }
  }

  double _getLoadingSize() {
    switch (size) {
      case AppButtonSize.small:
        return 16;
      case AppButtonSize.medium:
        return 20;
      case AppButtonSize.large:
        return 24;
    }
  }

  double _getIconSize() {
    switch (size) {
      case AppButtonSize.small:
        return 16;
      case AppButtonSize.medium:
        return 20;
      case AppButtonSize.large:
        return 24;
    }
  }

  TextStyle _getTextStyle() {
    switch (size) {
      case AppButtonSize.small:
        return AppTextStyles.labelMedium;
      case AppButtonSize.medium:
        return AppTextStyles.labelLarge;
      case AppButtonSize.large:
        return AppTextStyles.titleSmall;
    }
  }

  Color _getTextColor() {
    switch (type) {
      case AppButtonType.primary:
      case AppButtonType.secondary:
      case AppButtonType.danger:
        return AppColors.white;
      case AppButtonType.outlined:
      case AppButtonType.text:
        return AppColors.primary;
    }
  }

  Color _getLoadingColor() {
    switch (type) {
      case AppButtonType.primary:
      case AppButtonType.secondary:
      case AppButtonType.danger:
        return AppColors.white;
      case AppButtonType.outlined:
      case AppButtonType.text:
        return AppColors.primary;
    }
  }

  ButtonStyle _primaryStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.white,
      disabledBackgroundColor: AppColors.disabled,
      disabledForegroundColor: AppColors.white,
      shape: RoundedRectangleBorder(borderRadius: AppSpacing.borderRadiusSm),
      padding: _getPadding(),
    );
  }

  ButtonStyle _secondaryStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: AppColors.secondary,
      foregroundColor: AppColors.white,
      disabledBackgroundColor: AppColors.disabled,
      disabledForegroundColor: AppColors.white,
      shape: RoundedRectangleBorder(borderRadius: AppSpacing.borderRadiusSm),
      padding: _getPadding(),
    );
  }

  ButtonStyle _outlinedStyle() {
    return OutlinedButton.styleFrom(
      foregroundColor: AppColors.primary,
      side: BorderSide(
        color: isDisabled ? AppColors.disabled : AppColors.primary,
      ),
      shape: RoundedRectangleBorder(borderRadius: AppSpacing.borderRadiusSm),
      padding: _getPadding(),
    );
  }

  ButtonStyle _textStyle() {
    return TextButton.styleFrom(
      foregroundColor: AppColors.primary,
      shape: RoundedRectangleBorder(borderRadius: AppSpacing.borderRadiusSm),
      padding: _getPadding(),
    );
  }

  ButtonStyle _dangerStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: AppColors.danger,
      foregroundColor: AppColors.white,
      disabledBackgroundColor: AppColors.disabled,
      disabledForegroundColor: AppColors.white,
      shape: RoundedRectangleBorder(borderRadius: AppSpacing.borderRadiusSm),
      padding: _getPadding(),
    );
  }

  EdgeInsetsGeometry _getPadding() {
    switch (size) {
      case AppButtonSize.small:
        return EdgeInsets.symmetric(horizontal: AppSpacing.sm);
      case AppButtonSize.medium:
        return EdgeInsets.symmetric(horizontal: AppSpacing.md);
      case AppButtonSize.large:
        return EdgeInsets.symmetric(horizontal: AppSpacing.lg);
    }
  }
}
