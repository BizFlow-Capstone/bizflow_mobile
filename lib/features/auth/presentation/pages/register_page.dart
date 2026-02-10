import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
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
import 'verify_otp_page.dart';
import 'login_page.dart';

/// SC-AUT-01: Register Page
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  late TextEditingController _nameController;

  late FocusNode _phoneFocus;
  late FocusNode _emailFocus;
  late FocusNode _passwordFocus;
  late FocusNode _nameFocus;

  bool _isPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    _phoneController = TextEditingController();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _nameController = TextEditingController();

    _phoneFocus = FocusNode();
    _emailFocus = FocusNode();
    _passwordFocus = FocusNode();
    _nameFocus = FocusNode();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();

    _phoneFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _nameFocus.dispose();
    super.dispose();
  }

  void _handleRegister(AppLocalizations l10n) {
    if (_nameController.text.isEmpty) {
      _showError(l10n.translate('auth.name_required'));
      return;
    }

    if (_phoneController.text.isEmpty) {
      _showError(l10n.translate('auth.phone_required'));
      return;
    }

    if (_emailController.text.isEmpty) {
      _showError(l10n.translate('auth.email_required'));
      return;
    }

    if (_passwordController.text.isEmpty) {
      _showError(l10n.translate('auth.password_required'));
      return;
    }

    context.read<AuthBloc>().add(
      SignupRequested(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      ),
    );
  }

  void _handleGoogleRegister() {
    // TODO: Google signup
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.danger,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final localizationProvider = Provider.of<LocalizationProvider>(context);


    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.white,
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
      body: _RegisterPageContent(
        l10n: l10n,
        nameController: _nameController,
        phoneController: _phoneController,
        emailController: _emailController,
        passwordController: _passwordController,
        nameFocus: _nameFocus,
        phoneFocus: _phoneFocus,
        emailFocus: _emailFocus,
        passwordFocus: _passwordFocus,
        isPasswordVisible: _isPasswordVisible,
        onPasswordVisibilityChanged: (value) {
          setState(() {
            _isPasswordVisible = value;
          });
        },
        onRegister: () => _handleRegister(l10n),
        onGoogleRegister: _handleGoogleRegister,
      ),
    );
  }
}

class _RegisterPageContent extends StatelessWidget {
  final AppLocalizations l10n;
  final TextEditingController nameController;
  final TextEditingController phoneController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final FocusNode nameFocus;
  final FocusNode phoneFocus;
  final FocusNode emailFocus;
  final FocusNode passwordFocus;
  final bool isPasswordVisible;
  final Function(bool) onPasswordVisibilityChanged;
  final VoidCallback onRegister;
  final VoidCallback onGoogleRegister;

  const _RegisterPageContent({
    required this.l10n,
    required this.nameController,
    required this.phoneController,
    required this.emailController,
    required this.passwordController,
    required this.nameFocus,
    required this.phoneFocus,
    required this.emailFocus,
    required this.passwordFocus,
    required this.isPasswordVisible,
    required this.onPasswordVisibilityChanged,
    required this.onRegister,
    required this.onGoogleRegister,

  });

  @override
  Widget build(BuildContext context) {
    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is SignupSuccess) {
          _showSuccess(context, l10n.translate('auth.register_success'));
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => VerifyOtpPage(
                phoneNumber: phoneController.text.trim(),
              ),
            ),
          );
        } else if (state is SignupFailure) {
          final errorMessage = _mapErrorCodeToLocalization(state.errorCode);
          _showError(context, errorMessage);
        }
      },
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (!isKeyboardOpen) ...[
                SizedBox(height: AppSpacing.lg),
                const Icon(
                  Icons.business,
                  size: 60,
                  color: Color(0xFF23C4C1),
                ),
                SizedBox(height: AppSpacing.md),
              ],
              Text(
                l10n.translate('auth.create_account'),
                style: AppTextStyles.headlineSmall,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: AppSpacing.sm),
              Text(
                l10n.translate('auth.register_subtitle'),
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: AppSpacing.xl),
              AppTextField(
                controller: nameController,
                focusNode: nameFocus,
                label: l10n.translate('auth.name'),
                hintText: l10n.translate('auth.enter_name'),
                keyboardType: TextInputType.name,
                textInputAction: TextInputAction.next,
                onSubmitted: (_) {
                  FocusScope.of(context).requestFocus(phoneFocus);
                },
              ),
              SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: phoneController,
                focusNode: phoneFocus,
                label: l10n.translate('auth.phone'),
                hintText: l10n.translate('auth.enter_phone'),
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                onSubmitted: (_) {
                  FocusScope.of(context).requestFocus(emailFocus);
                },
              ),
              SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: emailController,
                focusNode: emailFocus,
                label: l10n.translate('auth.email'),
                hintText: l10n.translate('auth.enter_email'),
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                onSubmitted: (_) {
                  FocusScope.of(context).requestFocus(passwordFocus);
                },
              ),
              SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: passwordController,
                focusNode: passwordFocus,
                label: l10n.translate('auth.password'),
                hintText: l10n.translate('auth.enter_password'),
                obscureText: !isPasswordVisible,
                textInputAction: TextInputAction.done,
                suffixIcon: GestureDetector(
                  onTap: () => onPasswordVisibilityChanged(!isPasswordVisible),
                  child: Icon(
                    isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              SizedBox(height: AppSpacing.xl),
              BlocBuilder<AuthBloc, AuthState>(
                builder: (context, state) {
                  return AppButton(
                    label: l10n.translate('auth.sign_up'),
                    isFullWidth: true,
                    isLoading: state is SignupInProgress,
                    onPressed: state is SignupInProgress ? null : onRegister,
                    type: AppButtonType.secondary,
                    size: AppButtonSize.large,
                  );
                },
              ),
              SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: Divider(color: AppColors.divider, thickness: 1),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                    child: Text(
                      l10n.translate('auth.or_divider'),
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Divider(color: AppColors.divider, thickness: 1),
                  ),
                ],
              ),
              SizedBox(height: AppSpacing.md),
              _buildGoogleButton(context),
              SizedBox(height: AppSpacing.lg),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${l10n.translate('auth.already_have_account')} ',
                    style: AppTextStyles.bodyMedium,
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => LoginPage(),
                        ),
                      );
                    },
                    child: Text(
                      l10n.translate('auth.sign_in'),
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: const Color(0xFF23C4C1),
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
    );
  }

  Widget _buildGoogleButton(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.divider),
        borderRadius: AppSpacing.borderRadiusMd,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onGoogleRegister,
          borderRadius: AppSpacing.borderRadiusMd,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Image.asset(
                    'assets/icons/google.png',
                    width: 24,
                    height: 24,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Center(
                          child: Text(
                            'G',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(width: AppSpacing.md),
                Text(
                  l10n.translate('auth.sign_up_google'),
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.danger,
      ),
    );
  }

  void _showSuccess(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.success,
      ),
    );
  }

  String _mapErrorCodeToLocalization(AuthErrorCode errorCode) {
    switch (errorCode) {
      case AuthErrorCode.signupFailed:
        return l10n.translate('auth.register_failed');
      case AuthErrorCode.networkError:
        return l10n.translate('error.network');
      case AuthErrorCode.serverError:
        return l10n.translate('error.server');
      default:
        return l10n.translate('error.unknown');
    }
  }
}
