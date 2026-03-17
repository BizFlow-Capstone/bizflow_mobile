import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/context/user_profile_context.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_sync_status_text.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/bloc/auth_state.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Set<String> _credentialTypes = <String>{};

  @override
  void initState() {
    super.initState();
    context.read<AuthBloc>().add(const LoadCredentialsRequested());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final profile = UserProfileContext();

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is CredentialsLoaded) {
          setState(() {
            _credentialTypes = state.credentialTypes.toSet();
          });
        } else if (state is LinkCredentialSuccess) {
          setState(() {
            _credentialTypes = {..._credentialTypes, state.linkedType};
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.translate('profile.link_success')),
              backgroundColor: AppColors.success,
            ),
          );
          context.read<AuthBloc>().add(const LoadCredentialsRequested());
        } else if (state is LinkPhoneOtpCodeSent) {
          _showPhoneOtpDialog(context, state.phone);
        } else if (state is LinkCredentialFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.danger,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(l10n.translate('profile.title')),
          backgroundColor: AppColors.white,
          foregroundColor: AppColors.textPrimary,
          systemOverlayStyle: SystemUiOverlayStyle.dark,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
            color: Colors.black,
          ),
          bottom: const AppSyncStatusText(),
        ),
        body: SafeArea(
          child: BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              final credentialTypes = _credentialTypes;

              final hasGoogle = credentialTypes.contains('google');
              final hasEmail = credentialTypes.contains('email');
              final hasPhone = credentialTypes.contains('phone');

              return ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: AppSpacing.borderRadiusMd,
                    ),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 32,
                          backgroundColor: AppColors.secondary.withValues(
                            alpha: 0.1,
                          ),
                          child: Text(
                            (profile.fullName?.isNotEmpty == true
                                    ? profile.fullName!
                                    : 'U')
                                .substring(0, 1)
                                .toUpperCase(),
                            style: AppTextStyles.titleLarge.copyWith(
                              color: AppColors.secondary,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          profile.fullName ??
                              l10n.translate('profile.unknown_user'),
                          style: AppTextStyles.titleLarge,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    l10n.translate('profile.linked_credentials'),
                    style: AppTextStyles.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _CredentialTile(
                    title: l10n.translate('profile.credential_google'),
                    isLinked: hasGoogle,
                    onLink: hasGoogle
                        ? null
                        : () {
                            context.read<AuthBloc>().add(
                              const LinkGoogleRequested(),
                            );
                          },
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _CredentialTile(
                    title: l10n.translate('profile.credential_email'),
                    isLinked: hasEmail,
                    onLink: hasEmail
                        ? null
                        : () => _showLinkEmailSheet(context),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _CredentialTile(
                    title: l10n.translate('profile.credential_phone'),
                    isLinked: hasPhone,
                    onLink: hasPhone
                        ? null
                        : () => _showLinkPhoneSheet(context),
                  ),
                  if (state is CredentialsLoading ||
                      state is LinkCredentialInProgress)
                    const Padding(
                      padding: EdgeInsets.only(top: AppSpacing.lg),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  void _showLinkEmailSheet(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final emailController = TextEditingController();
    final passwordController = TextEditingController();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            top: AppSpacing.lg,
            bottom:
                MediaQuery.of(sheetContext).viewInsets.bottom + AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.translate('profile.link_email'),
                style: AppTextStyles.titleMedium,
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: emailController,
                label: l10n.translate('auth.email'),
                hintText: l10n.translate('auth.enter_email'),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: passwordController,
                label: l10n.translate('auth.password'),
                hintText: l10n.translate('auth.enter_password'),
                obscureText: true,
              ),
              const SizedBox(height: AppSpacing.lg),
              AppButton(
                label: l10n.translate('common.confirm'),
                isFullWidth: true,
                onPressed: () {
                  final email = emailController.text.trim();
                  final password = passwordController.text.trim();
                  if (email.isEmpty || password.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(l10n.translate('common.required_field')),
                        backgroundColor: AppColors.warning,
                      ),
                    );
                    return;
                  }

                  context.read<AuthBloc>().add(
                    LinkEmailRequested(email: email, password: password),
                  );
                  Navigator.of(sheetContext).pop();
                },
              ),
            ],
          ),
        );
      },
    ).whenComplete(() {
      Future<void>.delayed(const Duration(milliseconds: 350), () {
        emailController.dispose();
        passwordController.dispose();
      });
    });
  }

  void _showLinkPhoneSheet(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final phoneController = TextEditingController();
    final passwordController = TextEditingController();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        final mediaQuery = MediaQuery.of(sheetContext);
        return SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.only(
              left: AppSpacing.lg,
              right: AppSpacing.lg,
              top: AppSpacing.lg,
              bottom:
                  mediaQuery.viewInsets.bottom +
                  mediaQuery.padding.bottom +
                  AppSpacing.xl,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.translate('profile.link_phone'),
                  style: AppTextStyles.titleMedium,
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  controller: phoneController,
                  label: l10n.translate('auth.phone'),
                  hintText: l10n.translate('auth.enter_phone'),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  controller: passwordController,
                  label: l10n.translate('auth.password'),
                  hintText: l10n.translate('auth.enter_password'),
                  obscureText: true,
                ),
                const SizedBox(height: AppSpacing.lg),
                AppButton(
                  label: l10n.translate('common.confirm'),
                  isFullWidth: true,
                  onPressed: () {
                    final phone = phoneController.text.trim();
                    final password = passwordController.text.trim();
                    if (phone.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            l10n.translate('common.required_field'),
                          ),
                          backgroundColor: AppColors.warning,
                        ),
                      );
                      return;
                    }

                    context.read<AuthBloc>().add(
                      StartLinkPhoneRequested(
                        phone: phone,
                        password: password.isEmpty ? null : password,
                      ),
                    );
                    Navigator.of(sheetContext).pop();
                  },
                ),
              ],
            ),
          ),
        );
      },
    ).whenComplete(() {
      Future<void>.delayed(const Duration(milliseconds: 350), () {
        phoneController.dispose();
        passwordController.dispose();
      });
    });
  }

  void _showPhoneOtpDialog(BuildContext context, String phone) {
    final l10n = AppLocalizations.of(context);
    final controllers = List.generate(6, (_) => TextEditingController());
    final focusNodes = List.generate(6, (_) => FocusNode());

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        final mediaQuery = MediaQuery.of(sheetContext);
        return SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              left: AppSpacing.lg,
              right: AppSpacing.lg,
              top: AppSpacing.lg,
              bottom:
                  mediaQuery.viewInsets.bottom +
                  mediaQuery.padding.bottom +
                  AppSpacing.xl,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.translate('auth.verify_otp_title'),
                  style: AppTextStyles.titleMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  l10n
                      .translate('auth.otp_sent_to')
                      .replaceAll('{phone}', phone),
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(6, (index) {
                    return SizedBox(
                      width: 46,
                      child: TextField(
                        controller: controllers[index],
                        focusNode: focusNodes[index],
                        maxLength: 1,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        textDirection: TextDirection.ltr,
                        style: AppTextStyles.titleLarge.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: const InputDecoration(counterText: ''),
                        onChanged: (value) {
                          if (value.isNotEmpty && index < 5) {
                            focusNodes[index + 1].requestFocus();
                          } else if (value.isEmpty && index > 0) {
                            focusNodes[index - 1].requestFocus();
                          }
                        },
                      ),
                    );
                  }),
                ),
                const SizedBox(height: AppSpacing.lg),
                AppButton(
                  label: l10n.translate('common.confirm'),
                  isFullWidth: true,
                  onPressed: () {
                    final otp = controllers.map((e) => e.text).join().trim();
                    if (otp.length != 6) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(l10n.translate('auth.otp_incomplete')),
                          backgroundColor: AppColors.warning,
                        ),
                      );
                      return;
                    }

                    context.read<AuthBloc>().add(
                      SubmitLinkPhoneOtpRequested(smsCode: otp),
                    );
                    Navigator.of(sheetContext).pop();
                  },
                ),
                const SizedBox(height: AppSpacing.sm),
                TextButton(
                  onPressed: () {
                    context.read<AuthBloc>().add(
                      const ResendLinkPhoneOtpRequested(),
                    );
                  },
                  child: Text(l10n.translate('auth.resend_otp')),
                ),
              ],
            ),
          ),
        );
      },
    ).whenComplete(() {
      Future<void>.delayed(const Duration(milliseconds: 350), () {
        for (final c in controllers) {
          c.dispose();
        }
        for (final node in focusNodes) {
          node.dispose();
        }
      });
    });
  }
}

class _CredentialTile extends StatelessWidget {
  final String title;
  final bool isLinked;
  final VoidCallback? onLink;

  const _CredentialTile({
    required this.title,
    required this.isLinked,
    required this.onLink,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: AppSpacing.borderRadiusMd,
      ),
      child: Row(
        children: [
          Expanded(child: Text(title, style: AppTextStyles.bodyMedium)),
          Text(
            isLinked
                ? l10n.translate('profile.already_linked')
                : l10n.translate('profile.not_linked'),
            style: AppTextStyles.labelSmall.copyWith(
              color: isLinked ? AppColors.success : AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          if (!isLinked && onLink != null)
            TextButton(
              onPressed: onLink,
              child: Text(l10n.translate('profile.link_now')),
            ),
        ],
      ),
    );
  }
}
