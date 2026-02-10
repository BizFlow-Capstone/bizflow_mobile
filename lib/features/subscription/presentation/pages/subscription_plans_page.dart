import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_button.dart';

class SubscriptionPlansPage extends StatelessWidget {
  const SubscriptionPlansPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        surfaceTintColor: AppColors.white,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => AppRouter.pop(),
        ),
        title: Text(
          l10n.translate('subscription.appbar_title'),
          style: AppTextStyles.titleSmall.copyWith(color: AppColors.textPrimary),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: AppColors.textPrimary),
            onPressed: () {},
          ),
          SizedBox(width: AppSpacing.xs),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // _InlineBackRow(label: l10n.translate('common.back')),
              SizedBox(height: AppSpacing.md),
              Text(
                l10n.translate('subscription.header_title'),
                textAlign: TextAlign.center,
                style: AppTextStyles.titleLarge.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: AppSpacing.sm),
              Text(
                l10n.translate('subscription.header_subtitle'),
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              SizedBox(height: AppSpacing.lg),

              _PlanCard.free(l10n: l10n),
              SizedBox(height: AppSpacing.lg),
              _PlanCard.premium(
                l10n: l10n,
                onUpgrade: () {
                  AppRouter.navigateTo(
                    AppRoutes.premiumPayment,
                    arguments: {
                      'planName': l10n.translate('subscription.premium.name'),
                      'price': 299000,
                      'period': l10n.translate('subscription.per_month'),
                      'vatPercent': 10,
                      'total': 328900,
                    },
                  );
                },
              ),
              SizedBox(height: AppSpacing.lg),
              _PlanCard.business(l10n: l10n),
              SizedBox(height: AppSpacing.xl),

              _BenefitsSection(l10n: l10n),
              SizedBox(height: AppSpacing.lg),

              _FaqSection(l10n: l10n),
              SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final String title;
  final String description;
  final String priceText;
  final String priceSuffix;
  final List<_FeatureRowData> features;
  final Widget action;
  final Widget? badge;
  final Color borderColor;

  const _PlanCard({
    required this.title,
    required this.description,
    required this.priceText,
    required this.priceSuffix,
    required this.features,
    required this.action,
    required this.borderColor,
    this.badge,
  });

  factory _PlanCard.free({required AppLocalizations l10n}) {
    return _PlanCard(
      title: l10n.translate('subscription.free.name'),
      description: l10n.translate('subscription.free.desc'),
      priceText: l10n.translate('subscription.free.price'),
      priceSuffix: l10n.translate('subscription.per_month'),
      borderColor: AppColors.divider,
      features: [
        _FeatureRowData(enabled: true, text: l10n.translate('subscription.free.f1')),
        _FeatureRowData(enabled: true, text: l10n.translate('subscription.free.f2')),
        _FeatureRowData(enabled: true, text: l10n.translate('subscription.free.f3')),
        _FeatureRowData(enabled: true, text: l10n.translate('subscription.free.f4')),
        _FeatureRowData(enabled: false, text: l10n.translate('subscription.free.f5')),
        _FeatureRowData(enabled: false, text: l10n.translate('subscription.free.f6')),
        _FeatureRowData(enabled: false, text: l10n.translate('subscription.free.f7')),
      ],
      action: AppButton(
        label: l10n.translate('subscription.free.current'),
        onPressed: null,
        isDisabled: true,
        isFullWidth: true,
      ),
    );
  }

  factory _PlanCard.premium({
    required AppLocalizations l10n,
    required VoidCallback onUpgrade,
  }) {
    return _PlanCard(
      title: l10n.translate('subscription.premium.name'),
      description: l10n.translate('subscription.premium.desc'),
      priceText: l10n.translate('subscription.premium.price'),
      priceSuffix: l10n.translate('subscription.per_month'),
      borderColor: AppColors.warning,
      badge: _PopularBadge(text: l10n.translate('subscription.premium.badge')),
      features: [
        _FeatureRowData(enabled: true, text: l10n.translate('subscription.premium.f1')),
        _FeatureRowData(enabled: true, text: l10n.translate('subscription.premium.f2')),
        _FeatureRowData(enabled: true, text: l10n.translate('subscription.premium.f3')),
        _FeatureRowData(enabled: true, text: l10n.translate('subscription.premium.f4')),
        _FeatureRowData(enabled: true, text: l10n.translate('subscription.premium.f5')),
        _FeatureRowData(enabled: true, text: l10n.translate('subscription.premium.f6')),
        _FeatureRowData(enabled: true, text: l10n.translate('subscription.premium.f7')),
        _FeatureRowData(enabled: true, text: l10n.translate('subscription.premium.f8')),
      ],
      action: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: onUpgrade,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.warning,
            foregroundColor: AppColors.white,
            shape: RoundedRectangleBorder(
              borderRadius: AppSpacing.borderRadiusSm,
            ),
          ),
          child: Text(
            l10n.translate('subscription.premium.cta'),
            style: AppTextStyles.titleSmall.copyWith(
              color: AppColors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  factory _PlanCard.business({required AppLocalizations l10n}) {
    return _PlanCard(
      title: l10n.translate('subscription.business.name'),
      description: l10n.translate('subscription.business.desc'),
      priceText: l10n.translate('subscription.business.price'),
      priceSuffix: '',
      borderColor: AppColors.divider,
      features: [
        _FeatureRowData(enabled: true, text: l10n.translate('subscription.business.f1')),
        _FeatureRowData(enabled: true, text: l10n.translate('subscription.business.f2')),
        _FeatureRowData(enabled: true, text: l10n.translate('subscription.business.f3')),
        _FeatureRowData(enabled: true, text: l10n.translate('subscription.business.f4')),
        _FeatureRowData(enabled: true, text: l10n.translate('subscription.business.f5')),
        _FeatureRowData(enabled: true, text: l10n.translate('subscription.business.f6')),
      ],
      action: AppButton(
        label: l10n.translate('subscription.business.cta'),
        onPressed: () {},
        type: AppButtonType.primary,
        size: AppButtonSize.large,
        isFullWidth: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (badge != null) ...[
            badge!,
            SizedBox(height: AppSpacing.sm),
          ],
          Text(
            title,
            style: AppTextStyles.titleMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: AppSpacing.xs),
          Text(
            description,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: AppSpacing.md),
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              children: [
                TextSpan(
                  text: priceText,
                  style: AppTextStyles.headlineSmall.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (priceSuffix.isNotEmpty)
                  TextSpan(
                    text: ' $priceSuffix',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(height: AppSpacing.md),
          for (final feature in features) ...[
            _FeatureRow(data: feature),
            SizedBox(height: AppSpacing.xs),
          ],
          SizedBox(height: AppSpacing.md),
          action,
        ],
      ),
    );
  }
}

class _PopularBadge extends StatelessWidget {
  final String text;

  const _PopularBadge({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: AppColors.warning,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star, size: 14, color: AppColors.white),
          SizedBox(width: AppSpacing.xs),
          Text(
            text,
            style: AppTextStyles.labelMedium.copyWith(
              color: AppColors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureRowData {
  final bool enabled;
  final String text;

  const _FeatureRowData({required this.enabled, required this.text});
}

class _FeatureRow extends StatelessWidget {
  final _FeatureRowData data;

  const _FeatureRow({required this.data});

  @override
  Widget build(BuildContext context) {
    final icon = data.enabled ? Icons.check_circle : Icons.cancel;
    final iconColor = data.enabled ? AppColors.success : AppColors.textHint;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: iconColor, size: 18),
        SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            data.text,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }
}

class _BenefitsSection extends StatelessWidget {
  final AppLocalizations l10n;

  const _BenefitsSection({required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _BenefitCard(
          icon: Icons.flash_on_outlined,
          title: l10n.translate('subscription.benefits.fast_title'),
          subtitle: l10n.translate('subscription.benefits.fast_subtitle'),
        ),
        SizedBox(height: AppSpacing.md),
        _BenefitCard(
          icon: Icons.shield_outlined,
          title: l10n.translate('subscription.benefits.secure_title'),
          subtitle: l10n.translate('subscription.benefits.secure_subtitle'),
        ),
        SizedBox(height: AppSpacing.md),
        _BenefitCard(
          icon: Icons.support_agent,
          title: l10n.translate('subscription.benefits.support_title'),
          subtitle: l10n.translate('subscription.benefits.support_subtitle'),
        ),
      ],
    );
  }
}

class _BenefitCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _BenefitCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: AppSpacing.xs),
                Text(
                  subtitle,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FaqSection extends StatelessWidget {
  final AppLocalizations l10n;

  const _FaqSection({required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.translate('subscription.faq.title'),
            style: AppTextStyles.titleSmall.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: AppSpacing.md),
          _FaqItem(
            question: l10n.translate('subscription.faq.q1'),
            answer: l10n.translate('subscription.faq.a1'),
          ),
          SizedBox(height: AppSpacing.md),
          _FaqItem(
            question: l10n.translate('subscription.faq.q2'),
            answer: l10n.translate('subscription.faq.a2'),
          ),
          SizedBox(height: AppSpacing.md),
          _FaqItem(
            question: l10n.translate('subscription.faq.q3'),
            answer: l10n.translate('subscription.faq.a3'),
          ),
        ],
      ),
    );
  }
}

class _FaqItem extends StatelessWidget {
  final String question;
  final String answer;

  const _FaqItem({required this.question, required this.answer});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          question,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: AppSpacing.xs),
        Text(
          answer,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
            height: 1.3,
          ),
        ),
      ],
    );
  }
}
