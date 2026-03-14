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
import '../../../../shared/widgets/google_icon.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import 'register_page.dart';
import '../../../../core/routing/app_router.dart';

// Import AuthErrorCode from bloc
export '../bloc/auth_bloc.dart' show AuthErrorCode;

/// SC-AUT-03: Login Page
/// Trang đăng nhập gồm 2 ô input (Email/Phone, Password) + Forgot Password link
/// Hỗ trợ đăng nhập bằng:
/// - Email + mật khẩu
/// - Số điện thoại + mật khẩu
/// - Google sign-in
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  late TextEditingController _emailPhoneController;
  late TextEditingController _passwordController;

  late FocusNode _emailPhoneFocus;
  late FocusNode _passwordFocus;

  bool _isPasswordVisible = false;
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

  void _handleLogin(AppLocalizations l10n) {
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
      _showError(l10n.translate('auth.invalid_email_or_phone'));
      return;
    }

    // Call BLoC to handle login
    context.read<AuthBloc>().add(
      LoginRequested(
        email: isEmail ? input : '',
        password: _passwordController.text.trim(),
        phone: isPhone ? input : '',
      ),
    );
  }

  void _handleGoogleLogin() {
    context.read<AuthBloc>().add(const GoogleLoginRequested());
  }

  void _handleForgotPassword(AppLocalizations l10n) {
    Navigator.pushNamed(context, AppRoutes.forgotPassword);
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
        backgroundColor: AppColors.danger,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final localizationProvider = Provider.of<LocalizationProvider>(context);

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
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
      body: _LoginPageContent(
        l10n: l10n,
        emailPhoneController: _emailPhoneController,
        passwordController: _passwordController,
        emailPhoneFocus: _emailPhoneFocus,
        passwordFocus: _passwordFocus,
        isPasswordVisible: _isPasswordVisible,
        rememberMe: _rememberMe,
        onPasswordVisibilityChanged: (value) {
          setState(() {
            _isPasswordVisible = value;
          });
        },
        onRememberMeChanged: (value) {
          setState(() {
            _rememberMe = value;
          });
        },
        onLogin: () => _handleLogin(l10n),
        onForgotPassword: () => _handleForgotPassword(l10n),
        onGoogleLogin: _handleGoogleLogin,
      ),
    );
  }
}

/// Wrapper widget that provides content for login page
class _LoginPageContent extends StatelessWidget {
  final AppLocalizations l10n;
  final TextEditingController emailPhoneController;
  final TextEditingController passwordController;
  final FocusNode emailPhoneFocus;
  final FocusNode passwordFocus;
  final bool isPasswordVisible;
  final bool rememberMe;
  final Function(bool) onPasswordVisibilityChanged;
  final Function(bool) onRememberMeChanged;
  final VoidCallback onLogin;
  final VoidCallback onForgotPassword;
  final VoidCallback onGoogleLogin;

  const _LoginPageContent({
    required this.l10n,
    required this.emailPhoneController,
    required this.passwordController,
    required this.emailPhoneFocus,
    required this.passwordFocus,
    required this.isPasswordVisible,
    required this.rememberMe,
    required this.onPasswordVisibilityChanged,
    required this.onRememberMeChanged,
    required this.onLogin,
    required this.onForgotPassword,
    required this.onGoogleLogin,
  });

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is LoginSuccess) {
          AppRouter.navigateAndClearStack(AppRoutes.home);
        } else if (state is GoogleLoginSetPasswordRequired) {
          AppRouter.navigateAndClearStack(AppRoutes.setPassword);
        } else if (state is LoginFailure) {
          final msg = state.serverMessage ?? _mapErrorCodeToLocalization(state.errorCode);
          _showError(context, msg);
        }
      },
      child: SafeArea(
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
                controller: emailPhoneController,
                focusNode: emailPhoneFocus,
                label: l10n.translate('auth.email_or_phone'),
                hintText: l10n.translate('auth.enter_email_or_phone'),
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                onSubmitted: (_) {
                  FocusScope.of(context).requestFocus(passwordFocus);
                },
              ),
              SizedBox(height: AppSpacing.md),

              // Password Field
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
                          value: rememberMe,
                          onChanged: (value) {
                            onRememberMeChanged(value ?? false);
                          },
                          activeColor: const Color(0xFF23C4C1),
                          side: BorderSide(
                            color: rememberMe
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
                    onTap: onForgotPassword,
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
              BlocBuilder<AuthBloc, AuthState>(
                builder: (context, state) {
                  return AppButton(
                    label: l10n.translate('auth.login_button'),
                    isFullWidth: true,
                    isLoading: state is LoginInProgress,
                    onPressed: state is LoginInProgress ? null : onLogin,
                    type: AppButtonType.primary,
                    size: AppButtonSize.large,
                  );
                },
              ),
              SizedBox(height: AppSpacing.md),

              // Divider
              Row(
                children: [
                  Expanded(
                    child: Divider(color: AppColors.divider, thickness: 1),
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
                    child: Divider(color: AppColors.divider, thickness: 1),
                  ),
                ],
              ),
              SizedBox(height: AppSpacing.md),

              // Google Login Button
              _buildGoogleButton(context),
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
                          builder: (context) => const RegisterPage(),
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
              const SafeArea(
                top: false,
                child: SizedBox(height: AppSpacing.md),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGoogleButton(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final isLoading = state is LoginInProgress;
        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border.all(
              color: isLoading ? AppColors.divider.withOpacity(0.5) : AppColors.divider,
            ),
            borderRadius: AppSpacing.borderRadiusMd,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: isLoading ? null : onGoogleLogin,
          borderRadius: AppSpacing.borderRadiusMd,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Google Icon - inline branded widget
                const GoogleIcon(),
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
      },
    );
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.danger,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showSuccess(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Map error code from bloc to localization key
  String _mapErrorCodeToLocalization(AuthErrorCode errorCode) {
    switch (errorCode) {
      case AuthErrorCode.loginFailed:
        return l10n.translate('auth.login_failed');
      case AuthErrorCode.invalidCredentials:
        return l10n.translate('auth.invalid_credentials');
      case AuthErrorCode.emailNotRegistered:
        return l10n.translate('auth.email_not_registered');
      case AuthErrorCode.accountNotVerified:
        return l10n.translate('auth.account_not_verified');
      case AuthErrorCode.networkError:
        return l10n.translate('error.network');
      case AuthErrorCode.serverError:
        return l10n.translate('error.server');
      default:
        return l10n.translate('error.unknown');
    }
  }
}
