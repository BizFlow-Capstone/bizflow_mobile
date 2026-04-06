import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';

/// AppTextField - Shared TextField Widget
/// Stateless, nhận config qua constructor, không import bloc/provider/api
class AppTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? label;
  final String? hintText;
  final String? errorText;
  final String? helperText;
  final bool obscureText;
  final bool enabled;
  final bool readOnly;
  final bool autofocus;
  final int maxLines;
  final int? maxLength;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final bool enableSqlInjectionGuard;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final ValueChanged<String>? onSubmitted;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final FocusNode? focusNode;
  final String? Function(String?)? validator;
  final AutovalidateMode? autovalidateMode;
  final EdgeInsetsGeometry? contentPadding;

  const AppTextField({
    super.key,
    this.controller,
    this.label,
    this.hintText,
    this.errorText,
    this.helperText,
    this.obscureText = false,
    this.enabled = true,
    this.readOnly = false,
    this.autofocus = false,
    this.maxLines = 1,
    this.maxLength,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
    this.enableSqlInjectionGuard = true,
    this.onChanged,
    this.onTap,
    this.onSubmitted,
    this.prefixIcon,
    this.suffixIcon,
    this.focusNode,
    this.validator,
    this.autovalidateMode,
    this.contentPadding,
  });

  bool _isControllerUsable(TextEditingController? target) {
    if (target == null) return false;
    void noop() {}
    try {
      // addListener/removeListener will assert in debug if controller is disposed.
      target.addListener(noop);
      target.removeListener(noop);
      return true;
    } catch (_) {
      return false;
    }
  }

  List<TextInputFormatter>? _buildInputFormatters() {
    return AppInputFormatters.withSqlInjectionGuard(
      inputFormatters: inputFormatters,
      enabled: enableSqlInjectionGuard,
    );
  }

  @override
  Widget build(BuildContext context) {
    final effectiveController = _isControllerUsable(controller)
        ? controller
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text(label!, style: AppTextStyles.labelMedium),
          SizedBox(height: AppSpacing.xs),
        ],
        TextFormField(
          controller: effectiveController,
          obscureText: obscureText,
          enabled: enabled,
          readOnly: readOnly,
          autofocus: autofocus,
          maxLines: maxLines,
          maxLength: maxLength,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          inputFormatters: _buildInputFormatters(),
          onChanged: onChanged,
          onTap: onTap,
          onFieldSubmitted: onSubmitted,
          focusNode: focusNode,
          validator: validator,
          autovalidateMode: autovalidateMode,
          style: AppTextStyles.bodyMedium,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textHint,
            ),
            errorText: errorText,
            helperText: helperText,
            prefixIcon: prefixIcon,
            suffixIcon: suffixIcon,
            contentPadding:
                contentPadding ??
                EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
            filled: true,
            fillColor: enabled ? AppColors.surface : AppColors.divider,
            border: OutlineInputBorder(
              borderRadius: AppSpacing.borderRadiusSm,
              borderSide: BorderSide(color: AppColors.divider),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: AppSpacing.borderRadiusSm,
              borderSide: BorderSide(color: AppColors.divider),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: AppSpacing.borderRadiusSm,
              borderSide: BorderSide(color: AppColors.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: AppSpacing.borderRadiusSm,
              borderSide: BorderSide(color: AppColors.error),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: AppSpacing.borderRadiusSm,
              borderSide: BorderSide(color: AppColors.error, width: 2),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: AppSpacing.borderRadiusSm,
              borderSide: BorderSide(color: AppColors.divider),
            ),
          ),
        ),
      ],
    );
  }
}

class _SqlInjectionGuardFormatter extends TextInputFormatter {
  _SqlInjectionGuardFormatter._();

  static final _SqlInjectionGuardFormatter instance =
      _SqlInjectionGuardFormatter._();

  static final RegExp _blockedChars = RegExp("[\"';`\\\\]");

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final sanitized = newValue.text.replaceAll(_blockedChars, '');
    if (sanitized == newValue.text) {
      return newValue;
    }

    final baseOffset = newValue.selection.baseOffset;
    final extentOffset = newValue.selection.extentOffset;
    final removedCount = newValue.text.length - sanitized.length;

    return TextEditingValue(
      text: sanitized,
      selection: TextSelection(
        baseOffset: (baseOffset - removedCount).clamp(0, sanitized.length),
        extentOffset: (extentOffset - removedCount).clamp(0, sanitized.length),
      ),
      composing: TextRange.empty,
    );
  }
}

class AppInputFormatters {
  AppInputFormatters._();

  static TextInputFormatter get sqlInjectionGuard =>
      _SqlInjectionGuardFormatter.instance;

  static List<TextInputFormatter>? withSqlInjectionGuard({
    List<TextInputFormatter>? inputFormatters,
    bool enabled = true,
  }) {
    final formatters = <TextInputFormatter>[];

    if (enabled) {
      formatters.add(sqlInjectionGuard);
    }

    if (inputFormatters != null && inputFormatters.isNotEmpty) {
      formatters.addAll(inputFormatters);
    }

    return formatters.isEmpty ? null : formatters;
  }
}

/// AppPasswordField - Password TextField với toggle visibility
class AppPasswordField extends StatefulWidget {
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? label;
  final String? hintText;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final String? Function(String?)? validator;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

  const AppPasswordField({
    super.key,
    this.controller,
    this.focusNode,
    this.label,
    this.hintText,
    this.errorText,
    this.onChanged,
    this.validator,
    this.textInputAction,
    this.onSubmitted,
  });

  @override
  State<AppPasswordField> createState() => _AppPasswordFieldState();
}

class _AppPasswordFieldState extends State<AppPasswordField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: widget.controller,
      focusNode: widget.focusNode,
      label: widget.label,
      hintText: widget.hintText,
      errorText: widget.errorText,
      obscureText: _obscureText,
      onChanged: widget.onChanged,
      validator: widget.validator,
      textInputAction: widget.textInputAction,
      onSubmitted: widget.onSubmitted,
      keyboardType: TextInputType.visiblePassword,
      suffixIcon: IconButton(
        icon: Icon(
          _obscureText ? Icons.visibility_off : Icons.visibility,
          color: AppColors.textHint,
        ),
        onPressed: () {
          setState(() {
            _obscureText = !_obscureText;
          });
        },
      ),
    );
  }
}

/// AppSearchField - Search TextField
class AppSearchField extends StatelessWidget {
  final TextEditingController? controller;
  final String? hintText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;
  final ValueChanged<String>? onSubmitted;

  const AppSearchField({
    super.key,
    this.controller,
    this.hintText,
    this.onChanged,
    this.onClear,
    this.onSubmitted,
  });

  bool _hasText(TextEditingController? target) {
    if (target == null) return false;
    try {
      return target.text.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: controller,
      hintText: hintText ?? 'Search...',
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      textInputAction: TextInputAction.search,
      prefixIcon: Icon(Icons.search, color: AppColors.textHint),
      suffixIcon: _hasText(controller)
          ? IconButton(
              icon: Icon(Icons.clear, color: AppColors.textHint),
              onPressed: () {
                controller?.clear();
                onClear?.call();
              },
            )
          : null,
    );
  }
}
