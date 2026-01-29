import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/language_switcher.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import 'verify_otp_page.dart';
import 'login_page.dart';

/// SC-AUT-01: Register Page
/// Trang đăng ký gồm 4 ô input (Name, Phone, Email, Password)
class RegisterPage extends StatefulWidget {
  final Function(Locale)? onLocaleChange;

  const RegisterPage({
    super.key,
    this.onLocaleChange,
  });

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

  void _handleRegister() {
    final l10n = AppLocalizations.of(context);

    // Validate inputs
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

    if (_nameController.text.isEmpty) {
      _showError(l10n.translate('auth.name_required'));
      return;
    }

    // Call BLoC to handle signup
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
    // Call BLoC to handle Google signup
    // TODO: Get idToken từ Google Sign-In
    // context.read<AuthBloc>().add(
    //   GoogleSignupRequested(
    //     idToken: idToken,
    //     email: email,
    //     name: name,
    //   ),
    // );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.danger,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final size = MediaQuery.of(context).size;
    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.white,
        actions: [
          LanguageSwitcher(
            currentLocale: Localizations.localeOf(context),
            onLanguageChanged: (locale) {
              widget.onLocaleChange?.call(locale);
            },
          ),
          SizedBox(width: AppSpacing.md),
        ],
      ),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is SignupSuccess) {
            _showSuccess(l10n.translate('auth.register_success'));
            // Navigate to OTP verification
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => VerifyOtpPage(
                  phoneNumber: _phoneController.text.trim(),
                  onLocaleChange: widget.onLocaleChange,
                ),
              ),
            );
          } else if (state is SignupFailure) {
            _showError(state.message);
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
              // Logo / Header
              if (!isKeyboardOpen) ...[
                SizedBox(height: AppSpacing.lg),
                const Icon(
                  Icons.business,
                  size: 60,
                  color: Color(0xFF23C4C1),
                ),
                SizedBox(height: AppSpacing.md),
              ],

              // Title
              Text(
                l10n.translate('auth.create_account'),
                style: AppTextStyles.headlineSmall,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: AppSpacing.sm),

              // Subtitle
              Text(
                l10n.translate('auth.register_subtitle'),
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: AppSpacing.xl),

              // Form
              AppTextField(
                controller: _nameController,
                focusNode: _nameFocus,
                label: l10n.translate('auth.name'),
                hintText: l10n.translate('auth.enter_name'),
                keyboardType: TextInputType.name,
                textInputAction: TextInputAction.next,
                onSubmitted: (_) {
                  FocusScope.of(context).requestFocus(_phoneFocus);
                },
              ),
              SizedBox(height: AppSpacing.md),

              AppTextField(
                controller: _phoneController,
                focusNode: _phoneFocus,
                label: l10n.translate('auth.phone'),
                hintText: l10n.translate('auth.enter_phone'),
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                onSubmitted: (_) {
                  FocusScope.of(context).requestFocus(_emailFocus);
                },
              ),
              SizedBox(height: AppSpacing.md),

              AppTextField(
                controller: _emailController,
                focusNode: _emailFocus,
                label: l10n.translate('auth.email'),
                hintText: l10n.translate('auth.enter_email'),
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                onSubmitted: (_) {
                  FocusScope.of(context).requestFocus(_passwordFocus);
                },
              ),
              SizedBox(height: AppSpacing.md),

              AppTextField(
                controller: _passwordController,
                focusNode: _passwordFocus,
                label: l10n.translate('auth.password'),
                hintText: l10n.translate('auth.enter_password'),
                obscureText: !_isPasswordVisible,
                textInputAction: TextInputAction.done,
                suffixIcon: GestureDetector(
                  onTap: () {
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    });
                  },
                  child: Icon(
                    _isPasswordVisible
                        ? Icons.visibility
                        : Icons.visibility_off,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              SizedBox(height: AppSpacing.xl),

              // Register Button
              BlocBuilder<AuthBloc, AuthState>(
                builder: (context, state) {
                  return AppButton(
                    label: l10n.translate('auth.sign_up'),
                    isFullWidth: true,
                    isLoading: state is SignupInProgress,
                    onPressed: state is SignupInProgress ? null : _handleRegister,
                    type: AppButtonType.secondary,
                    size: AppButtonSize.large,
                  );
                },
              ),
              SizedBox(height: AppSpacing.md),

              // Divider
              Row(
                children: [
                  Expanded(
                    child: Divider(
                      color: AppColors.divider,
                      thickness: 1,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                    ),
                    child: Text(
                      l10n.translate('auth.or_divider'),
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Divider(
                      color: AppColors.divider,
                      thickness: 1,
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppSpacing.md),

              // Google Sign Up Button
              _buildGoogleButton(l10n),
              SizedBox(height: AppSpacing.lg),

              // Already have account
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${l10n.translate('auth.already_have_account')} ',
                    style: AppTextStyles.bodyMedium,
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(context,
                      MaterialPageRoute(
                        builder: (context) => LoginPage(
                          onLocaleChange: widget.onLocaleChange,
                        ),
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
      ),
    );
  }

  Widget _buildGoogleButton(AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.divider),
        borderRadius: AppSpacing.borderRadiusMd,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _handleGoogleRegister,
          borderRadius: AppSpacing.borderRadiusMd,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/icons/google.png',
                  width: 24,
                  height: 24,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.g_mobiledata,
                      size: 24,
                      color: AppColors.textPrimary,
                    );
                  },
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
}
