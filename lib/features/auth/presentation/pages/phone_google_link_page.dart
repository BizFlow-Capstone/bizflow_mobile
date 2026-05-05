import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/dialogs/app_snackbar.dart';
import '../../../../shared/widgets/app_button.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../navigation/post_auth_navigation.dart';

class PhoneGoogleLinkPage extends StatefulWidget {
  const PhoneGoogleLinkPage({super.key});

  @override
  State<PhoneGoogleLinkPage> createState() => _PhoneGoogleLinkPageState();
}

class _PhoneGoogleLinkPageState extends State<PhoneGoogleLinkPage> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is LinkCredentialSuccess) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            PostAuthNavigation.route(context);
            context.read<AuthBloc>().add(const AuthOnboardingCompleted());
          });
        } else if (state is LinkCredentialFailure) {
          AppSnackBar.error(context, l10n.translateOrRaw(state.message));
        } else if (state is LoginSuccess) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            PostAuthNavigation.route(context);
            context.read<AuthBloc>().add(const AuthOnboardingCompleted());
          });
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.surface,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(l10n.translate('auth.link_google_required_title') == 'auth.link_google_required_title' ? 'Liên kết Google' : l10n.translate('auth.link_google_required_title')),
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
                    l10n.translate('auth.link_google_required_subtitle') == 'auth.link_google_required_subtitle' ? 'Tài khoản của bạn chưa liên kết với Google. Vui lòng liên kết tài khoản Google để bảo vệ tài khoản và đăng nhập dễ dàng hơn.' : l10n.translate('auth.link_google_required_subtitle'),
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  BlocBuilder<AuthBloc, AuthState>(
                    builder: (context, state) {
                      final isLoading = state is LinkCredentialInProgress;
                      return AppButton(
                        label: l10n.translate('profile.credential_google'),
                        isFullWidth: true,
                        isLoading: isLoading,
                        onPressed: isLoading
                            ? null
                            : () {
                                context.read<AuthBloc>().add(
                                  const LinkGoogleRequested(),
                                );
                              },
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppButton(
                    label: l10n.translate('auth.skip') == 'auth.skip' ? 'Bỏ qua' : l10n.translate('auth.skip'),
                    isFullWidth: true,
                    type: AppButtonType.outlined,
                    onPressed: () {
                      PostAuthNavigation.route(context);
                      context.read<AuthBloc>().add(const AuthOnboardingCompleted());
                    },
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
