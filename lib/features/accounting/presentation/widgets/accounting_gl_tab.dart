import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../shared/widgets/app_button.dart';

class AccountingGlTab extends StatelessWidget {
  const AccountingGlTab({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.account_balance_wallet_outlined,
              size: 64,
              color: AppColors.secondary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.translate('accounting.general_ledger_desc'),
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              label: l10n.translate('accounting.view_general_ledger'),
              onPressed: () => AppRouter.navigateTo(AppRoutes.generalLedger),
            ),
          ],
        ),
      ),
    );
  }
}
