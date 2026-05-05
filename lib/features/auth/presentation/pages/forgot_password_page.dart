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
  final TextEditingController _identifierController = TextEditingController();
  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode());
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();

  int _step = 1;
  ForgotPasswordChannel _channel = ForgotPasswordChannel.email;
  String? _confirmPasswordError;

  @override
  void dispose() {
    _identifierController.dispose();
    for (final c in _otpControllers) {
      c.dispose();
    }
    for (final node in _otpFocusNodes) {
      node.dispose();
    }
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  String get _otp => _otpControllers.map((e) => e.text).join();

  bool get _isPhoneChannel => _channel == ForgotPasswordChannel.phone;

  String get _currentIdentifier => _identifierController.text.trim();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is ForgotPasswordOtpSent) {
          setState(() {
            _step = 2;
            _channel = state.channel;
          });
          final sentMessage = state.channel == ForgotPasswordChannel.phone
              ? l10n.translate('auth.otp_sent_generic_phone')
              : l10n.translate('auth.otp_sent_generic');
          AppSnackBar.success(context, sentMessage);
        } else if (state is ForgotPasswordOtpVerified) {
          setState(() {
            _step = 3;
          });
        } else if (state is ForgotPasswordResetSuccess) {
          AppSnackBar.success(
            context,
            l10n.translate('auth.reset_password_success'),
          );
          if (!mounted) return;
          Navigator.of(context).pushNamedAndRemoveUntil(
            AppRoutes.login,
            (route) => false,
          );
        } else if (state is ForgotPasswordFailure) {
          AppSnackBar.error(context, l10n.translateOrRaw(state.message));
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.surface,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: AppColors.surface,
          surfaceTintColor: AppColors.white,
          systemOverlayStyle: SystemUiOverlayStyle.dark,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              // If user verified OTP but hasn't set password (step 3), clear temporary token
              if (_step == 3) {
                context.read<AuthBloc>().add(const LogoutRequested());
              }
              AppRouter.pop();
            },
            color: Colors.black,
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
                    Text(
                      l10n.translate('auth.forgot_password_method_label'),
                      style: AppTextStyles.labelMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.sm,
                      children: [
                        ChoiceChip(
                          label: Text(
                            l10n.translate('auth.forgot_password_via_email'),
                          ),
                          selected: !_isPhoneChannel,
                          onSelected: (_) {
                            setState(() {
                              _channel = ForgotPasswordChannel.email;
                            });
                          },
                        ),
                        ChoiceChip(
                          label: Text(
                            l10n.translate('auth.forgot_password_via_phone'),
                          ),
                          selected: _isPhoneChannel,
                          onSelected: (_) {
                            setState(() {
                              _channel = ForgotPasswordChannel.phone;
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppTextField(
                      controller: _identifierController,
                      label: _isPhoneChannel
                          ? l10n.translate('auth.phone')
                          : l10n.translate('auth.email'),
                      hintText: _isPhoneChannel
                          ? l10n.translate('auth.enter_phone')
                          : l10n.translate('auth.enter_email'),
                      keyboardType: _isPhoneChannel
                          ? TextInputType.phone
                          : TextInputType.emailAddress,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _buildActionButton(
                      context,
                      l10n.translate('auth.send_otp'),
                      onPressed: () {
                        final identifier = _currentIdentifier;
                        if (identifier.isEmpty) {
                          AppSnackBar.warning(
                            context,
                            _isPhoneChannel
                                ? l10n.translate('auth.phone_required')
                                : l10n.translate('auth.email_required'),
                          );
                          return;
                        }
                        context.read<AuthBloc>().add(
                          ForgotPasswordSendOtpRequested(
                            identifier: identifier,
                            channel: _channel,
                          ),
                        );
                      },
                    ),
                  ],
                  if (_step == 2) ...[
                    Text(
                      _isPhoneChannel
                          ? l10n
                                .translate('auth.otp_sent_to_phone')
                                .replaceAll('{phone}', _currentIdentifier)
                          : l10n
                                .translate('auth.otp_sent_to_email')
                                .replaceAll('{email}', _currentIdentifier),
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final gap = constraints.maxWidth < 320 ? 6.0 : 8.0;
                        final availableWidth = constraints.maxWidth - (5 * gap);
                        final rawWidth = availableWidth / 6;
                        final boxWidth = rawWidth.clamp(34.0, 56.0);

                        return Row(
                          children: List.generate(6, (index) {
                            return Padding(
                              padding: EdgeInsets.only(
                                right: index == 5 ? 0 : gap,
                              ),
                              child: SizedBox(
                                width: boxWidth,
                                height: 76,
                                child: TextField(
                                  controller: _otpControllers[index],
                                  focusNode: _otpFocusNodes[index],
                                  maxLength: 1,
                                  keyboardType: TextInputType.number,
                                  textAlign: TextAlign.center,
                                  textAlignVertical: TextAlignVertical.center,
                                  textDirection: TextDirection.ltr,
                                  style: AppTextStyles.titleLarge.copyWith(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w700,
                                    height: 1.0,
                                  ),
                                  inputFormatters: [
                                    ...?AppInputFormatters.withSqlInjectionGuard(
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                      ],
                                    ),
                                  ],
                                  decoration: const InputDecoration(
                                    counterText: '',
                                    isCollapsed: true,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                  onChanged: (value) {
                                    if (value.isNotEmpty && index < 5) {
                                      _otpFocusNodes[index + 1].requestFocus();
                                    } else if (value.isEmpty && index > 0) {
                                      _otpFocusNodes[index - 1].requestFocus();
                                    }
                                  },
                                ),
                              ),
                            );
                          }),
                        );
                      },
                    ),
                    const SizedBox(height: AppSpacing.xl),
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
                            identifier: _currentIdentifier,
                            otpCode: _otp,
                            channel: _channel,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Center(
                      child: TextButton(
                        onPressed: () {
                          context.read<AuthBloc>().add(
                            ForgotPasswordSendOtpRequested(
                              identifier: _currentIdentifier,
                              channel: _channel,
                            ),
                          );
                        },
                        child: Text(
                          l10n.translate('auth.resend_otp'),
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
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
