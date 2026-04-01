import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../shared/context/business_context.dart';
import '../../../../shared/dialogs/app_snackbar.dart';
import '../../data/subscription_repository.dart';

class SubscriptionFeatureGuard {
  SubscriptionFeatureGuard._();

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
        AppSnackBar.show(
          context,
          message: l10n.translate('subscription.feature_blocked'),
          type: AppSnackBarType.error,
          actionLabel: l10n.translate('settings_page.upgrade'),
          onAction: () {
            AppRouter.navigateTo(AppRoutes.subscriptionPlans);
          },
        );
      }

      return allowed;
    } catch (_) {
      // Do not block action when pre-check cannot resolve locally.
      return true;
    }
  }
}
