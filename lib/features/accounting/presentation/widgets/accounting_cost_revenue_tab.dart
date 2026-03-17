import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/utils/formatters.dart';
import '../models/accounting_mock_models.dart';

class AccountingCostRevenueTab extends StatelessWidget {
  final List<AccountingItemModel> revenues;
  final List<AccountingItemModel> costs;
  final ValueChanged<AccountingItemModel> onEditRevenue;
  final ValueChanged<AccountingItemModel> onEditCost;

  const AccountingCostRevenueTab({
    super.key,
    required this.revenues,
    required this.costs,
    required this.onEditRevenue,
    required this.onEditCost,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        _card(
          title: l10n.translate('accounting.revenue_list'),
          child: Column(
            children: revenues
                .map(
                  (item) => _itemTile(
                    context,
                    item: item,
                    isRevenue: true,
                    onEdit: () => onEditRevenue(item),
                  ),
                )
                .toList(),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _card(
          title: l10n.translate('accounting.cost_list'),
          child: Column(
            children: costs
                .map(
                  (item) => _itemTile(
                    context,
                    item: item,
                    isRevenue: false,
                    onEdit: () => onEditCost(item),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _itemTile(
    BuildContext context, {
    required AccountingItemModel item,
    required bool isRevenue,
    required VoidCallback onEdit,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(item.code, style: AppTextStyles.bodyMedium),
      subtitle: Text(item.description, style: AppTextStyles.bodySmall),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            CurrencyFormatter.formatVND(item.amount),
            style: AppTextStyles.labelSmall.copyWith(
              color: isRevenue ? AppColors.success : AppColors.error,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: onEdit,
          ),
        ],
      ),
    );
  }

  Widget _card({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSpacing.sm),
          child,
        ],
      ),
    );
  }
}
