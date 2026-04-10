import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../shared/context/business_context.dart';
import '../../data/subscription_repository.dart';

class SubscriptionFeatureGuard {
  SubscriptionFeatureGuard._();

  /// Synchronous local check using persistent feature-limit flags.
  /// Shows a dialog if feature has reached its limit.
  /// Returns false if blocked (dialog shown), true if allowed (no dialog).
  static bool checkFeatureLimitAndShowDialog(
    BuildContext context, {
    required String featureCode,
    String? customFeatureName,
  }) {
    final repo = context.read<SubscriptionRepository>();
    final isBlocked = repo.isFeatureLimitReached(featureCode);

    if (!isBlocked) return true; // allowed

    final l10n = AppLocalizations.of(context);
    final featureName = customFeatureName ??
        _getFeatureDisplayName(featureCode, l10n);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          l10n.translate('subscription.feature_limit_reached_title'),
        ),
        content: Text(
          l10n.translate('subscription.feature_limit_reached_message')
              .replaceAll('{feature}', featureName),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.translate('common.close')),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              AppRouter.navigateTo(AppRoutes.subscriptionPlans);
            },
            child: Text(
              l10n.translate('settings_page.upgrade'),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    return false; // blocked
  }

  /// Helper to get user-friendly feature name for UI dialogs.
  static String _getFeatureDisplayName(
      String featureCode, AppLocalizations l10n) {
    return switch (featureCode.toUpperCase()) {
      'LOCATIONS' => l10n.translate('location.title_plural'),
      'PRODUCTS' => l10n.translate('product.title_plural'),
      'EMPLOYEES' => l10n.translate('employee.title_plural'),
      'ORDERS' => l10n.translate('order.title_plural'),
      'INVOICES' => l10n.translate('invoice.title_plural'),
      'DEBTS' => l10n.translate('debt.title_plural'),
      _ => featureCode,
    };
  }

  static Future<bool> ensureAllowed(
    BuildContext context, {
    required String featureCode,
  }) async {
    try {
      final businessContext = context.read<BusinessContext>();
      final ownerProfileId = businessContext.isOwner
          ? null
          : businessContext.currentOwnerProfileId;

      final allowed = await context.read<SubscriptionRepository>().canUseFeatureCode(
            featureCode: featureCode,
            ownerProfileId: ownerProfileId,
          );

      if (!allowed && context.mounted) {
        final l10n = AppLocalizations.of(context);
        final featureName = _getFeatureDisplayName(featureCode, l10n);
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Text(
              l10n.translate('subscription.feature_limit_reached_title'),
            ),
            content: Text(
              l10n.translate('subscription.feature_limit_reached_message')
                  .replaceAll('{feature}', featureName),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l10n.translate('common.close')),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  AppRouter.navigateTo(AppRoutes.subscriptionPlans);
                },
                child: Text(
                  l10n.translate('settings_page.upgrade'),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
      }

      return allowed;
    } catch (_) {
      // Do not block action when pre-check cannot resolve locally.
      return true;
    }
  }
}
