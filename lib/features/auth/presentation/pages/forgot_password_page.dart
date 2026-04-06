import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/dialogs/app_snackbar.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../bloc/auth_bloc.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final TextEditingController _emailController = TextEditingController();
  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();

  int _step = 1;
  String? _confirmPasswordError;

  @override
  void dispose() {
    _emailController.dispose();
    for (final c in _otpControllers) {
      c.dispose();
    }
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  String get _otp => _otpControllers.map((e) => e.text).join();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is ForgotPasswordOtpSent) {
          setState(() {
            _step = 2;
          });
          AppSnackBar.success(context, l10n.translate('auth.otp_sent_generic'));
        } else if (state is ForgotPasswordOtpVerified) {
          setState(() {
            _step = 3;
          });
        } else if (state is ForgotPasswordResetSuccess) {
          AppSnackBar.success(
            context,
            l10n.translate('auth.reset_password_success'),
          );
          AppRouter.navigateAndClearStack(AppRoutes.login);
        } else if (state is ForgotPasswordFailure) {
          AppSnackBar.error(context, state.message);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.surface,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: AppColors.surface,
          surfaceTintColor: AppColors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => AppRouter.pop(),
          ),
          title: Text(
            l10n.translate('auth.forgot_password'),
            style: AppTextStyles.titleLarge,
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.divider),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n
                        .translate('auth.forgot_password_step')
                        .replaceAll('{step}', _step.toString()),
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (_step == 1) ...[
                    AppTextField(
                      controller: _emailController,
                      label: l10n.translate('auth.email'),
                      hintText: l10n.translate('auth.enter_email'),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _buildActionButton(
                      context,
                      l10n.translate('auth.send_otp'),
                      onPressed: () {
                        final email = _emailController.text.trim();
                        if (email.isEmpty) {
                          AppSnackBar.warning(
                            context,
                            l10n.translate('auth.email_required'),
                          );
                          return;
                        }
                        context.read<AuthBloc>().add(
                          ForgotPasswordSendOtpRequested(email: email),
                        );
                      },
                    ),
                  ],
                  if (_step == 2) ...[
                    Text(
                      l10n
                          .translate('auth.otp_sent_to_email')
                          .replaceAll('{email}', _emailController.text.trim()),
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(6, (index) {
                        return SizedBox(
                          width: 44,
                          child: TextField(
                            controller: _otpControllers[index],
                            maxLength: 1,
                            textAlign: TextAlign.center,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              ...?AppInputFormatters.withSqlInjectionGuard(
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                              ),
                            ],
                            decoration: const InputDecoration(counterText: ''),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _buildActionButton(
                      context,
                      l10n.translate('auth.verify_button'),
                      onPressed: () {
                        if (_otp.length != 6) {
                          AppSnackBar.warning(
                            context,
                            l10n.translate('auth.otp_incomplete'),
                          );
                          return;
                        }
                        context.read<AuthBloc>().add(
                          ForgotPasswordVerifyOtpRequested(
                            email: _emailController.text.trim(),
                            otpCode: _otp,
                          ),
                        );
                      },
                    ),
                  ],
                  if (_step == 3) ...[
                    AppPasswordField(
                      controller: _passwordController,
                      label: l10n.translate('auth.password'),
                      hintText: l10n.translate('auth.enter_password'),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppPasswordField(
                      controller: _confirmController,
                      label: l10n.translate('auth.confirm_password'),
                      hintText: l10n.translate('auth.confirm_password'),
                      errorText: _confirmPasswordError,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _buildActionButton(
                      context,
                      l10n.translate('auth.reset_password_button'),
                      onPressed: () {
                        final password = _passwordController.text;
                        final confirm = _confirmController.text;
                        if (password.length < 8) {
                          AppSnackBar.warning(
                            context,
                            l10n.translate('auth.password_min_length_8'),
                          );
                          return;
                        }
                        if (password != confirm) {
                          setState(() {
                            _confirmPasswordError =
                                l10n.translate('auth.passwords_not_match');
                          });
                          return;
                        }
                        setState(() {
                          _confirmPasswordError = null;
                        });
                        context.read<AuthBloc>().add(
                          ForgotPasswordResetRequested(password: password),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    String label, {
    required VoidCallback onPressed,
  }) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final loading = state is ForgotPasswordInProgress;
        return AppButton(
          label: label,
          isFullWidth: true,
          isLoading: loading,
          onPressed: loading ? null : onPressed,
          size: AppButtonSize.large,
        );
      },
    );
  }
}
