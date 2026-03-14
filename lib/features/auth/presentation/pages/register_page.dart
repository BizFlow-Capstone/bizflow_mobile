import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/providers/localization_provider.dart';
import '../../../../shared/widgets/language_switcher.dart';
import '../../../../shared/widgets/google_icon.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

/// SC-AUT-01: Register Page — Google-only registration
/// The backend only supports account creation via Google.
class RegisterPage extends StatelessWidget {
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final localizationProvider = Provider.of<LocalizationProvider>(context);

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is LoginSuccess) {
          AppRouter.navigateAndClearStack(AppRoutes.home);
        } else if (state is GoogleLoginSetPasswordRequired) {
          AppRouter.navigateAndClearStack(AppRoutes.setPassword);
        } else if (state is LoginFailure) {
          final msg =
              state.serverMessage ?? l10n.translate('auth.register_failed');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(msg), backgroundColor: AppColors.danger),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.white,
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
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.business,
                  size: 64,
                  color: Color(0xFF23C4C1),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  l10n.translate('auth.create_account'),
                  style: AppTextStyles.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  l10n.translate('auth.register_google_description'),
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xl),

                // Google register button
                BlocBuilder<AuthBloc, AuthState>(
                  builder: (context, state) {
                    final isLoading = state is LoginInProgress;
                    return Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.divider),
                        borderRadius: AppSpacing.borderRadiusMd,
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: isLoading
                              ? null
                              : () => context
                                  .read<AuthBloc>()
                                  .add(const GoogleLoginRequested()),
                          borderRadius: AppSpacing.borderRadiusMd,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.md,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (isLoading)
                                  const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Color(0xFF23C4C1),
                                    ),
                                  )
                                else
                                  const GoogleIcon(),
                                SizedBox(width: AppSpacing.md),
                                Text(
                                  l10n.translate('auth.register_with_google'),
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
                ),
                const SizedBox(height: AppSpacing.xl),

                // Already have account
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
}
