import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../../shared/context/user_profile_context.dart';
import '../../../../shared/cache/swr_builder.dart';
import '../../../subscription/data/subscription_api_service.dart';
import '../../../subscription/data/models/subscription_models.dart';

/// Settings Page - Trang cài đặt hệ thống
/// Theo thiết kế SC-ORD-05
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.textPrimary,
        systemOverlayStyle: SystemUiOverlayStyle.dark,

        elevation: 0,
        title: Text(
          l10n.translate('settings_page.title'),
          style: AppTextStyles.titleLarge.copyWith(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
          color: Colors.black,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Header Card
              _buildProfileCard(context, l10n),
              const SizedBox(height: AppSpacing.lg),

              // Account Section
              _buildSectionLabel(l10n.translate('settings_page.account')),
              const SizedBox(height: AppSpacing.sm),
              _buildSettingsTile(
                context,
                icon: Icons.person_outline,
                iconColor: const Color(0xFF5C6BC0),
                iconBgColor: const Color(0xFFE8EAF6),
                title: l10n.translate('settings_page.personal_info'),
                subtitle: l10n.translate('settings_page.personal_info_sub'),
                onTap: () => AppRouter.navigateTo(AppRoutes.profile),
              ),
              const SizedBox(height: AppSpacing.sm),
              _buildSettingsTile(
                context,
                icon: Icons.workspace_premium,
                iconColor: const Color(0xFFFF6F00),
                iconBgColor: const Color(0xFFFFF3E0),
                title: l10n.translate('settings_page.premium_plan'),
                subtitle: l10n.translate('settings_page.premium_plan_sub'),
                badge: 'Premium',
                onTap: () =>
                    AppRouter.navigateTo(AppRoutes.currentSubscription),
              ),
              const SizedBox(height: AppSpacing.lg),

              // System Settings Section
              _buildSectionLabel(l10n.translate('settings_page.system')),
              const SizedBox(height: AppSpacing.sm),
              _buildSettingsTile(
                context,
                icon: Icons.receipt_outlined,
                iconColor: const Color(0xFF5C6BC0),
                iconBgColor: const Color(0xFFE8EAF6),
                title: l10n.translate('settings_page.invoice_template'),
                subtitle: l10n.translate('settings_page.invoice_template_sub'),
                onTap: () => AppRouter.navigateTo(AppRoutes.invoiceTemplate),
              ),
              const SizedBox(height: AppSpacing.sm),
              _buildSettingsTile(
                context,
                icon: Icons.design_services_outlined,
                iconColor: const Color(0xFFE91E63),
                iconBgColor: const Color(0xFFFCE4EC),
                title: l10n.translate('settings_page.advanced_invoice'),
                subtitle: l10n.translate('settings_page.advanced_invoice_sub'),
                onTap: () =>
                    AppRouter.navigateTo(AppRoutes.advancedInvoiceTemplate),
              ),
              const SizedBox(height: AppSpacing.sm),
              _buildSettingsTile(
                context,
                icon: Icons.notifications_outlined,
                iconColor: const Color(0xFFFF9800),
                iconBgColor: const Color(0xFFFFF3E0),
                title: l10n.translate('settings_page.notification_settings'),
                subtitle: l10n.translate(
                  'settings_page.notification_settings_sub',
                ),
                onTap: () => AppRouter.navigateTo(AppRoutes.notifications),
              ),
              const SizedBox(height: AppSpacing.sm),
              _buildSettingsTile(
                context,
                icon: Icons.language,
                iconColor: const Color(0xFF00897B),
                iconBgColor: const Color(0xFFE0F2F1),
                title: l10n.translate('settings_page.language'),
                subtitle: l10n.translate('settings_page.language_sub'),
                onTap: () {},
              ),
              const SizedBox(height: AppSpacing.lg),

              // Security Section
              _buildSectionLabel(l10n.translate('settings_page.security')),
              const SizedBox(height: AppSpacing.sm),
              _buildSettingsTile(
                context,
                icon: Icons.shield_outlined,
                iconColor: const Color(0xFFF44336),
                iconBgColor: const Color(0xFFFFEBEE),
                title: l10n.translate('settings_page.security_settings'),
                subtitle: l10n.translate('settings_page.security_settings_sub'),
                onTap: () => AppRouter.navigateTo(AppRoutes.profile),
              ),
              const SizedBox(height: AppSpacing.sm),
              _buildSettingsTile(
                context,
                icon: Icons.payment_outlined,
                iconColor: const Color(0xFF43A047),
                iconBgColor: const Color(0xFFE8F5E9),
                title: l10n.translate('settings_page.payment_methods'),
                subtitle: l10n.translate('settings_page.payment_methods_sub'),
                onTap: () {},
              ),
              const SizedBox(height: AppSpacing.lg),

              // Support Section
              _buildSectionLabel(l10n.translate('settings_page.support')),
              const SizedBox(height: AppSpacing.sm),
              _buildSettingsTile(
                context,
                icon: Icons.help_outline,
                iconColor: const Color(0xFF1976D2),
                iconBgColor: const Color(0xFFE3F2FD),
                title: l10n.translate('settings_page.help'),
                subtitle: l10n.translate('settings_page.help_sub'),
                onTap: () {},
              ),
              const SizedBox(height: AppSpacing.lg),

              // Logout Button
              SizedBox(
                width: double.infinity,
                child: BlocBuilder<AuthBloc, AuthState>(
                  builder: (context, state) {
                    return OutlinedButton.icon(
                      onPressed: state is LogoutInProgress
                          ? null
                          : () => context.read<AuthBloc>().add(
                              const LogoutRequested(),
                            ),
                      icon: state is LogoutInProgress
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.danger,
                              ),
                            )
                          : const Icon(Icons.logout, color: AppColors.danger),
                      label: Text(
                        l10n.translate('settings_page.logout'),
                        style: AppTextStyles.titleMedium.copyWith(
                          color: AppColors.danger,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.danger),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusMd,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Version Footer
              Center(
                child: FutureBuilder<PackageInfo>(
                  future: PackageInfo.fromPlatform(),
                  builder: (context, snapshot) {
                    final version = snapshot.hasData
                        ? snapshot.data!.version
                        : '1.0.0';
                    return Column(
                      children: [
                        Text(
                          'BizFlow v$version',
                          style: AppTextStyles.labelMedium.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.translate('settings_page.copyright'),
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.textHint,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  /// Profile Header Card with gradient
  Widget _buildProfileCard(BuildContext context, AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF7B1FA2), // Purple
            Color(0xFF1565C0), // Blue
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7B1FA2).withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Avatar
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.2),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.4),
                      width: 2,
                    ),
                  ),
                  child: const Center(
                    child: Icon(Icons.person, color: Colors.white, size: 28),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                // Name and Email
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        UserProfileContext().fullName?.isNotEmpty == true
                            ? UserProfileContext().fullName!
                            : 'User',
                        style: AppTextStyles.titleMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        UserProfileContext().email?.isNotEmpty == true
                            ? UserProfileContext().email!
                            : (UserProfileContext().phone?.isNotEmpty == true
                                  ? UserProfileContext().phone!
                                  : 'No contact info'),
                        style: AppTextStyles.labelSmall.copyWith(
                          color: Colors.white.withAlpha(204), // 80% opacity
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            // Plan badge row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.translate('settings_page.current_plan'),
                      style: AppTextStyles.labelSmall.copyWith(
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 2),
                    SwrBuilder<CurrentSubscriptionDto?>(
                      cacheKey: 'current_subscription',
                      fetcher: ({cancelToken}) => context
                          .read<SubscriptionApiService>()
                          .getCurrentSubscription(cancelToken: cancelToken),
                      fromJson: (json) => json.isEmpty
                          ? null
                          : CurrentSubscriptionDto.fromJson(json),
                      toJson: (data) => data?.toJson() ?? {},
                      builder: (context, currentSub, isLoading, error) {
                        final planName = currentSub?.plan?.name;
                        return Text(
                          planName?.isNotEmpty == true
                              ? planName!
                              : 'Free Plan',
                          style: AppTextStyles.titleMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      },
                    ),
                  ],
                ),
                // Upgrade button
                ElevatedButton(
                  onPressed: () =>
                      AppRouter.navigateTo(AppRoutes.currentSubscription),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFB300),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppSpacing.radiusFull,
                      ),
                    ),
                  ),
                  child: Text(
                    l10n.translate('settings_page.upgrade'),
                    style: AppTextStyles.labelMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Section Label
  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: AppTextStyles.labelMedium.copyWith(
        color: AppColors.textSecondary,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  /// Settings Tile Item
  Widget _buildSettingsTile(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required String subtitle,
    String? badge,
    required VoidCallback onTap,
  }) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: 14,
          ),
          child: Row(
            children: [
              // Icon container
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Center(child: Icon(icon, color: iconColor, size: 22)),
              ),
              const SizedBox(width: AppSpacing.md),
              // Title + Subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: AppTextStyles.titleSmall.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (badge != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFB300),
                              borderRadius: BorderRadius.circular(
                                AppSpacing.radiusFull,
                              ),
                            ),
                            child: Text(
                              badge,
                              style: AppTextStyles.labelSmall.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              // Chevron
              Icon(Icons.chevron_right, color: AppColors.textHint, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
