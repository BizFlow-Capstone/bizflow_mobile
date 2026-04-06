import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/dialogs/app_snackbar.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../navigation/post_auth_navigation.dart';

class PhoneRegisterOtpPage extends StatefulWidget {
  final String phone;

  const PhoneRegisterOtpPage({super.key, required this.phone});

  @override
  State<PhoneRegisterOtpPage> createState() => _PhoneRegisterOtpPageState();
}

class _PhoneRegisterOtpPageState extends State<PhoneRegisterOtpPage> {
  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _focusNodes;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(6, (_) => TextEditingController());
    _focusNodes = List.generate(6, (_) => FocusNode());
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  String get _otp => _controllers.map((e) => e.text).join();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is LoginSuccess) {
          PostAuthNavigation.route(context);
        } else if (state is PhoneRegisterFailure) {
          AppSnackBar.error(context, state.message);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.surface,
        appBar: AppBar(
          title: Text(l10n.translate('auth.verify_otp_title')),
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.textPrimary,
          systemOverlayStyle: SystemUiOverlayStyle.dark,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
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
                  Center(
                    child: Image.asset(
                      'assets/images/logos/Bizflow.png',
                      height: 64,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.business,
                        size: 64,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    l10n
                        .translate('auth.otp_sent_to')
                        .replaceAll('{phone}', widget.phone),
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
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
                                controller: _controllers[index],
                                focusNode: _focusNodes[index],
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
                                    _focusNodes[index + 1].requestFocus();
                                  } else if (value.isEmpty && index > 0) {
                                    _focusNodes[index - 1].requestFocus();
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
                  BlocBuilder<AuthBloc, AuthState>(
                    builder: (context, state) {
                      final loading = state is PhoneRegisterInProgress;
                      return AppButton(
                        label: l10n.translate('auth.verify_button'),
                        isFullWidth: true,
                        isLoading: loading,
                        onPressed: loading
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
                                  PhoneOtpCodeSubmitted(smsCode: _otp),
                                );
                              },
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextButton(
                    onPressed: () {
                      context.read<AuthBloc>().add(
                        const ResendPhoneOtpRequested(),
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
