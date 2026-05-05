import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/network/api_error_message_parser.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/cache/swr_builder.dart';
import '../../data/subscription_api_service.dart';
import '../../data/models/subscription_models.dart';
import '../../data/subscription_repository.dart';

import '../../../../shared/context/business_context.dart';

class SubscriptionPlansPage extends StatefulWidget {
  const SubscriptionPlansPage({super.key});

  @override
  State<SubscriptionPlansPage> createState() => _SubscriptionPlansPageState();
}

class _SubscriptionPlansPageState extends State<SubscriptionPlansPage> {
  int? _processingPlanId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final apiService = context.read<SubscriptionApiService>();
    final businessContext = Provider.of<BusinessContext>(context);
    final isOwner = businessContext.isOwner;

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
          style: AppTextStyles.titleSmall.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.notifications_none,
              color: AppColors.textPrimary,
            ),
            onPressed: () => AppRouter.navigateTo(AppRoutes.notifications),
          ),
          SizedBox(width: AppSpacing.xs),
        ],
      ),
      body: SwrBuilder<CurrentSubscriptionDto?>(
        cacheKey: 'current_subscription_for_plans',
        fetcher: ({cancelToken}) =>
            apiService.getCurrentSubscription(cancelToken: cancelToken),
        fromJson: (json) =>
            json.isEmpty ? null : CurrentSubscriptionDto.fromJson(json),
        toJson: (data) => data?.toJson() ?? {},
        builder: (context, currentSub, _, __) {
          return SwrBuilder<List<SubscriptionPlanDto>>(
            cacheKey: 'subscription_plans',
            fetcher: ({cancelToken}) =>
                apiService.getSubscriptionPlans(cancelToken: cancelToken),
            fromJson: (json) {
              final data = json['list'] as List<dynamic>? ?? [];
              return data
                  .map((json) => SubscriptionPlanDto.fromJson(json))
                  .toList();
            },
            toJson: (data) => {'list': data.map((e) => e.toJson()).toList()},
            builder: (context, plans, isLoading, error) {
              if (isLoading && (plans == null || plans.isEmpty)) {
                return const Center(child: CircularProgressIndicator());
              }

              if (error != null && (plans == null || plans.isEmpty)) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 48,
                          color: AppColors.error,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          ApiErrorMessageParser.parse(error),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => AppRouter.pop(),
                          child: Text(l10n.translate('common.back')),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final displayPlans = plans ?? [];

              return SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(height: AppSpacing.md),
                      if (!isOwner) ...[
                        _buildEmployeeWarning(context),
                        SizedBox(height: AppSpacing.lg),
                      ],
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

                      ...displayPlans.map((plan) {
                        final normalizedPlanName = plan.name.toLowerCase();
                        final isFree =
                            (plan.currentPrice?.effectivePrice ?? 0) <= 0 ||
                            normalizedPlanName.contains('free') ||
                            normalizedPlanName.contains('miễn phí');
                        final isBusiness =
                            normalizedPlanName.contains('business') ||
                            normalizedPlanName.contains('doanh nghiệp');
                        final isCurrentPlan =
                            currentSub?.isActive == true &&
                            currentSub?.plan?.subscriptionPlanId ==
                                plan.subscriptionPlanId;

                        return Column(
                          children: [
                            _DynamicPlanCard(
                              plan: plan,
                              l10n: l10n,
                              type: isFree
                                  ? _PlanType.free
                                  : (isBusiness
                                        ? _PlanType.business
                                        : _PlanType.premium),
                              onUpgrade: () => _handleUpgrade(context, plan),
                              isOwner: isOwner,
                              isCurrentPlan: isCurrentPlan,
                              isProcessing:
                                  _processingPlanId == plan.subscriptionPlanId,
                            ),
                            SizedBox(height: AppSpacing.lg),
                          ],
                        );
                      }),

                      _BenefitsSection(l10n: l10n),
                      SizedBox(height: AppSpacing.lg),

                      SizedBox(height: AppSpacing.xl),
                      const SafeArea(top: false, child: SizedBox.shrink()),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmployeeWarning(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: AppColors.error,
            size: 24,
          ),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              AppLocalizations.of(
                context,
              ).translate('subscription.owner_only_upgrade_notice'),
              style: TextStyle(
                color: AppColors.error,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleUpgrade(
    BuildContext context,
    SubscriptionPlanDto plan,
  ) async {
    if (_processingPlanId != null) return;
    final repo = context.read<SubscriptionRepository>();

    setState(() {
      _processingPlanId = plan.subscriptionPlanId;
    });

    try {
      final checkout = await repo.checkoutSubscription(plan.subscriptionPlanId);
      if (checkout.sessionUrl.isNotEmpty) {
        final uri = Uri.parse(checkout.sessionUrl);
        if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
          if (context.mounted) {
            ScaffoldMessenger.of(context)
              ..removeCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: Text(
                    AppLocalizations.of(
                      context,
                    ).translate('subscription.launch_payment_failed'),
                  ),
                  backgroundColor: AppColors.error,
                ),
              );
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
          ..removeCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(ApiErrorMessageParser.parse(e)),
              backgroundColor: AppColors.error,
            ),
          );
      }
    } finally {
      if (mounted) {
        setState(() {
          _processingPlanId = null;
        });
      }
    }
  }
}

enum _PlanType { free, premium, business }

class _DynamicPlanCard extends StatelessWidget {
  final SubscriptionPlanDto plan;
  final AppLocalizations l10n;
  final _PlanType type;
  final VoidCallback onUpgrade;

  final bool isOwner;
  final bool isCurrentPlan;
  final bool isProcessing;

  const _DynamicPlanCard({
    required this.plan,
    required this.l10n,
    required this.type,
    required this.onUpgrade,
    required this.isOwner,
    required this.isCurrentPlan,
    this.isProcessing = false,
  });

  @override
  Widget build(BuildContext context) {
    final price = plan.currentPrice;
    final priceText = price != null
        ? (price.effectivePrice == 0
              ? l10n.translate('subscription.free.price')
              : price.effectivePrice.toStringAsFixed(0))
        : 'Contact Us';

    final currency = price?.currency ?? 'VND';
    final formattedPrice = price != null && price.effectivePrice > 0
        ? '$priceText $currency'
        : priceText;

    final borderColor = isCurrentPlan
        ? AppColors.success
        : (type == _PlanType.premium ? AppColors.warning : AppColors.divider);

    // Check if it's premium to show popular badge
    final showBadge = type == _PlanType.premium;

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
          if (isCurrentPlan && type != _PlanType.free) ...[
            _PopularBadge(
              text: l10n.translate('subscription.registered_label'),
            ),
            SizedBox(height: AppSpacing.sm),
          ] else if (showBadge) ...[
            _PopularBadge(text: l10n.translate('subscription.premium.badge')),
            SizedBox(height: AppSpacing.sm),
          ],
          Text(
            plan.name,
            style: AppTextStyles.titleMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: AppSpacing.xs),
          Text(
            plan.description ?? '',
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
                  text: formattedPrice,
                  style: AppTextStyles.headlineSmall.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (plan.durationDays > 0 &&
                    price != null &&
                    price.effectivePrice > 0)
                  TextSpan(
                    text: ' / ${plan.durationDays} days',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(height: AppSpacing.md),
          ...plan.features.map(
            (f) => Column(
              children: [
                _FeatureRow(
                  data: _FeatureRowData(
                    enabled: true,
                    text: _buildFeatureText(f),
                  ),
                ),
                SizedBox(height: AppSpacing.xs),
              ],
            ),
          ),
          SizedBox(height: AppSpacing.md),
          _buildActionButton(context),
        ],
      ),
    );
  }

  Widget _buildActionButton(BuildContext context) {
    if (!isOwner) return const SizedBox.shrink();

    if (type == _PlanType.free && isCurrentPlan) {
      return const SizedBox.shrink();
    }

    if (isCurrentPlan) {
      return SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: isProcessing ? null : onUpgrade,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.success,
            foregroundColor: AppColors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: isProcessing
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  )
                )
              : Text(
                  l10n.translate('subscription.renew_more'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      );
    }

    if (type == _PlanType.free) {
      return AppButton(
        label: l10n.translate('subscription.free.current'),
        onPressed: null,
        isDisabled: true,
        isFullWidth: true,
      );
    }

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: isProcessing ? null : onUpgrade,
        style: ElevatedButton.styleFrom(
          backgroundColor: type == _PlanType.premium
              ? AppColors.warning
              : AppColors.primary,
          foregroundColor: AppColors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: isProcessing
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                type == _PlanType.business
                    ? l10n.translate('subscription.business.cta')
                    : l10n.translate('subscription.premium.cta'),
                style: AppTextStyles.titleSmall.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  String _buildFeatureText(PlanFeatureDto feature) {
    final featureName = feature.featureName.trim();
    final featureDescription = feature.featureDescription.trim();
    final featureCode = feature.featureCode.trim();

    final displayName = featureName.isNotEmpty
        ? featureName
        : (featureDescription.isNotEmpty
              ? featureDescription
              : _humanizeFeatureCode(featureCode));

    if (feature.usageLimit < 0) {
      return '$displayName: ${l10n.translate('subscription.unlimited')}';
    }

    // Some payloads still return missing code/name with usageLimit=0; show description only.
    if (feature.usageLimit == 0 &&
        featureName.isEmpty &&
        featureCode.isEmpty &&
        featureDescription.isNotEmpty) {
      return displayName;
    }

    if (feature.usageLimit == 0) {
      return displayName;
    }

    return '$displayName: ${feature.usageLimit}';
  }

  String _humanizeFeatureCode(String featureCode) {
    if (featureCode.isEmpty) return '-';

    final normalized = featureCode.replaceAll('_', ' ').trim();
    if (normalized.isEmpty) return '-';

    final parts = normalized
        .split(' ')
        .where((part) => part.trim().isNotEmpty)
        .toList();
    if (parts.isEmpty) return '-';

    return parts
        .map(
          (part) =>
              '${part[0].toUpperCase()}${part.length > 1 ? part.substring(1).toLowerCase() : ''}',
        )
        .join(' ');
  }
}

class _PopularBadge extends StatelessWidget {
  final String text;

  const _PopularBadge({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
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
              color: AppColors.primary.withAlpha(26), // ~0.1 opacity
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
