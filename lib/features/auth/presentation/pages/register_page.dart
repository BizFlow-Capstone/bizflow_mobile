import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/providers/localization_provider.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/language_switcher.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import 'phone_register_otp_page.dart';

enum _RegisterMode { email, phone }

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _taxCodeController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  _RegisterMode _registerMode = _RegisterMode.email;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _taxCodeController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool get _isPhoneMode => _registerMode == _RegisterMode.phone;

  Future<void> _saveRegisterTaxCode() async {
    final taxCode = _taxCodeController.text.trim();
    if (taxCode.isNotEmpty) {
      await SecureStorage().setRegisterTaxCode(taxCode);
    }
  }

  bool _validateCommonForm(AppLocalizations l10n) {
    final fullName = _fullNameController.text.trim();
    final taxCode = _taxCodeController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (fullName.isEmpty || taxCode.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.translate('common.required_field')),
          backgroundColor: AppColors.warning,
        ),
      );
      return false;
    }

    if (confirmPassword != password) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.translate('auth.passwords_not_match')),
          backgroundColor: AppColors.warning,
        ),
      );
      return false;
    }

    return true;
  }

  Future<void> _submit(AppLocalizations l10n) async {
    if (!_validateCommonForm(l10n)) return;

    if (_isPhoneMode) {
      final phone = _phoneController.text.trim();
      if (phone.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.translate('auth.phone_required')),
            backgroundColor: AppColors.warning,
          ),
        );
        return;
      }

      await _saveRegisterTaxCode();
      if (!mounted) return;
      context.read<AuthBloc>().add(
        RegisterWithPhoneRequested(
          phone: phone,
          password: _passwordController.text.trim(),
          fullName: _fullNameController.text.trim(),
        ),
      );
      return;
    }

    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.translate('auth.email_required')),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    await _saveRegisterTaxCode();
    if (!mounted) return;
    context.read<AuthBloc>().add(
      SignupRequested(
        name: _fullNameController.text.trim(),
        phone: '',
        email: email,
        password: _passwordController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final localizationProvider = Provider.of<LocalizationProvider>(context);

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is LoginSuccess) {
          FocusScope.of(context).unfocus();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            AppRouter.navigateAndClearStack(AppRoutes.home);
          });
        } else if (state is GoogleLoginSetPasswordRequired) {
          FocusScope.of(context).unfocus();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            AppRouter.navigateAndClearStack(AppRoutes.setPassword);
          });
        } else if (state is PhoneOtpCodeSent) {
          FocusScope.of(context).unfocus();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PhoneRegisterOtpPage(phone: state.phone),
              ),
            );
          });
        } else if (state is PhoneRegisterFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.danger,
            ),
          );
        } else if (state is LoginFailure) {
          final msg =
              state.serverMessage ?? l10n.translate('auth.register_failed');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(msg), backgroundColor: AppColors.danger),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.surface,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: AppColors.surface,
          surfaceTintColor: AppColors.white,
          systemOverlayStyle: SystemUiOverlayStyle.dark,
          actions: [
            LanguageSwitcher(
              currentLocale: localizationProvider.currentLocale,
              onLanguageChanged: (locale) {
                localizationProvider.setLocale(locale);
              },
            ),
            SizedBox(width: AppSpacing.md),
          ],
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
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/logos/Bizflow.png',
                    height: 64,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.business,
                      size: 64,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    l10n.translate('auth.create_account'),
                    style: AppTextStyles.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        l10n.translate('auth.register_subtitle'),
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: AppButton(
                          label: l10n.translate('auth.register_with_email'),
                          onPressed: () {
                            setState(() {
                              _registerMode = _RegisterMode.email;
                            });
                          },
                          type: _isPhoneMode
                              ? AppButtonType.outlined
                              : AppButtonType.primary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      SizedBox(
                        width: double.infinity,
                        child: AppButton(
                          label: l10n.translate('auth.register_with_phone'),
                          onPressed: () {
                            setState(() {
                              _registerMode = _RegisterMode.phone;
                            });
                          },
                          type: _isPhoneMode
                              ? AppButtonType.primary
                              : AppButtonType.outlined,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    _isPhoneMode
                        ? l10n.translate('auth.phone_register_subtitle')
                        : l10n.translate('auth.email_register_subtitle'),
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  BlocBuilder<AuthBloc, AuthState>(
                    builder: (context, state) {
                      final isLoading =
                          state is LoginInProgress ||
                          state is SignupInProgress ||
                          state is PhoneRegisterInProgress;

                      return Column(
                        children: [
                          AppTextField(
                            controller: _fullNameController,
                            label: l10n.translate('auth.name'),
                            hintText: l10n.translate('auth.enter_name'),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          if (_isPhoneMode)
                            AppTextField(
                              controller: _phoneController,
                              label: l10n.translate('auth.phone'),
                              hintText: l10n.translate('auth.enter_phone'),
                              keyboardType: TextInputType.phone,
                            )
                          else
                            AppTextField(
                              controller: _emailController,
                              label: l10n.translate('auth.email'),
                              hintText: l10n.translate('auth.enter_email'),
                              keyboardType: TextInputType.emailAddress,
                            ),
                          const SizedBox(height: AppSpacing.md),
                          AppTextField(
                            controller: _taxCodeController,
                            label: l10n.translate('location.location_tax_code'),
                            hintText: l10n.translate(
                              'location.location_tax_code_hint',
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          AppPasswordField(
                            controller: _passwordController,
                            label: l10n.translate('auth.password'),
                            hintText: l10n.translate('auth.enter_password'),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          AppPasswordField(
                            controller: _confirmPasswordController,
                            label: l10n.translate('auth.confirm_password'),
                            hintText: l10n.translate('auth.confirm_password'),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          AppButton(
                            label: l10n.translate('auth.sign_up'),
                            isFullWidth: true,
                            isLoading: isLoading,
                            onPressed: isLoading ? null : () => _submit(l10n),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${l10n.translate('auth.already_have_account')} ',
                        style: AppTextStyles.bodyMedium,
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pushReplacementNamed(
                          context,
                          AppRoutes.login,
                        ),
                        child: Text(
                          l10n.translate('auth.sign_in'),
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
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
