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
import '../../../../shared/dialogs/app_snackbar.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/language_switcher.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import 'phone_register_otp_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _taxCodeController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final FocusNode _fullNameFocusNode = FocusNode();
  final FocusNode _phoneFocusNode = FocusNode();
  final FocusNode _taxCodeFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  final FocusNode _confirmPasswordFocusNode = FocusNode();

  String? _fullNameError;
  String? _phoneError;
  String? _taxCodeError;
  String? _passwordError;
  String? _confirmPasswordError;

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _taxCodeController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _fullNameFocusNode.dispose();
    _phoneFocusNode.dispose();
    _taxCodeFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _saveRegisterTaxCode() async {
    final taxCode = _taxCodeController.text.trim();
    if (taxCode.isNotEmpty) {
      await SecureStorage().setRegisterTaxCode(taxCode);
    }
  }

  bool _validateCommonForm(AppLocalizations l10n) {
    final fullName = _fullNameController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    FocusNode? firstInvalidFocus;

    String? fullNameError;
    String? phoneError;
    String? passwordError;
    String? confirmPasswordError;

    if (fullName.isEmpty) {
      fullNameError = l10n.translate('common.required_field');
      firstInvalidFocus ??= _fullNameFocusNode;
    }
    if (phone.isEmpty) {
      phoneError = l10n.translate('auth.phone_required');
      firstInvalidFocus ??= _phoneFocusNode;
    }
    if (password.isEmpty) {
      passwordError = l10n.translate('auth.password_required');
      firstInvalidFocus ??= _passwordFocusNode;
    } else if (password.length < 8) {
      passwordError = l10n.translate('auth.password_min_length_8');
      firstInvalidFocus ??= _passwordFocusNode;
    }
    if (confirmPassword.isEmpty) {
      confirmPasswordError = l10n.translate('auth.password_required');
      firstInvalidFocus ??= _confirmPasswordFocusNode;
    } else if (confirmPassword != password) {
      confirmPasswordError = l10n.translate('auth.passwords_not_match');
      firstInvalidFocus ??= _confirmPasswordFocusNode;
    }

    setState(() {
      _fullNameError = fullNameError;
      _phoneError = phoneError;
      _taxCodeError = null;
      _passwordError = passwordError;
      _confirmPasswordError = confirmPasswordError;
    });

    if (firstInvalidFocus != null) {
      FocusScope.of(context).requestFocus(firstInvalidFocus);
      return false;
    }

    return true;
  }

  Future<void> _submit(AppLocalizations l10n) async {
    if (!_validateCommonForm(l10n)) return;

    final phone = _phoneController.text.trim();

    await _saveRegisterTaxCode();
    if (!mounted) return;
    context.read<AuthBloc>().add(
      RegisterWithPhoneRequested(
        phone: phone,
        password: _passwordController.text.trim(),
        fullName: _fullNameController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final localizationProvider = Provider.of<LocalizationProvider>(context);

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is GoogleLoginPhoneLinkRequired) {
          FocusScope.of(context).unfocus();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            AppRouter.navigateAndClearStack(AppRoutes.googlePhoneLink);
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
            ).then((_) {
              if (!mounted) return;
              context.read<AuthBloc>().add(
                const CancelPhoneRegisterFlowRequested(),
              );
            });
          });
        } else if (state is PhoneRegisterFailure) {
          AppSnackBar.error(context, l10n.translateOrRaw(state.message));
        } else if (state is LoginFailure) {
          final msg =
              state.serverMessage ?? l10n.translate('auth.register_failed');
          AppSnackBar.error(context, l10n.translateOrRaw(msg));
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.surface,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: AppColors.surface,
          surfaceTintColor: AppColors.white,
          systemOverlayStyle: SystemUiOverlayStyle.dark,
          automaticallyImplyLeading: false,
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
                  Text(
                    l10n.translate('auth.phone_register_subtitle'),
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  BlocBuilder<AuthBloc, AuthState>(
                    builder: (context, state) {
                      final isLoading =
                          state is SignupInProgress ||
                          state is PhoneRegisterSendOtpInProgress;

                      return Column(
                        children: [
                          AppTextField(
                            controller: _fullNameController,
                            focusNode: _fullNameFocusNode,
                            label: l10n.translate('auth.name'),
                            hintText: l10n.translate('auth.enter_name'),
                            errorText: _fullNameError,
                            onChanged: (_) {
                              if (_fullNameError != null) {
                                setState(() {
                                  _fullNameError = null;
                                });
                              }
                            },
                          ),
                          const SizedBox(height: AppSpacing.md),
                          AppTextField(
                            controller: _phoneController,
                            focusNode: _phoneFocusNode,
                            label: l10n.translate('auth.phone'),
                            hintText: l10n.translate('auth.enter_phone'),
                            keyboardType: TextInputType.phone,
                            errorText: _phoneError,
                            onChanged: (_) {
                              if (_phoneError != null) {
                                setState(() {
                                  _phoneError = null;
                                });
                              }
                            },
                          ),
                          const SizedBox(height: AppSpacing.md),
                          AppTextField(
                            controller: _taxCodeController,
                            focusNode: _taxCodeFocusNode,
                            label: l10n.translate('location.location_tax_code'),
                            hintText: l10n.translate(
                              'location.location_tax_code_hint',
                            ),
                            errorText: _taxCodeError,
                            onChanged: (_) {
                              if (_taxCodeError != null) {
                                setState(() {
                                  _taxCodeError = null;
                                });
                              }
                            },
                          ),
                          const SizedBox(height: AppSpacing.md),
                          AppPasswordField(
                            controller: _passwordController,
                            focusNode: _passwordFocusNode,
                            label: l10n.translate('auth.password'),
                            hintText: l10n.translate('auth.enter_password'),
                            errorText: _passwordError,
                            onChanged: (_) {
                              if (_passwordError != null) {
                                setState(() {
                                  _passwordError = null;
                                });
                              }
                            },
                          ),
                          const SizedBox(height: AppSpacing.md),
                          AppPasswordField(
                            controller: _confirmPasswordController,
                            focusNode: _confirmPasswordFocusNode,
                            label: l10n.translate('auth.confirm_password'),
                            hintText: l10n.translate('auth.confirm_password'),
                            errorText: _confirmPasswordError,
                            onChanged: (_) {
                              if (_confirmPasswordError != null) {
                                setState(() {
                                  _confirmPasswordError = null;
                                });
                              }
                            },
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
                        onTap: () {
                          context.read<AuthBloc>().add(
                            const CancelPhoneRegisterFlowRequested(),
                          );
                          Navigator.pushReplacementNamed(
                            context,
                            AppRoutes.login,
                          );
                        },
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
