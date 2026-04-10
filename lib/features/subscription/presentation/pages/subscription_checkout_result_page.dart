import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/cache/cache_manager.dart';
import '../../data/subscription_api_service.dart';
import '../../data/subscription_repository.dart';
import '../../data/models/subscription_models.dart';

class SubscriptionCheckoutResultPage extends StatefulWidget {
  final bool isSuccess;
  final String? sessionId;

  const SubscriptionCheckoutResultPage({
    super.key,
    required this.isSuccess,
    this.sessionId,
  });

  @override
  State<SubscriptionCheckoutResultPage> createState() =>
      _SubscriptionCheckoutResultPageState();
}

class _SubscriptionCheckoutResultPageState
    extends State<SubscriptionCheckoutResultPage> {
  // Track the async refresh so the "View plan" button can await it.
  Future<void>? _refreshFuture;
  bool _isNavigatingToPlan = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshFuture = _refreshCurrentSubscription();
    });
  }

  Future<void> _navigateToCurrentPlan() async {
    if (_isNavigatingToPlan || !mounted) return;
    setState(() => _isNavigatingToPlan = true);
    try {
      // Ensure fresh subscription data is in cache before opening the page.
      await (_refreshFuture ?? Future.value());
    } finally {
      if (mounted) setState(() => _isNavigatingToPlan = false);
    }
    if (!mounted) return;
    AppRouter.navigateAndClearStack(
      AppRoutes.currentSubscription,
      arguments: {'fromCheckoutResult': true},
    );
  }

  Future<void> _refreshCurrentSubscription() async {
    if (!widget.isSuccess || !mounted) {
      return;
    }

    try {
      final apiService = context.read<SubscriptionApiService>();
      final repo = context.read<SubscriptionRepository>();
      final cache = CacheManager();

      // Remember old plan ID to detect when backend has processed the upgrade.
      final oldPlanId = repo.currentSubscriptionSnapshot?.plan?.subscriptionPlanId;

      // Clear stale cache first.
      await cache.remove('current_subscription');
      await cache.remove('current_subscription_for_plans');

      // Retry up to 5 times (2s apart) until the plan actually changes.
      // This handles backend webhook processing delay after payment.
      CurrentSubscriptionDto? latest;
      const maxAttempts = 5;
      const retryDelay = Duration(seconds: 2);

      for (var attempt = 0; attempt < maxAttempts; attempt++) {
        if (!mounted) return;
        latest = await apiService.getCurrentSubscription();

        // Plan changed (or no previous plan) → backend processed successfully.
        if (latest?.plan?.subscriptionPlanId != oldPlanId) break;

        // Still same plan → wait and retry, except on last attempt.
        if (attempt < maxAttempts - 1) {
          await Future.delayed(retryDelay);
        }
      }

      // Update in-memory snapshot — CurrentSubscriptionPage reads this sync.
      if (latest != null && mounted) {
        repo.updateCurrentSubscription(latest);
      }

      final json = latest?.toJson() ?? <String, dynamic>{};
      await cache.set('current_subscription', json);
      await cache.set('current_subscription_for_plans', json);
    } catch (_) {
      // Best effort refresh: keep result page UX stable if refresh fails.
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    final title = widget.isSuccess
        ? l10n.translate('payment.result.success_title')
        : l10n.translate('payment.result.cancel_title');
    final message = widget.isSuccess
        ? l10n.translate('payment.result.success_message')
        : l10n.translate('payment.result.cancel_message');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
         elevation: 0,
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.textPrimary,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
          color: Colors.black,
        ),
        surfaceTintColor: AppColors.white,
        title: Text(
          l10n.translate('payment.result.appbar_title'),
          style: AppTextStyles.titleSmall.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                widget.isSuccess ? Icons.check_circle : Icons.cancel,
                size: 72,
                color: widget.isSuccess ? AppColors.success : AppColors.error,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                title,
                textAlign: TextAlign.center,
                style: AppTextStyles.titleLarge.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                message,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              if ((widget.sessionId ?? '').isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Session: ${widget.sessionId}',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
              LayoutBuilder(
                builder: (context, constraints) {
                  final isNarrow = constraints.maxWidth < 420;

                  final currentPlanButton = AppButton(
                    label: l10n.translate('subscription.my_current_plan'),
                    onPressed: _isNavigatingToPlan ? null : _navigateToCurrentPlan,
                    isLoading: _isNavigatingToPlan,
                    type: AppButtonType.outlined,
                    size: AppButtonSize.large,
                  );

                  final backButton = AppButton(
                    label: l10n.translate('common.back'),
                    onPressed: () => AppRouter.navigateAndClearStack(
                      AppRoutes.home,
                    ),
                    type: AppButtonType.primary,
                    size: AppButtonSize.large,
                  );

                  if (isNarrow) {
                    return Column(
                      children: [
                        SizedBox(width: double.infinity, child: currentPlanButton),
                        const SizedBox(height: AppSpacing.md),
                        SizedBox(width: double.infinity, child: backButton),
                      ],
                    );
                  }

                  return Row(
                    children: [
                      Expanded(child: currentPlanButton),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(child: backButton),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
