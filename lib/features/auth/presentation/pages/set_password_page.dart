import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

/// Set Password page — shown for new Google accounts (isNewAccount=true)
class SetPasswordPage extends StatefulWidget {
  const SetPasswordPage({super.key});

  @override
  State<SetPasswordPage> createState() => _SetPasswordPageState();
}

class _SetPasswordPageState extends State<SetPasswordPage> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _passwordFocus = FocusNode();
  final _confirmFocus = FocusNode();

  bool _isPasswordVisible = false;
  bool _isConfirmVisible = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    _passwordFocus.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  void _handleSubmit(AppLocalizations l10n) {
    final password = _passwordController.text;
    final confirm = _confirmController.text;

    if (password.length < 8) {
      _showError(l10n.translate('auth.password_min_length_8'));
      return;
    }
    if (password != confirm) {
      _showError(l10n.translate('auth.passwords_not_match'));
      return;
    }

    context.read<AuthBloc>().add(SetPasswordRequested(password: password));
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.danger),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is SetPasswordSuccess) {
          AppRouter.navigateAndClearStack(AppRoutes.home);
        } else if (state is SetPasswordFailure) {
          _showError(state.message);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.white,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          surfaceTintColor: AppColors.white,
          automaticallyImplyLeading: false,
          title: Text(
            l10n.translate('auth.set_password_title'),
            style: AppTextStyles.titleLarge,
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppSpacing.lg),
                Text(
                  l10n.translate('auth.set_password_subtitle'),
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                // Password field
                AppTextField(
                  controller: _passwordController,
                  focusNode: _passwordFocus,
                  label: l10n.translate('auth.password'),
                  hintText: l10n.translate('auth.enter_password'),
                  obscureText: !_isPasswordVisible,
                  textInputAction: TextInputAction.next,
                  suffixIcon: GestureDetector(
                    onTap: () =>
                        setState(() => _isPasswordVisible = !_isPasswordVisible),
                    child: Icon(
                      _isPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  onSubmitted: (_) =>
                      FocusScope.of(context).requestFocus(_confirmFocus),
                ),
                const SizedBox(height: AppSpacing.md),

                // Confirm password field
                AppTextField(
                  controller: _confirmController,
                  focusNode: _confirmFocus,
                  label: l10n.translate('auth.confirm_password'),
                  hintText: l10n.translate('auth.enter_password'),
                  obscureText: !_isConfirmVisible,
                  textInputAction: TextInputAction.done,
                  suffixIcon: GestureDetector(
                    onTap: () =>
                        setState(() => _isConfirmVisible = !_isConfirmVisible),
                    child: Icon(
                      _isConfirmVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                // Submit button
                BlocBuilder<AuthBloc, AuthState>(
                  builder: (context, state) {
                    return AppButton(
                      label: l10n.translate('auth.set_password_button'),
                      isFullWidth: true,
                      isLoading: state is SetPasswordInProgress,
                      onPressed: state is SetPasswordInProgress
                          ? null
                          : () => _handleSubmit(l10n),
                      type: AppButtonType.primary,
                      size: AppButtonSize.large,
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
