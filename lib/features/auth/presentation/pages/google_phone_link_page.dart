import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/dialogs/app_snackbar.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class GooglePhoneLinkPage extends StatefulWidget {
  const GooglePhoneLinkPage({super.key});

  @override
  State<GooglePhoneLinkPage> createState() => _GooglePhoneLinkPageState();
}

class _GooglePhoneLinkPageState extends State<GooglePhoneLinkPage> {
  final TextEditingController _phoneController = TextEditingController();
  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode());

  bool _otpSent = false;

  @override
  void dispose() {
    _phoneController.dispose();
    for (final c in _otpControllers) {
      c.dispose();
    }
    for (final node in _otpFocusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  String get _otp => _otpControllers.map((e) => e.text).join();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is LinkPhoneOtpCodeSent) {
          setState(() {
            _otpSent = true;
          });
        } else if (state is GoogleLoginSetPasswordRequired) {
          AppRouter.navigateAndClearStack(AppRoutes.setPassword);
        } else if (state is LinkCredentialFailure) {
          AppSnackBar.error(context, state.message);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.surface,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(l10n.translate('auth.link_phone_required_title')),
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.textPrimary,
          systemOverlayStyle: SystemUiOverlayStyle.dark,
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
                    l10n.translate('auth.link_phone_required_subtitle'),
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppTextField(
                    controller: _phoneController,
                    label: l10n.translate('auth.phone'),
                    hintText: l10n.translate('auth.enter_phone'),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  BlocBuilder<AuthBloc, AuthState>(
                    builder: (context, state) {
                      final isLoading = state is LinkCredentialInProgress;
                      return AppButton(
                        label: _otpSent
                            ? l10n.translate('auth.resend_otp')
                            : l10n.translate('auth.send_otp'),
                        isFullWidth: true,
                        isLoading: isLoading,
                        onPressed: isLoading
                            ? null
                            : () {
                                final phone = _phoneController.text.trim();
                                if (phone.isEmpty) {
                                  AppSnackBar.warning(
                                    context,
                                    l10n.translate('auth.phone_required'),
                                  );
                                  return;
                                }
                                context.read<AuthBloc>().add(
                                  StartLinkPhoneRequested(phone: phone),
                                );
                              },
                      );
                    },
                  ),
                  if (_otpSent) ...[
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      l10n
                          .translate('auth.otp_sent_to')
                          .replaceAll('{phone}', _phoneController.text.trim()),
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        const gap = 8.0;
                        final rawWidth = (constraints.maxWidth - (5 * gap)) / 6;
                        final boxWidth = rawWidth.clamp(44.0, 56.0);

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
                    const SizedBox(height: AppSpacing.lg),
                    BlocBuilder<AuthBloc, AuthState>(
                      builder: (context, state) {
                        final isLoading = state is LinkCredentialInProgress;
                        return AppButton(
                          label: l10n.translate('auth.verify_button'),
                          isFullWidth: true,
                          isLoading: isLoading,
                          onPressed: isLoading
                              ? null
                              : () {
                                  if (_otp.length != 6) {
                                    AppSnackBar.warning(
                                      context,
                                      l10n.translate('auth.otp_incomplete'),
                                    );
                                    return;
                                  }
                                  context.read<AuthBloc>().add(
                                    SubmitLinkPhoneOtpRequested(smsCode: _otp),
                                  );
                                },
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
}
