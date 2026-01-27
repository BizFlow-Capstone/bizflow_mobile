import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/language_switcher.dart';
import '../../data/auth_api_service.dart';
import 'register_page.dart';

/// SC-AUT-03: Login Page
/// Trang đăng nhập gồm 2 ô input (Email/Phone, Password) + Forgot Password link
/// Hỗ trợ đăng nhập bằng:
/// - Email + mật khẩu
/// - Số điện thoại + mật khẩu
/// - Google sign-in
class LoginPage extends StatefulWidget {
  final Function(Locale)? onLocaleChange;

  const LoginPage({
    super.key,
    this.onLocaleChange,
  });

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  late TextEditingController _emailPhoneController;
  late TextEditingController _passwordController;

  late FocusNode _emailPhoneFocus;
  late FocusNode _passwordFocus;

  bool _isPasswordVisible = false;
  bool _isLoading = false;
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _emailPhoneController = TextEditingController();
    _passwordController = TextEditingController();

    _emailPhoneFocus = FocusNode();
    _passwordFocus = FocusNode();
  }

  @override
  void dispose() {
    _emailPhoneController.dispose();
    _passwordController.dispose();

    _emailPhoneFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    final l10n = AppLocalizations.of(context);

    // Validate inputs
    final input = _emailPhoneController.text.trim();
    if (input.isEmpty) {
      _showError(l10n.translate('auth.email_required'));
      return;
    }

    if (_passwordController.text.isEmpty) {
      _showError(l10n.translate('auth.password_required'));
      return;
    }

    // Validate email or phone format
    final isEmail = _isValidEmail(input);
    final isPhone = _isValidPhone(input);

    if (!isEmail && !isPhone) {
      _showError(l10n.translate('validation.invalid_email')); // Email hoặc số điện thoại không hợp lệ
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final apiService = AuthApiService();
      final response = await apiService.login(
        password: _passwordController.text.trim(),
        email: isEmail ? input : '', // Gửi email nếu là email
        phone: isPhone ? input : '', // Gửi phone nếu là số điện thoại
      );

      if (response['success'] == true) {
        _showSuccess(l10n.translate('auth.login_success'));
        // TODO: Navigate to home screen
      } else {
        _showError(response['message'] ?? l10n.translate('auth.login_failed'));
      }
    } catch (e) {
      _showError(l10n.translate('auth.login_failed'));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _handleGoogleLogin() async {
    final l10n = AppLocalizations.of(context);
    setState(() {
      _isLoading = true;
    });

    try {
      final apiService = AuthApiService();
      final response = await apiService.googleLogin();

      if (response['success'] == true) {
        _showSuccess(l10n.translate('auth.login_success'));
        // TODO: Navigate to home screen
      } else {
        _showError(response['message'] ?? l10n.translate('auth.login_failed'));
      }
    } catch (e) {
      _showError(l10n.translate('auth.login_failed'));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _handleForgotPassword() {
    final l10n = AppLocalizations.of(context);
    // TODO: Navigate to forgot password page
    _showSuccess(l10n.translate('auth.forgot_password'));
  }

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9.!#$%&*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$',
    );
    return emailRegex.hasMatch(email);
  }

  bool _isValidPhone(String phone) {
    // Validate Vietnamese phone number or international format
    // Vietnam: 10 digits (0xxxxxxxxx), +84xxxxxxxxx
    final phoneRegex = RegExp(r'^(\+84|0)[1-9]\d{8}$');
    return phoneRegex.hasMatch(phone.replaceAll('-', '').replaceAll(' ', ''));
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade400,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green.shade400,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              SizedBox(height: AppSpacing.xl),

              // Logo or Title
              Text(
                l10n.translate('auth.login_title'),
                style: AppTextStyles.headlineSmall,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: AppSpacing.sm),

              // Subtitle
              Text(
                l10n.translate('auth.login_subtitle'),
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: AppSpacing.xl),

              // Email/Phone Field
              AppTextField(
                controller: _emailPhoneController,
                focusNode: _emailPhoneFocus,
                label: l10n.translate('auth.email_or_phone'),
                hintText: l10n.translate('auth.enter_email_or_phone'),
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                onSubmitted: (_) {
                  FocusScope.of(context).requestFocus(_passwordFocus);
                },
              ),
              SizedBox(height: AppSpacing.md),

              // Password Field
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
              SizedBox(height: AppSpacing.md),

              // Remember Me & Forgot Password Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Remember Me Checkbox
                  Row(
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: Checkbox(
                          value: _rememberMe,
                          onChanged: (value) {
                            setState(() {
                              _rememberMe = value ?? false;
                            });
                          },
                          activeColor: const Color(0xFF23C4C1),
                          side: BorderSide(
                            color: _rememberMe
                                ? const Color(0xFF23C4C1)
                                : AppColors.divider,
                          ),
                        ),
                      ),
                      SizedBox(width: AppSpacing.sm),
                      Text(
                        l10n.translate('auth.remember_me'),
                        style: AppTextStyles.bodySmall,
                      ),
                    ],
                  ),
                  // Forgot Password Link
                  GestureDetector(
                    onTap: _handleForgotPassword,
                    child: Text(
                      l10n.translate('auth.forgot_password'),
                      style: AppTextStyles.bodySmall.copyWith(
                        color: const Color(0xFF23C4C1),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppSpacing.xl),

              // Login Button
              AppButton(
                label: l10n.translate('auth.login_button'),
                isFullWidth: true,
                isLoading: _isLoading,
                onPressed: _isLoading ? null : _handleLogin,
                type: AppButtonType.primary,
                size: AppButtonSize.large,
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

              // Google Login Button
              _buildGoogleButton(l10n),
              SizedBox(height: AppSpacing.lg),

              // Don't have account
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${l10n.translate('auth.dont_have_account')} ',
                    style: AppTextStyles.bodyMedium,
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RegisterPage(
                            onLocaleChange: widget.onLocaleChange,
                          ),
                        ),
                      );
                    },
                    child: Text(
                      l10n.translate('auth.dont_have_account_signup'),
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
          onTap: _handleGoogleLogin,
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
                  l10n.translate('auth.or_login_google'),
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
