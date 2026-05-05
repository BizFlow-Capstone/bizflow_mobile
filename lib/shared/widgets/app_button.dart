import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';

/// Button type enum
enum AppButtonType { primary, secondary, outlined, text, danger }

/// Button size enum
enum AppButtonSize { small, medium, large }

/// AppButton - Shared Button Widget
/// Includes lightweight tap cooldown to reduce accidental rapid re-taps.
class AppButton extends StatefulWidget {
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
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  static const Duration _tapCooldown = Duration(milliseconds: 250);

  bool _tapLocked = false;
  DateTime? _lastTapAt;
  int _lockVersion = 0;

  @override
  void didUpdateWidget(covariant AppButton oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  void _lockFor(Duration duration) {
    _lockVersion += 1;
    final version = _lockVersion;

    if (!_tapLocked) {
      _tapLocked = true;
      if (mounted) {
        setState(() {});
      }
    }

    Future<void>.delayed(duration, () {
      if (!mounted || version != _lockVersion) return;
      _tapLocked = false;
      setState(() {});
    });
  }

  void _handleTap() {
    if (!_isEnabled) return;

    final now = DateTime.now();
    final lastTapAt = _lastTapAt;
    if (lastTapAt != null && now.difference(lastTapAt) < _tapCooldown) {
      return;
    }

    _lastTapAt = now;
    _lockFor(_tapCooldown);
    widget.onPressed?.call();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.isFullWidth ? double.infinity : widget.width,
      height: _getHeight(),
      child: _buildButton(),
    );
  }

  Widget _buildButton() {
    final child = _buildChild();

    switch (widget.type) {
      case AppButtonType.primary:
        return ElevatedButton(
          onPressed: _isEnabled ? _handleTap : null,
          style: _primaryStyle(),
          child: child,
        );

      case AppButtonType.secondary:
        return ElevatedButton(
          onPressed: _isEnabled ? _handleTap : null,
          style: _secondaryStyle(),
          child: child,
        );

      case AppButtonType.outlined:
        return OutlinedButton(
          onPressed: _isEnabled ? _handleTap : null,
          style: _outlinedStyle(),
          child: child,
        );

      case AppButtonType.text:
        return TextButton(
          onPressed: _isEnabled ? _handleTap : null,
          style: _textStyle(),
          child: child,
        );

      case AppButtonType.danger:
        return ElevatedButton(
          onPressed: _isEnabled ? _handleTap : null,
          style: _dangerStyle(),
          child: child,
        );
    }
  }

  Widget _buildChild() {
    if (widget.isLoading) {
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
        if (widget.prefixIcon != null) ...[
          Icon(widget.prefixIcon, size: iconSize),
          SizedBox(width: AppSpacing.sm),
        ],
        Flexible(
          child: Text(
            widget.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: textStyle.copyWith(color: textColor),
          ),
        ),
        if (widget.suffixIcon != null) ...[
          SizedBox(width: AppSpacing.sm),
          Icon(widget.suffixIcon, size: iconSize),
        ],
      ],
    );
  }

  bool get _isEnabled => !widget.isDisabled && !widget.isLoading && !_tapLocked;

  double _getHeight() {
    switch (widget.size) {
      case AppButtonSize.small:
        return 36;
      case AppButtonSize.medium:
        return 44;
      case AppButtonSize.large:
        return 52;
    }
  }

  double _getLoadingSize() {
    switch (widget.size) {
      case AppButtonSize.small:
        return 16;
      case AppButtonSize.medium:
        return 20;
      case AppButtonSize.large:
        return 24;
    }
  }

  double _getIconSize() {
    switch (widget.size) {
      case AppButtonSize.small:
        return 16;
      case AppButtonSize.medium:
        return 20;
      case AppButtonSize.large:
        return 24;
    }
  }

  TextStyle _getTextStyle() {
    switch (widget.size) {
      case AppButtonSize.small:
        return AppTextStyles.labelMedium;
      case AppButtonSize.medium:
        return AppTextStyles.labelLarge;
      case AppButtonSize.large:
        return AppTextStyles.titleSmall;
    }
  }

  Color _getTextColor() {
    switch (widget.type) {
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
    switch (widget.type) {
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
        color: widget.isDisabled ? AppColors.disabled : AppColors.primary,
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
    switch (widget.size) {
      case AppButtonSize.small:
        return EdgeInsets.symmetric(horizontal: AppSpacing.sm);
      case AppButtonSize.medium:
        return EdgeInsets.symmetric(horizontal: AppSpacing.md);
      case AppButtonSize.large:
        return EdgeInsets.symmetric(horizontal: AppSpacing.lg);
    }
  }
}
